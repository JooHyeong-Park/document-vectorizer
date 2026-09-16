#!/usr/bin/env bash

set -Eeuo pipefail

### App Service deployment settings

# Interval between App Service deployment status checks.
POLL_INTERVAL_SECONDS=10

# Maximum time allowed for an Azure Resource Manager request.
ARM_REQUEST_TIMEOUT_SECONDS=120

# Azure Resource Manager API version used for App Service requests.
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
