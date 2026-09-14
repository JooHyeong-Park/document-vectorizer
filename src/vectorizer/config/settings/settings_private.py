from typing import Literal

from vectorizer.contracts.errors import ErrorCode, create_error

from .settings_common import (
    BlobStorageAuthenticationMode,
    BlobStorageSettings,
    CommonSettings,
    EmbeddingAuthenticationMode,
    PostgreSQLAuthenticationMode,
)


class PrivateSettings(CommonSettings):
    blob_storages: dict[str, BlobStorageSettings]
    azure_tenant_id: str | None = None
    azure_client_id: str | None = None
    azure_client_secret: str | None = None

    postgresql_authentication_mode: PostgreSQLAuthenticationMode = (
        PostgreSQLAuthenticationMode.PASSWORD
    )

    @classmethod
    def _validate_azure_credentials(
        cls, mode: str, tenant_id: str | None, client_id: str | None, secret: str | None
    ) -> None:
        if mode in {
            BlobStorageAuthenticationMode.SERVICE_PRINCIPAL,
            EmbeddingAuthenticationMode.SERVICE_PRINCIPAL,
        } and not all((tenant_id, client_id, secret)):
            raise create_error(ErrorCode.SERVICE_PRINCIPAL_CREDENTIALS_REQUIRED)

    def model_post_init(self, __context: object) -> None:
        for name, storage in self.blob_storages.items():
            self._validate_azure_credentials(
                storage.authentication_mode,
                storage.azure_tenant_id,
                storage.azure_client_id,
                storage.azure_client_secret,
            )
        for name, profile in self.embedding_profiles.items():
            if profile.provider != "azure_openai":
                raise create_error(
                    ErrorCode.PRIVATE_EMBEDDING_PROVIDER_INVALID, name=name
                )
            self._validate_azure_credentials(
                profile.authentication_mode,
                profile.azure_tenant_id,
                profile.azure_client_id,
                profile.azure_client_secret,
            )
        if (
            self.postgresql_authentication_mode == PostgreSQLAuthenticationMode.PASSWORD
            and not self.postgresql_password
        ):
            raise create_error(ErrorCode.POSTGRESQL_PASSWORD_REQUIRED)
