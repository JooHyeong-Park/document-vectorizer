#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIRECTORY="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIRECTORY}/../.." && pwd)"
ENV_FILE="${SCRIPT_DIRECTORY}/_public-local-variables-by-image"
PYTHON_RUNTIME_ROOT="${HOME}/runtimes/python-3.13.15"
PYTHON_RUNTIME_BIN="${PYTHON_RUNTIME_ROOT}/bin"
PYTHON_SITE_PACKAGES="${PYTHON_RUNTIME_ROOT}/lib/python3.13/site-packages"

if [[ ! -f "${ENV_FILE}" ]]; then
  printf '[ERROR] environment file %s is not configured\n' "'${ENV_FILE}'" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

# Override image-oriented endpoints because this command runs on the host,
# while the shared environment file uses container network hostnames.
export BLOB_STORAGES__DEFAULT__ENDPOINT=http://127.0.0.1:10011/devstoreaccount1
export POSTGRESQL_HOST=127.0.0.1
export POSTGRESQL_PORT=10001
export EMBEDDING_PROFILES__DEFAULT__OPENROUTER_API_KEY="$(tr -d '\r\n' < "${HOME}/k-01.txt")"

if [[ ! -x "${PYTHON_RUNTIME_BIN}/python3.13" ]]; then
  printf '[ERROR] Python 3.13 executable %s is not available\n' "${PYTHON_RUNTIME_BIN}/python3.13" >&2
  exit 1
fi

export PATH="${PYTHON_RUNTIME_BIN}:${PATH}"
export PYTHONPATH="${PROJECT_ROOT}/src:${PYTHON_SITE_PACKAGES}${PYTHONPATH:+:${PYTHONPATH}}"

exec python -m adapters.azure_web_app.fastapi_app

# Verification:
# BASE_URL='http://127.0.0.1:8080/api'
# curl --fail "${BASE_URL}/health"
# for blob_path in \
#   'documents/01/01-sample.csv' \
#   'documents/01/02-sample.docx' \
#   'documents/01/03-sample.xlsx' \
#   'documents/01/04-sample.pptx' \
#   'documents/01/05-sample.pdf'; do
#   PAYLOAD="{\"blob_path\":\"${blob_path}\"}"
#   curl --fail --request POST "${BASE_URL}/documents/process" \
#     --header 'Content-Type: application/json' \
#     --data "${PAYLOAD}"
# done
