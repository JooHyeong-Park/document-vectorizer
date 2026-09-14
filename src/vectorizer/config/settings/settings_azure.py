from typing import Literal

from pydantic import model_validator
from vectorizer.contracts.errors import ErrorCode, create_error

from .settings_common import (
    BlobStorageAuthenticationMode,
    BlobStorageSettings,
    CommonSettings,
    EmbeddingAuthenticationMode,
    PostgreSQLAuthenticationMode,
)


class AzureSettings(CommonSettings):
    blob_storages: dict[str, BlobStorageSettings]
    postgresql_authentication_mode: PostgreSQLAuthenticationMode = (
        PostgreSQLAuthenticationMode.PASSWORD
    )

    @model_validator(mode="after")
    def validate_postgresql(self) -> "AzureSettings":
        if (
            self.postgresql_authentication_mode == PostgreSQLAuthenticationMode.PASSWORD
            and not self.postgresql_password
        ):
            raise create_error(ErrorCode.POSTGRESQL_PASSWORD_REQUIRED)
        return self

    @model_validator(mode="after")
    def validate_blob_storages(self) -> "AzureSettings":
        for name, storage in self.blob_storages.items():
            if (
                storage.authentication_mode
                != BlobStorageAuthenticationMode.MANAGED_IDENTITY
            ):
                raise create_error(
                    ErrorCode.AZURE_BLOB_STORAGE_AUTHENTICATION_INVALID, name=name
                )
            if not storage.azure_client_id:
                raise create_error(
                    ErrorCode.AZURE_BLOB_STORAGE_CLIENT_ID_REQUIRED, name=name
                )
        return self

    @model_validator(mode="after")
    def validate_embedding_profiles(self) -> "AzureSettings":
        for name, profile in self.embedding_profiles.items():
            if profile.provider != "azure_openai":
                raise create_error(
                    ErrorCode.AZURE_EMBEDDING_PROVIDER_INVALID, name=name
                )
            if (
                profile.authentication_mode
                != EmbeddingAuthenticationMode.MANAGED_IDENTITY
            ):
                raise create_error(
                    ErrorCode.AZURE_EMBEDDING_AUTHENTICATION_INVALID, name=name
                )
            if not profile.azure_client_id:
                raise create_error(
                    ErrorCode.AZURE_EMBEDDING_CLIENT_ID_REQUIRED, name=name
                )
        return self
