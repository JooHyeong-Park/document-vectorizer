#!/bin/bash

set -Eeuo pipefail

RESOURCE_GROUP="RG_00001_Public-App-Service_DV01"
FUNCTION_APP_NAME="fpy00001kcdv0101"
ACR_NAME="acr00001kcdv0101"
IMAGE_TAG="20260913-03"
IMAGE_URL="${ACR_NAME}.azurecr.io/document-vectorizer-function-app:${IMAGE_TAG}"
DEPLOYMENT_TIMEOUT_SECONDS=600
POLL_INTERVAL_SECONDS=10

command -v az >/dev/null
command -v curl >/dev/null

az functionapp config container set \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${FUNCTION_APP_NAME}" \
  --image "${IMAGE_URL}" \
  --registry-server "https://${ACR_NAME}.azurecr.io"

az functionapp restart --resource-group "${RESOURCE_GROUP}" --name "${FUNCTION_APP_NAME}"

hostname="$(az resource show \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${FUNCTION_APP_NAME}" \
  --resource-type Microsoft.Web/sites \
  --query properties.defaultHostName \
  --output tsv)"
url="https://${hostname}/api/health"

started_at="${SECONDS}"
attempt=0
while (( SECONDS - started_at < DEPLOYMENT_TIMEOUT_SECONDS )); do
  ((attempt += 1))
  state="$(az functionapp show \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${FUNCTION_APP_NAME}" \
    --query state \
    --output tsv)"
  configured_image="$(az resource show \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${FUNCTION_APP_NAME}" \
    --resource-type Microsoft.Web/sites \
    --query properties.siteConfig.linuxFxVersion \
    --output tsv)"
  printf '[INFO] Function deployment check %s: state=%s image=%s\n' \
    "${attempt}" "${state}" "${configured_image}"

  if [[ "${state}" == "Running" && "${configured_image}" == "DOCKER|${IMAGE_URL}" ]] \
    && curl --fail --silent --max-time 5 "${url}" >/dev/null; then
    printf '[SUCCESS] Function deployment and health check passed: %s\n' "${url}"
    exit 0
  fi

  sleep "${POLL_INTERVAL_SECONDS}"
done

printf '[ERROR] Function deployment verification timed out after %ss: %s\n' \
  "${DEPLOYMENT_TIMEOUT_SECONDS}" "${url}" >&2
az functionapp show --resource-group "${RESOURCE_GROUP}" --name "${FUNCTION_APP_NAME}" \
  --query '{state:state,hostNames:hostNames}' --output json >&2
exit 1
