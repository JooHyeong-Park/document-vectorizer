#!/usr/bin/env bash

set -Eeuo pipefail

SERVICE_PRINCIPAL_NAME='DEV:14053:MetIQ:Automation:AppDeploy'

command -v az >/dev/null

printf '[INFO] Creating Service Principal %s\n' "${SERVICE_PRINCIPAL_NAME}"
az ad sp create-for-rbac \
  --name "${SERVICE_PRINCIPAL_NAME}" \
  --create-password false \
  --skip-assignment \
  --only-show-errors \
  --output json

printf '[INFO] Register the generated certificate manually in the App Registration.\n'
