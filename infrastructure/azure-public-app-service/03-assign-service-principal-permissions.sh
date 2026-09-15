#!/usr/bin/env bash

set -Eeuo pipefail

AZURE_SUBSCRIPTION_ID='d423337a-8a9a-43fd-891c-4f57161bc69d'
SERVICE_PRINCIPAL_NAME='DEV:14053:MetIQ:Automation:AppDeploy'
RBAC_ASSIGNMENT_VARIABLE_PREFIX='rbac_assignment_'

declare -A rbac_assignment_resource_group_website_contributor=(
  [targetSubscriptionId]="${AZURE_SUBSCRIPTION_ID}"
  [targetResourceGroupName]='RG_00001_Public-App-Service_DV01'
  [roleDefinitionId]='de139f84-1756-47ae-9be6-808fbbe84772'
)

declare -A rbac_assignment_function_app_website_contributor=(
  [targetSubscriptionId]="${AZURE_SUBSCRIPTION_ID}"
  [targetResourceType]='Microsoft.Web/sites'
  [targetResourceGroupName]='RG_00001_Public-App-Service_DV01'
  [targetResourceName]='fpy00001kcdv0101'
  [roleDefinitionId]='de139f84-1756-47ae-9be6-808fbbe84772'
)

declare -A rbac_assignment_web_app_website_contributor=(
  [targetSubscriptionId]="${AZURE_SUBSCRIPTION_ID}"
  [targetResourceType]='Microsoft.Web/sites'
  [targetResourceGroupName]='RG_00001_Public-App-Service_DV01'
  [targetResourceName]='wbalx00001kcdv0101'
  [roleDefinitionId]='de139f84-1756-47ae-9be6-808fbbe84772'
)

command -v az >/dev/null

mapfile -t service_principal_object_ids < <(
  az ad sp list \
    --display-name "${SERVICE_PRINCIPAL_NAME}" \
    --query '[].id' \
    --output tsv
)

if [[ "${#service_principal_object_ids[@]}" -ne 1 ]]; then
  printf '[ERROR] Expected exactly one Service Principal named "%s", found %s\n' \
    "${SERVICE_PRINCIPAL_NAME}" "${#service_principal_object_ids[@]}" >&2
  exit 1
fi
service_principal_object_id="${service_principal_object_ids[0]}"

mapfile -t rbac_assignment_names < <(
  compgen -A variable -- "${RBAC_ASSIGNMENT_VARIABLE_PREFIX}"
)

for assignment_name in "${rbac_assignment_names[@]}"; do
  declare -n assignment="${assignment_name}"
  target_subscription_id="${assignment[targetSubscriptionId]:-${AZURE_SUBSCRIPTION_ID}}"
  target_resource_group_name="${assignment[targetResourceGroupName]:-}"
  target_resource_type="${assignment[targetResourceType]:-}"
  target_resource_name="${assignment[targetResourceName]:-}"
  role_definition_id="${assignment[roleDefinitionId]:-}"

  if [[ -z "${target_resource_group_name}" || -z "${role_definition_id}" ]]; then
    printf '[ERROR] RBAC assignment is missing a resource group or role definition ID\n' >&2
    exit 1
  fi

  if [[ -z "${target_resource_name}" ]]; then
    target_scope="/subscriptions/${target_subscription_id}/resourceGroups/${target_resource_group_name}"
  else
    if [[ -z "${target_resource_type}" ]]; then
      printf '[ERROR] targetResourceType is required when targetResourceName is specified\n' >&2
      exit 1
    fi
    target_scope="/subscriptions/${target_subscription_id}/resourceGroups/${target_resource_group_name}/providers/${target_resource_type}/${target_resource_name}"
  fi

  printf '[INFO] Assigning role definition "%s" to Service Principal: %s\n' \
    "${role_definition_id}" "${target_scope}"
  az role assignment create \
    --assignee-object-id "${service_principal_object_id}" \
    --assignee-principal-type ServicePrincipal \
    --role "${role_definition_id}" \
    --scope "${target_scope}" \
    --only-show-errors \
    --output json
done

printf '[SUCCESS] Service Principal permission assignment completed\n'
printf '[INFO] RBAC assignments processed: %s\n' "${#rbac_assignment_names[@]}"
