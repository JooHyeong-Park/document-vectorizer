#!/bin/bash

set -Eeuo pipefail

SOURCE_DIR="$(dirname "${BASH_SOURCE[0]}")/../.."
ACR_NAME="acr00001kcdv0101"
IMAGE_TAG="20260913-02"
IMAGE_URL="${ACR_NAME}.azurecr.io/document-vectorizer-web-app:${IMAGE_TAG}"

command -v az >/dev/null
command -v podman >/dev/null

ACR_USERNAME="00000000-0000-0000-0000-000000000000"
ACR_TOKEN="$(az acr login --name "${ACR_NAME}" --expose-token --query accessToken --output tsv)"
# ACR Admin 인증이 필요하면 위 두 줄을 다음으로 교체합니다.
# ACR_USERNAME="$(az acr credential show --name "${ACR_NAME}" --query username --output tsv)"
# ACR_TOKEN="$(az acr credential show --name "${ACR_NAME}" --query 'passwords[0].value' --output tsv)"

printf '[INFO] Building Web image: %s\n' "${IMAGE_URL}"
podman build \
  --file "${SOURCE_DIR}/Dockerfile.web-app" \
  --tag "${IMAGE_URL}" \
  "${SOURCE_DIR}"

printf '[INFO] Logging in to ACR: %s\n' "${ACR_NAME}"
printf '%s' "${ACR_TOKEN}" | podman login "${ACR_NAME}.azurecr.io" \
  --username "${ACR_USERNAME}" \
  --password-stdin
podman push "${IMAGE_URL}"

printf '[SUCCESS] Web image build and push finished.\n'
