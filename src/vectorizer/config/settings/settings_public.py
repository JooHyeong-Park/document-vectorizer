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


class PublicSettings(CommonSettings):
    blob_storages: dict[str, BlobStorageSettings]

    postgresql_authentication_mode: PostgreSQLAuthenticationMode = (
        PostgreSQLAuthenticationMode.PASSWORD
    )
    postgresql_ssl_mode: Literal["disable"] = "disable"
    postgresql_password: str

    @model_validator(mode="after")
    def validate_blob_storages(self) -> "PublicSettings":
        for name, storage in self.blob_storages.items():
            if (
                storage.authentication_mode != BlobStorageAuthenticationMode.ACCOUNT_KEY
                or not storage.account_key
            ):
                raise create_error(
                    ErrorCode.PUBLIC_BLOB_STORAGE_AUTHENTICATION_INVALID, name=name
                )
        return self

    @model_validator(mode="after")
    def validate_embedding_profiles(self) -> "PublicSettings":
        for name, profile in self.embedding_profiles.items():
            if profile.provider != "openrouter":
                raise create_error(
                    ErrorCode.PUBLIC_EMBEDDING_PROVIDER_INVALID, name=name
                )
            if (
                profile.authentication_mode != EmbeddingAuthenticationMode.API_KEY
                or not profile.openrouter_api_key
            ):
                raise create_error(
                    ErrorCode.PUBLIC_EMBEDDING_AUTHENTICATION_INVALID, name=name
                )
        return self
