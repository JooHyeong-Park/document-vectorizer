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

  jq -r --arg property_name "${property_name}" \
    '[.. | objects | .[$property_name]? | select(type == "string")] | first // empty' \
    <<< "${json_body}"
}

# Client Secret authentication
get_access_token_by_client_secret() {
  set -Eeuo pipefail

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
    printf "[ERROR] Service Principal authentication failed :: http status '%s': %s\n" \
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

# [Note] This function has not been tested yet.
get_access_token_by_client_certificate() {
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
    printf "[ERROR] Certificate authentication failed :: http status '%s': %s\n" \
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

  # TEMPORARY AZURE ACCESS TOKEN :: START
  # Remove this block after Service Principal authentication is enabled.
  if [[ -n "${AZURE_ACCESS_TOKEN:-}" && "${AZURE_ACCESS_TOKEN}" != '__NOT_PROVIDED__' ]]; then
    printf '[INFO] Using the Azure access token supplied at pipeline execution\n'
    return 0
  fi
  # TEMPORARY AZURE ACCESS TOKEN :: END

  case "${authentication_method}" in
    client_secret)
      get_access_token_by_client_secret
      ;;
    client_certificate)
      get_access_token_by_client_certificate
      ;;
    *)
      printf "[ERROR] Unsupported AZURE_AUTHENTICATION_METHOD '%s'\n" \
        "${authentication_method}" >&2
      return 1
      ;;
  esac
}
