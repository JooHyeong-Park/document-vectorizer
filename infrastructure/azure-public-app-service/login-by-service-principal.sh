#!/usr/bin/env bash

set -Eeuo pipefail

AZURE_TENANT_ID="${AZURE_TENANT_ID:?AZURE_TENANT_ID is required}"
AZURE_CLIENT_ID="${AZURE_CLIENT_ID:?AZURE_CLIENT_ID is required}"
azure_client_secret="${AZURE_CLIENT_SECRET:?AZURE_CLIENT_SECRET is required}"
unset AZURE_CLIENT_SECRET

AZURE_SCOPE="${AZURE_SCOPE:-https://management.azure.com/.default}"
AZURE_ACCESS_TOKEN_FILE="${AZURE_ACCESS_TOKEN_FILE:-${XDG_RUNTIME_DIR:-/tmp}/document-vectorizer-azure-access-token-${UID}}"

command -v curl >/dev/null
command -v jq >/dev/null

if [[ ! "${AZURE_TENANT_ID}" =~ ^[a-zA-Z0-9.-]+$ ]]; then
  printf '[ERROR] AZURE_TENANT_ID contains invalid characters\n' >&2
  exit 1
fi

urlencode() {
  jq --slurp --raw-input --raw-output '@uri'
}

client_id="$(printf '%s' "${AZURE_CLIENT_ID}" | urlencode)"
client_secret="$(printf '%s' "${azure_client_secret}" | urlencode)"
scope="$(printf '%s' "${AZURE_SCOPE}" | urlencode)"
unset azure_client_secret

token_endpoint="https://login.microsoftonline.com/${AZURE_TENANT_ID}/oauth2/v2.0/token"
request_body="client_id=${client_id}&client_secret=${client_secret}&scope=${scope}&grant_type=client_credentials"
unset client_secret

token_response="$(curl \
  --silent \
  --show-error \
  --request POST \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-binary @- \
  --write-out $'\n%{http_code}' \
  "${token_endpoint}" <<< "${request_body}")"
unset request_body

http_status="${token_response##*$'\n'}"
token_body="${token_response%$'\n'*}"

if [[ "${http_status}" != "200" ]]; then
  error_code="$(jq --raw-output '.error // "unknown_error"' <<< "${token_body}")"
  error_description="$(jq --raw-output '.error_description // "Token request failed"' <<< "${token_body}")"
  printf '[ERROR] Service Principal authentication failed: %s: %s\n' \
    "${error_code}" "${error_description}" >&2
  exit 1
fi

access_token="$(jq --raw-output '.access_token // empty' <<< "${token_body}")"
expires_in="$(jq --raw-output '.expires_in // 0' <<< "${token_body}")"
unset token_body token_response

if [[ -z "${access_token}" || ! "${expires_in}" =~ ^[0-9]+$ ]]; then
  printf '[ERROR] Invalid token response\n' >&2
  exit 1
fi

token_directory="$(dirname -- "${AZURE_ACCESS_TOKEN_FILE}")"
if [[ ! -d "${token_directory}" ]]; then
  printf '[ERROR] Token directory does not exist: %s\n' "${token_directory}" >&2
  exit 1
fi

temporary_token_file="$(mktemp "${AZURE_ACCESS_TOKEN_FILE}.XXXXXX")"
trap 'rm -f -- "${temporary_token_file}"' EXIT
printf '%s' "${access_token}" > "${temporary_token_file}"
unset access_token
chmod 600 "${temporary_token_file}"
mv -- "${temporary_token_file}" "${AZURE_ACCESS_TOKEN_FILE}"
trap - EXIT

printf '[SUCCESS] Azure Service Principal authentication completed\n'
printf '[INFO] Access token file: %s\n' "${AZURE_ACCESS_TOKEN_FILE}"
printf '[INFO] Access token lifetime: %s seconds\n' "${expires_in}"
