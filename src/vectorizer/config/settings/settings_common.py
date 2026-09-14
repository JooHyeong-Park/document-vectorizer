from enum import StrEnum, auto
from typing import Literal

from pydantic import BaseModel, Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from vectorizer.contracts.errors import ErrorCode, create_error

# Shared default key for storage and embedding configuration.
DEFAULT_CONFIGURATION_NAME = "DEFAULT"


class BlobStorageAuthenticationMode(StrEnum):
    SERVICE_PRINCIPAL = auto()
    MANAGED_IDENTITY = auto()
    AZURE_CLI = auto()
    ACCOUNT_KEY = auto()


class EmbeddingAuthenticationMode(StrEnum):
    API_KEY = auto()
    SERVICE_PRINCIPAL = auto()
    MANAGED_IDENTITY = auto()
    AZURE_CLI = auto()


class PostgreSQLAuthenticationMode(StrEnum):
    PASSWORD = auto()
    MANAGED_IDENTITY = auto()


class BlobStorageSettings(BaseModel):
    endpoint: str
    authentication_mode: BlobStorageAuthenticationMode

    # PUBLIC-LOCAL
    # account_key is required only when using Azurite.
    account_key: str | None = None

    # PRIVATE-LOCAL
    # Azure Storage with service_principal authentication.
    azure_tenant_id: str | None = None

    # PRIVATE-LOCAL / AZURE-ASE
    # Service Principal client ID or user-assigned managed identity client ID.
    azure_client_id: str | None = None

    # PRIVATE-LOCAL
    # Azure Storage with service_principal authentication.
    azure_client_secret: str | None = None


class EmbeddingProfileSettings(BaseModel):
    provider: Literal["openrouter", "azure_openai"]
    endpoint: str
    authentication_mode: EmbeddingAuthenticationMode
    model: str

    dimensions: int = Field(gt=0)
    batch_size: int = Field(default=32, gt=0, le=2048)
    document_chunk_size: int = Field(gt=0)
    document_chunk_overlap: int = Field(ge=0)

    # PUBLIC-LOCAL
    # OpenRouter profile with api_key authentication.
    openrouter_api_key: str | None = None

    # PRIVATE-LOCAL
    # Azure OpenAI profile with api_key authentication.
    azure_openai_api_key: str | None = None
    # Azure Storage or Azure OpenAI profile with service_principal authentication.
    azure_tenant_id: str | None = None

    # PRIVATE-LOCAL
    # Azure Storage or Azure OpenAI profile with service_principal authentication.
    azure_client_secret: str | None = None

    # PRIVATE-LOCAL / AZURE-ASE
    # client ID :: Service Principal or user-assigned managed identity client ID.
    azure_client_id: str | None = None


class CommonSettings(BaseSettings):
    model_config = SettingsConfigDict(
        env_nested_delimiter="__",
        extra="ignore",
        case_sensitive=False,
    )

    blob_storages: dict[str, BlobStorageSettings]
    default_blob_storage: str = DEFAULT_CONFIGURATION_NAME

    postgresql_host: str
    postgresql_port: int = 5432
    postgresql_database_name: str
    postgresql_username: str
    postgresql_ssl_mode: str = "require"
    postgresql_password: str | None = None
    postgresql_azure_client_id: str | None = None

    embedding_profiles: dict[str, EmbeddingProfileSettings]
    default_embedding_profile: str = DEFAULT_CONFIGURATION_NAME

    max_document_size_mb: int = Field(default=50, gt=0)
    processing_timeout_seconds: int = Field(default=300, gt=0)

    @model_validator(mode="after")
    def validate_document_chunks(self) -> "CommonSettings":
        if not self.blob_storages:
            raise create_error(ErrorCode.BLOB_STORAGES_REQUIRED)
        blob_storage_names = {name.casefold(): name for name in self.blob_storages}
        default_name = DEFAULT_CONFIGURATION_NAME.casefold()
        if default_name not in blob_storage_names:
            raise create_error(ErrorCode.DEFAULT_BLOB_STORAGE_REQUIRED)
        self.default_blob_storage = blob_storage_names[default_name]
        embedding_profile_names = {
            name.casefold(): name for name in self.embedding_profiles
        }
        if default_name not in embedding_profile_names:
            raise create_error(ErrorCode.DEFAULT_EMBEDDING_PROFILE_REQUIRED)
        self.default_embedding_profile = embedding_profile_names[default_name]
        for name, profile in self.embedding_profiles.items():
            if profile.document_chunk_overlap >= profile.document_chunk_size:
                raise create_error(
                    ErrorCode.INVALID_DOCUMENT_CHUNK_CONFIGURATION, name=name
                )
        return self
