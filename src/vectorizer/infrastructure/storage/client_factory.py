from azure.storage.blob import BlobServiceClient

from vectorizer.contracts.errors import ErrorCode, create_error
from vectorizer.infrastructure.storage.authentication import create_blob_credential


def create_storage_account_client(settings, storage_name: str) -> BlobServiceClient:
    configured_storage_name = next(
        (
            name
            for name in settings.blob_storages
            if name.casefold() == storage_name.casefold()
        ),
        None,
    )
    if configured_storage_name is None:
        raise create_error(
            ErrorCode.STORAGE_ACCOUNT_NOT_FOUND,
            name=storage_name,
        )
    storage_settings = settings.blob_storages[configured_storage_name]
    client = BlobServiceClient(
        storage_settings.endpoint,
        credential=create_blob_credential(storage_settings),
    )
    return client
