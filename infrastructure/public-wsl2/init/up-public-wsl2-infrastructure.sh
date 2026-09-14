#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE_NAME="public-wsl2-podman-compose.yml"
COMPOSE_PROJECT_NAME="document-vectorizer"
COMPOSE_FILE_PATH="${SCRIPT_DIRECTORY}/${COMPOSE_FILE_NAME}"

podman-compose \
  --project-name "${COMPOSE_PROJECT_NAME}" \
  --file "${COMPOSE_FILE_PATH}" \
  down \
  --remove-orphans \
  >/dev/null 2>&1 || true

for container_name in \
  document-vectorizer-postgresql \
  document-vectorizer-azurite \
  document-vectorizer-cloudbeaver \
  document-vectorizer-storage-explorer; do
  podman stop "${container_name}" >/dev/null 2>&1 || true
  podman rm "${container_name}" >/dev/null 2>&1 || true
done

exec podman-compose \
  --project-name "${COMPOSE_PROJECT_NAME}" \
  --file "${COMPOSE_FILE_PATH}" \
  up \
  --detach \
  --pull never
