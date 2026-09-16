#!/usr/bin/env bash
set -euo pipefail

# Function App configuration. Update these values before running this script.
SUBSCRIPTION_ID="d423337a-8a9a-43fd-891c-4f57161bc69d"
LOCATION="koreacentral"
RESOURCE_GROUP_NAME="RG_00003_MetIQ_PR01"

FUNCTION_APP_NAME="fpy00003kcpr0101"
MANAGED_IDENTITY_NAME="MI-FPY00003KCPR0101"
APP_SERVICE_PLAN_NAME="apx00003kcpr0101"
STORAGE_ACCOUNT_NAME="sa00003kcpr0101"
ACR_NAME="acr00003kcpr0101"
KEY_VAULT_NAME="kyv00003kcpr0101"
LOG_ANALYTICS_RESOURCE_GROUP_NAME="${RESOURCE_GROUP_NAME}"
LOG_ANALYTICS_WORKSPACE_NAME="LogAnalytics-MetIQ-PR01"

CONTAINER_IMAGE_NAME="${ACR_NAME}.azurecr.io/${FUNCTION_APP_NAME}:latest"

# Function App environment variables. Add or update entries here when needed.
declare -A FUNCTION_APP_SETTINGS=(
  [FUNCTIONS_EXTENSION_VERSION]="~4"
  [FUNCTIONS_WORKER_RUNTIME]="python"
  [WEBSITES_PORT]="8080"
  [WEBSITES_ENABLE_APP_SERVICE_STORAGE]="false"
  [AzureFunctionsWebHost__hostId]="${FUNCTION_APP_NAME}"
  [AzureWebJobsStorage__credential]="managedidentity"
  [AzureWebJobsStorage__blobServiceUri]="https://${STORAGE_ACCOUNT_NAME}.blob.core.windows.net"
  [AzureWebJobsStorage__queueServiceUri]="https://${STORAGE_ACCOUNT_NAME}.queue.core.windows.net"
  [AzureWebJobsStorage__tableServiceUri]="https://${STORAGE_ACCOUNT_NAME}.table.core.windows.net"
)

TAGS=(
  "DPCCODE=W003 CORP DIST"
  "EAICODE=00003"
  "ENV=Prod"
  "TENANT=Azure"
)

RBAC_ASSIGNMENT_VARIABLE_PREFIX="rbac_assignment_"

declare -A rbac_assignment_storage_blob_data_owner=(
  [targetResourceType]="Microsoft.Storage/storageAccounts"
  [targetResourceGroupName]="${RESOURCE_GROUP_NAME}"
  [targetResourceName]="${STORAGE_ACCOUNT_NAME}"
  [roleDefinitionId]="b7e6dc6d-f1e8-4753-8033-0f276bb0955b"
  [roleName]="Storage Blob Data Owner"
)

declare -A rbac_assignment_storage_queue_data_contributor=(
  [targetResourceType]="Microsoft.Storage/storageAccounts"
  [targetResourceGroupName]="${RESOURCE_GROUP_NAME}"
  [targetResourceName]="${STORAGE_ACCOUNT_NAME}"
  [roleDefinitionId]="974c5e8b-45b9-4653-ba55-5f855dd0fb88"
  [roleName]="Storage Queue Data Contributor"
)

declare -A rbac_assignment_storage_table_data_contributor=(
  [targetResourceType]="Microsoft.Storage/storageAccounts"
  [targetResourceGroupName]="${RESOURCE_GROUP_NAME}"
  [targetResourceName]="${STORAGE_ACCOUNT_NAME}"
  [roleDefinitionId]="0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3"
  [roleName]="Storage Table Data Contributor"
)

declare -A rbac_assignment_acr_pull=(
  [targetResourceType]="Microsoft.ContainerRegistry/registries"
  [targetResourceGroupName]="${RESOURCE_GROUP_NAME}"
  [targetResourceName]="${ACR_NAME}"
  [roleDefinitionId]="7f951dda-4ed3-4680-a7ca-43fe172d538d"
  [roleName]="AcrPull"
)

declare -A rbac_assignment_key_vault_secrets_user=(
  [targetResourceType]="Microsoft.KeyVault/vaults"
  [targetResourceGroupName]="${RESOURCE_GROUP_NAME}"
  [targetResourceName]="${KEY_VAULT_NAME}"
  [roleDefinitionId]="4633458b-17de-408a-b874-0445c86b69e6"
  [roleName]="Key Vault Secrets User"
)

declare -A rbac_assignment_key_vault_certificate_user=(
  [targetResourceType]="Microsoft.KeyVault/vaults"
  [targetResourceGroupName]="${RESOURCE_GROUP_NAME}"
  [targetResourceName]="${KEY_VAULT_NAME}"
  [roleDefinitionId]="db79e9a7-68ee-4b58-9aeb-b90e7c24fcba"
  [roleName]="Key Vault Certificate User"
)

if command -v az > /dev/null 2>&1; then
  AZ_COMMAND="az"
elif command -v az.cmd > /dev/null 2>&1; then
  AZ_COMMAND="az.cmd"
else
  printf '[ERROR] Azure CLI executable was not found (tried: az, az.cmd).\n' >&2
  exit 1
fi

"${AZ_COMMAND}" account set --subscription "${SUBSCRIPTION_ID}"

require_resource() {
  local resource_id_value=$1
  local resource_description=$2

  if ! "${AZ_COMMAND}" resource show --ids "${resource_id_value}" --query id --output tsv >/dev/null 2>&1; then
    printf '[ERROR] Required existing resource was not found: %s (%s)\n' "${resource_description}" "${resource_id_value}" >&2
    exit 1
  fi
}

role_assignment_exists() {
  local principal_id=$1
  local role_definition_id=$2
  local scope=$3
  local subscription_id=$4

  [[ -n "$("${AZ_COMMAND}" role assignment list \
    --assignee-object-id "${principal_id}" \
    --scope "${scope}" \
    --role "${role_definition_id}" \
    --subscription "${subscription_id}" \
    --query '[0].id' \
    --output tsv 2>/dev/null || true)" ]]
}

ensure_role_assignment() {
  local subscription_id=$1
  local role_definition_id=$2
  local scope=$3
  local role_name=$4

  if role_assignment_exists "${MANAGED_IDENTITY_PRINCIPAL_ID}" "${role_definition_id}" "${scope}" "${subscription_id}"; then
    printf '[INFO] Role assignment already exists: %s\n' "${role_name}"
    return
  fi

  "${AZ_COMMAND}" role assignment create \
    --assignee-object-id "${MANAGED_IDENTITY_PRINCIPAL_ID}" \
    --assignee-principal-type ServicePrincipal \
    --role "${role_definition_id}" \
    --scope "${scope}" \
    --subscription "${subscription_id}" \
    --output none
  printf '[INFO] Role assignment created: %s\n' "${role_name}"
}

RESOURCE_GROUP_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}"
APP_SERVICE_PLAN_ID="${RESOURCE_GROUP_ID}/providers/Microsoft.Web/serverfarms/${APP_SERVICE_PLAN_NAME}"
LOG_ANALYTICS_WORKSPACE_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${LOG_ANALYTICS_RESOURCE_GROUP_NAME}/providers/Microsoft.OperationalInsights/workspaces/${LOG_ANALYTICS_WORKSPACE_NAME}"

declare -A REQUIRED_RESOURCES=(
  ["${RESOURCE_GROUP_ID}"]="resource group"
  ["${APP_SERVICE_PLAN_ID}"]="App Service Plan"
  ["${LOG_ANALYTICS_WORKSPACE_ID}"]="Log Analytics Workspace"
)

mapfile -t RBAC_ASSIGNMENT_NAMES < <(
  compgen -A variable -- "${RBAC_ASSIGNMENT_VARIABLE_PREFIX}"
)

for assignment_name in "${RBAC_ASSIGNMENT_NAMES[@]}"; do
  declare -n assignment="${assignment_name}"
  target_subscription_id="${assignment[targetSubscriptionId]:-${SUBSCRIPTION_ID}}"
  target_resource_group_name="${assignment[targetResourceGroupName]:-}"
  target_resource_type="${assignment[targetResourceType]:-}"
  target_resource_name="${assignment[targetResourceName]:-}"
  role_definition_id="${assignment[roleDefinitionId]:-}"
  role_name="${assignment[roleName]:-}"

  if [[ -z "${target_subscription_id}" || -z "${target_resource_group_name}" || -z "${target_resource_type}" || -z "${target_resource_name}" || -z "${role_definition_id}" || -z "${role_name}" ]]; then
    printf '[ERROR] RBAC assignment is missing a target resource or role definition: %s\n' "${assignment_name}" >&2
    exit 1
  fi

  target_scope="/subscriptions/${target_subscription_id}/resourceGroups/${target_resource_group_name}/providers/${target_resource_type}/${target_resource_name}"
  REQUIRED_RESOURCES["${target_scope}"]="${target_resource_type}/${target_resource_name}"
done

for required_resource_id in "${!REQUIRED_RESOURCES[@]}"; do
  require_resource "${required_resource_id}" "${REQUIRED_RESOURCES[${required_resource_id}]}"
done

MANAGED_IDENTITY_EXISTS=false
if "${AZ_COMMAND}" identity show \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --name "${MANAGED_IDENTITY_NAME}" \
  --query id \
  --output tsv >/dev/null 2>&1; then
  MANAGED_IDENTITY_EXISTS=true
fi

FUNCTION_APP_ID="${RESOURCE_GROUP_ID}/providers/Microsoft.Web/sites/${FUNCTION_APP_NAME}"
FUNCTION_APP_EXISTS=false
if "${AZ_COMMAND}" functionapp show \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --name "${FUNCTION_APP_NAME}" \
  --query id \
  --output tsv >/dev/null 2>&1; then
  FUNCTION_APP_EXISTS=true
fi

if [[ "${MANAGED_IDENTITY_EXISTS}" == false ]]; then
  "${AZ_COMMAND}" identity create \
    --resource-group "${RESOURCE_GROUP_NAME}" \
    --name "${MANAGED_IDENTITY_NAME}" \
    --location "${LOCATION}" \
    --tags "${TAGS[@]}" \
    --output none
  printf '[INFO] Managed Identity created: %s\n' "${MANAGED_IDENTITY_NAME}"
else
  printf '[INFO] Managed Identity already exists: %s\n' "${MANAGED_IDENTITY_NAME}"
fi

MANAGED_IDENTITY_ID=$("${AZ_COMMAND}" identity show \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --name "${MANAGED_IDENTITY_NAME}" \
  --query id \
  --output tsv)

MANAGED_IDENTITY_CLIENT_ID=$("${AZ_COMMAND}" identity show \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --name "${MANAGED_IDENTITY_NAME}" \
  --query clientId \
  --output tsv)

MANAGED_IDENTITY_PRINCIPAL_ID=$("${AZ_COMMAND}" identity show \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --name "${MANAGED_IDENTITY_NAME}" \
  --query principalId \
  --output tsv)

FUNCTION_APP_SETTINGS[AzureWebJobsStorage__clientId]="${MANAGED_IDENTITY_CLIENT_ID}"

for assignment_name in "${RBAC_ASSIGNMENT_NAMES[@]}"; do
  declare -n assignment="${assignment_name}"
  target_subscription_id="${assignment[targetSubscriptionId]:-${SUBSCRIPTION_ID}}"
  target_resource_group_name="${assignment[targetResourceGroupName]}"
  target_resource_type="${assignment[targetResourceType]}"
  target_resource_name="${assignment[targetResourceName]}"
  role_definition_id="${assignment[roleDefinitionId]:-}"
  role_name="${assignment[roleName]:-}"
  target_scope="/subscriptions/${target_subscription_id}/resourceGroups/${target_resource_group_name}/providers/${target_resource_type}/${target_resource_name}"
  ensure_role_assignment "${target_subscription_id}" "${role_definition_id}" "${target_scope}" "${role_name}"
done

if [[ "${FUNCTION_APP_EXISTS}" == false ]]; then
  "${AZ_COMMAND}" functionapp create \
    --resource-group "${RESOURCE_GROUP_NAME}" \
    --name "${FUNCTION_APP_NAME}" \
    --storage-account "${STORAGE_ACCOUNT_NAME}" \
    --plan "${APP_SERVICE_PLAN_NAME}" \
    --image "${CONTAINER_IMAGE_NAME}" \
    --assign-identity "${MANAGED_IDENTITY_ID}" \
    --functions-version 4 \
    --runtime custom \
    --os-type Linux \
    --https-only true \
    --configure-networking-later \
    --disable-app-insights \
    --tags "${TAGS[@]}" \
    --only-show-errors \
    --output none
  printf '[INFO] Function App created: %s\n' "${FUNCTION_APP_NAME}"
else
  printf '[INFO] Function App already exists: %s\n' "${FUNCTION_APP_NAME}"
fi

APP_SETTINGS_ARGUMENTS=()
for setting_name in "${!FUNCTION_APP_SETTINGS[@]}"; do
  APP_SETTINGS_ARGUMENTS+=("${setting_name}=${FUNCTION_APP_SETTINGS[${setting_name}]}")
done

"${AZ_COMMAND}" functionapp config appsettings set \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --name "${FUNCTION_APP_NAME}" \
  --settings "${APP_SETTINGS_ARGUMENTS[@]}" \
  --only-show-errors \
  --output none

"${AZ_COMMAND}" functionapp config set \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --name "${FUNCTION_APP_NAME}" \
  --always-on true \
  --ftps-state Disabled \
  --min-tls-version 1.2 \
  --vnet-route-all-enabled true \
  --generic-configurations "{\"acrUseManagedIdentityCreds\":true,\"acrUserManagedIdentityID\":\"${MANAGED_IDENTITY_CLIENT_ID}\"}" \
  --only-show-errors \
  --output none

"${AZ_COMMAND}" functionapp update \
  --resource-group "${RESOURCE_GROUP_NAME}" \
  --name "${FUNCTION_APP_NAME}" \
  --set httpsOnly=true clientAffinityEnabled=false publicNetworkAccess=Disabled \
  --output none

for policy_name in ftp scm; do
  "${AZ_COMMAND}" rest \
    --method put \
    --url "https://management.azure.com${FUNCTION_APP_ID}/basicPublishingCredentialsPolicies/${policy_name}?api-version=2025-03-01" \
    --body '{"properties":{"allow":false}}' \
    --output none
done

"${AZ_COMMAND}" monitor diagnostic-settings create \
  --name "ds-logAnalyticsWorkspace" \
  --resource "${FUNCTION_APP_ID}" \
  --workspace "${LOG_ANALYTICS_WORKSPACE_ID}" \
  --logs '[{"category":"FunctionAppLogs","enabled":true}]' \
  --metrics '[]' \
  --output none

printf '[SUCCESS] Function App configuration completed: %s\n' "${FUNCTION_APP_NAME}"
