#!/usr/bin/env bash

set -Eeuo pipefail

### HTTP request settings
# Maximum time allowed to establish an HTTP connection.
AZURE_CONNECT_TIMEOUT_SECONDS=10

# Maximum time allowed to complete an OAuth token request.
AZURE_TOKEN_TIMEOUT_SECONDS=60

# JSON response helpers
extract_json_string() {
  local json_body=$1
  local property_name=$2

  command -v jq >/dev/null

  jq -r --arg property_name "${property_name}" \
    '[.. | objects | .[$property_name]? | select(type == "string")] | first // empty' \
    <<< "${json_body}"

  # Previous Bash-only implementation. Keep this here for later replacement
  # if jq cannot be used in the target environment.
  # if [[ "${json_body}" =~ \"${property_name}\"[[:space:]]*:[[:space:]]*\"([^\"]*)\" ]]; then
  #   printf '%s' "${BASH_REMATCH[1]}"
  # fi
}

# Client Secret authentication
get_access_token_by_client_secret() {
  set -Eeuo pipefail

  command -v curl >/dev/null

  if [[ -z "${AZURE_CLIENT_SECRET:-}" ]]; then
    printf '[ERROR] AZURE_CLIENT_SECRET is required\n' >&2
    return 1
  fi

  local token_endpoint="https://login.microsoftonline.com/${AZURE_TENANT_ID}/oauth2/v2.0/token"
  local token_response
  token_response="$(curl \
    --silent \
    --show-error \
    --connect-timeout "${AZURE_CONNECT_TIMEOUT_SECONDS}" \
    --max-time "${AZURE_TOKEN_TIMEOUT_SECONDS}" \
    --request POST \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode "client_id=${AZURE_CLIENT_ID}" \
    --data-urlencode "client_secret=${AZURE_CLIENT_SECRET}" \
    --data-urlencode "scope=${AZURE_SCOPE}" \
    --data-urlencode 'grant_type=client_credentials' \
    --write-out $'\n%{http_code}' \
    "${token_endpoint}")"
  unset AZURE_CLIENT_SECRET

  local http_status="${token_response##*$'\n'}"
  local token_body="${token_response%$'\n'*}"
  unset token_response

  if [[ "${http_status}" != '200' ]]; then
    local error_description
    error_description="$(extract_json_string "${token_body}" 'error_description')"
    printf '[ERROR] Service Principal authentication failed (%s): %s\n' \
      "${http_status}" "${error_description:-Token request failed}" >&2
    return 1
  fi

  AZURE_ACCESS_TOKEN="$(extract_json_string "${token_body}" 'access_token')"
  unset token_body
  export AZURE_ACCESS_TOKEN

  if [[ -z "${AZURE_ACCESS_TOKEN}" ]]; then
    printf '[ERROR] Azure access token was not returned\n' >&2
    return 1
  fi

  printf '[SUCCESS] Azure Service Principal authentication completed\n'
}

# Certificate authentication
_base64url_encode() {
  openssl base64 -A | tr '+/' '-_' | tr -d '='
}

get_access_token_by_certificate() {
  command -v openssl >/dev/null

  local certificate_file="${AZURE_CERTIFICATE_FILE:?AZURE_CERTIFICATE_FILE is required}"
  if [[ ! -f "${certificate_file}" ]]; then
    printf '[ERROR] Certificate file does not exist: %s\n' "${certificate_file}" >&2
    return 1
  fi

  local token_endpoint="https://login.microsoftonline.com/${AZURE_TENANT_ID}/oauth2/v2.0/token"
  local temporary_directory
  temporary_directory="$(mktemp -d)"
  trap 'rm -rf -- "${temporary_directory}"' RETURN

  local private_key_file="${temporary_directory}/private-key.pem"
  local public_certificate_file="${temporary_directory}/certificate.pem"
  openssl pkey -in "${certificate_file}" -out "${private_key_file}" 2>/dev/null
  openssl x509 -in "${certificate_file}" -out "${public_certificate_file}" 2>/dev/null
  chmod 600 "${private_key_file}"

  local certificate_thumbprint
  certificate_thumbprint="$({
    openssl x509 -in "${public_certificate_file}" -outform DER 2>/dev/null
  } | openssl dgst -sha256 -binary | _base64url_encode)"

  local issued_at
  issued_at="$(date +%s)"
  local expires_at
  expires_at="$((issued_at + 600))"
  local jti
  jti="$(openssl rand -hex 16)"
  local jwt_header="{\"alg\":\"RS256\",\"typ\":\"JWT\",\"x5t#S256\":\"${certificate_thumbprint}\"}"
  local jwt_payload="{\"aud\":\"${token_endpoint}\",\"iss\":\"${AZURE_CLIENT_ID}\",\"sub\":\"${AZURE_CLIENT_ID}\",\"jti\":\"${jti}\",\"nbf\":${issued_at},\"exp\":${expires_at}}"
  local jwt_header_encoded
  local jwt_payload_encoded
  jwt_header_encoded="$(printf '%s' "${jwt_header}" | _base64url_encode)"
  jwt_payload_encoded="$(printf '%s' "${jwt_payload}" | _base64url_encode)"

  local jwt_signing_input="${jwt_header_encoded}.${jwt_payload_encoded}"
  local jwt_signature
  jwt_signature="$(printf '%s' "${jwt_signing_input}" | openssl dgst -sha256 -sign "${private_key_file}" | _base64url_encode)"
  local client_assertion="${jwt_signing_input}.${jwt_signature}"
  local token_response
  token_response="$(curl \
    --silent \
    --show-error \
    --connect-timeout "${AZURE_CONNECT_TIMEOUT_SECONDS}" \
    --max-time "${AZURE_TOKEN_TIMEOUT_SECONDS}" \
    --request POST \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode "client_id=${AZURE_CLIENT_ID}" \
    --data-urlencode "scope=${AZURE_SCOPE}" \
    --data-urlencode 'grant_type=client_credentials' \
    --data-urlencode 'client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer' \
    --data-urlencode "client_assertion=${client_assertion}" \
    --write-out $'\n%{http_code}' \
    "${token_endpoint}")"

  local http_status="${token_response##*$'\n'}"
  local token_body="${token_response%$'\n'*}"
  unset token_response client_assertion jwt_signature jwt_signing_input

  if [[ "${http_status}" != '200' ]]; then
    local error_description
    error_description="$(extract_json_string "${token_body}" 'error_description')"
    printf '[ERROR] Certificate authentication failed (%s): %s\n' \
      "${http_status}" "${error_description:-Token request failed}" >&2
    return 1
  fi

  AZURE_ACCESS_TOKEN="$(extract_json_string "${token_body}" 'access_token')"
  unset token_body
  export AZURE_ACCESS_TOKEN

  if [[ -z "${AZURE_ACCESS_TOKEN}" ]]; then
    printf '[ERROR] Azure access token was not returned\n' >&2
    return 1
  fi

  printf '[SUCCESS] Azure Service Principal certificate authentication completed\n'
}

# Authentication entry point
login_by_service_principal() {
  local authentication_method="${1:?authentication method is required}"

  case "${authentication_method}" in
    client_secret)
      get_access_token_by_client_secret
      ;;
    certificate)
      get_access_token_by_certificate
      ;;
    *)
      printf '[ERROR] Unsupported AZURE_AUTHENTICATION_METHOD: %s\n' \
        "${authentication_method}" >&2
      return 1
      ;;
  esac
}

# App Service deployment settings
POLL_INTERVAL_SECONDS=10
ARM_REQUEST_TIMEOUT_SECONDS=120
ARM_API_VERSION='2026-07-15'

# Azure Resource Manager requests
arm_request() {
  local method=$1
  local url=$2
  local body=${3:-}
  local -a curl_arguments=(
    --silent
    --show-error
    --connect-timeout "${AZURE_CONNECT_TIMEOUT_SECONDS}"
    --max-time "${ARM_REQUEST_TIMEOUT_SECONDS}"
    --request "${method}"
    --header "Authorization: Bearer ${AZURE_ACCESS_TOKEN}"
    --write-out $'\n%{http_code}'
  )

  if [[ -n "${body}" ]]; then
    curl_arguments+=(
      --header 'Content-Type: application/json'
      --data-raw "${body}"
    )
  else
    curl_arguments+=(--header 'Content-Length: 0')
  fi

  local response
  if ! response="$(curl "${curl_arguments[@]}" "${url}")"; then
    return 1
  fi

  local http_status="${response##*$'\n'}"
  local response_body="${response%$'\n'*}"
  unset response

  if [[ ! "${http_status}" =~ ^2[0-9][0-9]$ ]]; then
    printf '[ERROR] ARM %s request failed (HTTP %s)\n%s\n' \
      "${method}" "${http_status}" "${response_body}" >&2
    return 1
  fi

  printf '%s' "${response_body}"
}

# App Service container deployment
# Update the App Service container configuration.
update_app_service_container_configuration() {
  local app_type=$1
  local app_name=$2
  local image_url=$3
  local app_url="https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Web/sites/${app_name}"

  printf '[INFO] Updating %s container configuration: %s\n' "${app_type}" "${app_name}"
  arm_request PATCH "${app_url}/config/web?api-version=${ARM_API_VERSION}" \
    "{\"properties\":{\"linuxFxVersion\":\"DOCKER|${image_url}\",\"acrUseManagedIdentityCreds\":true}}" >/dev/null
}

# Restart the App Service synchronously.
restart_app_service() {
  local app_type=$1
  local app_name=$2
  local app_url="https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Web/sites/${app_name}"

  printf '[INFO] Restarting %s: %s\n' "${app_type}" "${app_name}"
  arm_request \
    POST \
    "${app_url}/restart?api-version=${ARM_API_VERSION}&synchronous=true" >/dev/null
}

# Verify the App Service state and configured container image.
verify_app_service_container_deployment() {
  local app_type=$1
  local app_name=$2
  local image_url=$3
  local app_url="https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Web/sites/${app_name}"
  local attempt=0
  while true; do
    ((attempt += 1))
    local site_response
    local state
    local configured_image
    site_response="$(arm_request GET "${app_url}?api-version=${ARM_API_VERSION}")"
    state="$(extract_json_string "${site_response}" 'state')"
    configured_image="$(extract_json_string "${site_response}" 'linuxFxVersion')"
    unset site_response

    printf '[INFO] %s deployment check %s: state=%s image=%s\n' \
      "${app_type}" "${attempt}" "${state}" "${configured_image}"

    if [[ "${state}" == 'Running' && "${configured_image}" == "DOCKER|${image_url}" ]]; then
      printf '[SUCCESS] %s deployment verified through Azure Resource Manager: app=%s state=%s configured_image=%s\n' \
        "${app_type}" "${app_name}" "${state}" "${configured_image}"
      return 0
    fi

    sleep "${POLL_INTERVAL_SECONDS}"
  done
}
