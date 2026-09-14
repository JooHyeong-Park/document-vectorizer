from urllib.parse import urlparse

from azure.core.credentials import AzureNamedKeyCredential
from azure.identity import (
    AzureCliCredential,
    ClientSecretCredential,
    DefaultAzureCredential,
)

from vectorizer.config.settings.settings_common import (
    BlobStorageAuthenticationMode,
    BlobStorageSettings,
)


def _create_account_key_credential(settings: BlobStorageSettings):
    parsed_endpoint = urlparse(settings.endpoint)
    account_name = parsed_endpoint.path.strip("/").split("/", maxsplit=1)[0]
    if not account_name and parsed_endpoint.hostname:
        account_name = parsed_endpoint.hostname.split(".", maxsplit=1)[0]
    return AzureNamedKeyCredential(account_name, settings.account_key)


def create_blob_credential(settings: BlobStorageSettings):
    match settings.authentication_mode:
        case BlobStorageAuthenticationMode.ACCOUNT_KEY:
            return _create_account_key_credential(settings)
        case BlobStorageAuthenticationMode.SERVICE_PRINCIPAL:
            return ClientSecretCredential(
                settings.azure_tenant_id,
                settings.azure_client_id,
                settings.azure_client_secret,
            )
        case BlobStorageAuthenticationMode.AZURE_CLI:
            return AzureCliCredential()
        case BlobStorageAuthenticationMode.MANAGED_IDENTITY:
            return DefaultAzureCredential(
                managed_identity_client_id=settings.azure_client_id
            )
        case _:
            raise ValueError(
                f"[ERROR] unsupported Blob Storage authentication mode '{settings.authentication_mode}'"
            )
