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
# APP_TYPE='Web App'
# APP_NAME='wbalx00001kcdv0101'

LOG_REQUEST_TIMEOUT_SECONDS=120
ARM_API_VERSION='2026-07-15'

source "${script_directory}/_common.sh"

login_by_service_principal "${AZURE_AUTHENTICATION_METHOD}"

get_app_container_logs() {
  local container_logs_url="https://management.azure.com/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Web/sites/${APP_NAME}/containerlogs?api-version=${ARM_API_VERSION}"
  local temporary_directory="$(mktemp -d)"
  local logs_file="${temporary_directory}/container-logs.txt"
  local http_status

  if ! http_status="$(curl \
    --silent \
    --show-error \
    --connect-timeout "${AZURE_CONNECT_TIMEOUT_SECONDS}" \
    --max-time "${LOG_REQUEST_TIMEOUT_SECONDS}" \
    --request POST \
    --header "Authorization: Bearer ${AZURE_ACCESS_TOKEN}" \
    --header 'Content-Length: 0' \
    --header 'Accept: application/octet-stream' \
    --output "${logs_file}" \
    --write-out '%{http_code}' \
    "${container_logs_url}")"; then
    rm -rf -- "${temporary_directory}"
    return 1
  fi

  case "${http_status}" in
    200)
      printf '[INFO] %s container logs: %s\n' "${APP_TYPE}" "${APP_NAME}"
      if [[ -s "${logs_file}" ]]; then
        cat "${logs_file}"
      else
        printf '[INFO] Container Logs API returned no log content\n'
      fi
      ;;
    204)
      printf '[INFO] Container Logs API returned no content: %s %s\n' "${APP_TYPE}" "${APP_NAME}"
      ;;
    *)
      local error_body
      error_body="$(<"${logs_file}")"
      printf '[ERROR] Get %s container logs failed (HTTP %s)\n%s\n' \
        "${APP_TYPE}" "${http_status}" "${error_body}" >&2
      rm -rf -- "${temporary_directory}"
      return 1
      ;;
  esac

  rm -rf -- "${temporary_directory}"
}

get_app_container_logs
