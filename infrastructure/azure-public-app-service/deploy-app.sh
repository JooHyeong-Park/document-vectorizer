#!/usr/bin/env bash

set -Eeuo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AZURE_TENANT_ID='eef21324-3a79-4bc1-af76-43b693f2f061'
AZURE_CLIENT_ID='17327f99-df92-446c-b385-b13d645676ce'
AZURE_CLIENT_SECRET="${AZURE_CLIENT_SECRET:?AZURE_CLIENT_SECRET is required}"
AZURE_AUTHENTICATION_METHOD='client_secret'
AZURE_SCOPE='https://management.azure.com/.default'
AZURE_SUBSCRIPTION_ID='d423337a-8a9a-43fd-891c-4f57161bc69d'
RESOURCE_GROUP='RG_00001_Public-App-Service_DV01'

APP_TYPE='Function App'
APP_NAME='fpy00001kcdv0101'
APP_IMAGE_URL='acr00001kcdv0101.azurecr.io/document-vectorizer-function-app:20260915-01'
# APP_TYPE='Web App'
# APP_NAME='wbalx00001kcdv0101'
# APP_IMAGE_URL='acr00001kcdv0101.azurecr.io/document-vectorizer-web-app:20260915-01'

DEPLOYMENT_TIMEOUT_SECONDS=600
POLL_INTERVAL_SECONDS=10
ARM_API_VERSION='2026-07-15'

source "${script_directory}/_common.sh"

arm_request() {
  local method=$1
  local url=$2
  local body=${3:-}

  if [[ -n "${body}" ]]; then
    curl \
      --fail \
      --silent \
      --show-error \
      --request "${method}" \
      --header "Authorization: Bearer ${AZURE_ACCESS_TOKEN}" \
      --header 'Content-Type: application/json' \
      --data-raw "${body}" \
      "${url}"
  else
    curl \
      --fail \
      --silent \
      --show-error \
      --request "${method}" \
      --header "Authorization: Bearer ${AZURE_ACCESS_TOKEN}" \
      --header 'Content-Length: 0' \
      "${url}"
  fi
}

update_app_service_container_configuration() {
  local app_type=$1
  local app_name=$2
  local image_url=$3
  local app_url="https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Web/sites/${app_name}"

  printf '[INFO] Updating %s container configuration: %s\n' "${app_type}" "${app_name}"
  arm_request PATCH "${app_url}/config/web?api-version=${ARM_API_VERSION}" \
    "{\"properties\":{\"linuxFxVersion\":\"DOCKER|${image_url}\",\"acrUseManagedIdentityCreds\":true}}" >/dev/null
}

restart_app_service() {
  local app_type=$1
  local app_name=$2
  local app_url="https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Web/sites/${app_name}"

  printf '[INFO] Restarting %s: %s\n' "${app_type}" "${app_name}"
  arm_request POST "${app_url}/restart?api-version=${ARM_API_VERSION}" >/dev/null
}

verify_app_service_container_deployment() {
  local app_type=$1
  local app_name=$2
  local image_url=$3
  local app_url="https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Web/sites/${app_name}"
  local started_at="${SECONDS}"
  local attempt=0
  while (( SECONDS - started_at < DEPLOYMENT_TIMEOUT_SECONDS )); do
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

  printf '[ERROR] %s deployment verification timed out after %ss: %s\n' \
    "${app_type}" "${DEPLOYMENT_TIMEOUT_SECONDS}" "${app_name}" >&2
  return 1
}


login_by_service_principal "${AZURE_AUTHENTICATION_METHOD}"

update_app_service_container_configuration "${APP_TYPE}" "${APP_NAME}" "${APP_IMAGE_URL}"

restart_app_service "${APP_TYPE}" "${APP_NAME}"

verify_app_service_container_deployment "${APP_TYPE}" "${APP_NAME}" "${APP_IMAGE_URL}"
