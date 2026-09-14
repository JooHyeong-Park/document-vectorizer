#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../.." && pwd)"
ENV_FILE="${SCRIPT_DIRECTORY}/_public-local-variables-by-image"
IMAGE_URL="${IMAGE_URL:-localhost/document-vectorizer-function-app:clean}"
CONTAINER_NAME="${CONTAINER_NAME:-document-vectorizer-function-app}"
PODMAN_NETWORK="${PODMAN_NETWORK:-vectorizer-network}"
HOST_PORT="${HOST_PORT:-8080}"
FUNCTION_PORT="${FUNCTION_PORT:-8080}"

if [[ ! -f "${ENV_FILE}" ]]; then
  printf '[ERROR] environment file %s is not configured\n' "'${ENV_FILE}'" >&2
  exit 1
fi
set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

OPENROUTER_API_KEY="$(tr -d '\r\n' < "${HOME}/k-01.txt")"

cd "${PROJECT_ROOT}"

printf '[INFO] Build image %s\n' "${IMAGE_URL}"
podman build \
  --no-cache \
  --file "${PROJECT_ROOT}/Dockerfile.function-app" \
  --tag "${IMAGE_URL}" \
  "${PROJECT_ROOT}"

printf '[INFO] Remove existing container %s\n' "${CONTAINER_NAME}"
podman rm --force "${CONTAINER_NAME}" >/dev/null 2>&1 || true

printf '[INFO] Run container %s on port %s\n' "${CONTAINER_NAME}" "${HOST_PORT}"
# The OpenRouter API key is evaluated and supplied separately at runtime.
podman run \
  --name "${CONTAINER_NAME}" \
  --network "${PODMAN_NETWORK}" \
  --publish "${HOST_PORT}:${FUNCTION_PORT}" \
  --env-file "${ENV_FILE}" \
  --env "EMBEDDING_PROFILES__DEFAULT__OPENROUTER_API_KEY=${OPENROUTER_API_KEY}" \
  "${IMAGE_URL}"

status=$?
exit "${status}"

# Verification:
# BASE_URL="http://127.0.0.1:${HOST_PORT}/api"
# curl --fail "${BASE_URL}/health"
# curl --fail --request POST "${BASE_URL}/documents/process" \
#   --header 'Content-Type: application/json' \
#   --data '{"blob_path":"documents/01/01-sample.csv"}'
