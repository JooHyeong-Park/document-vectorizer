from dataclasses import dataclass
from enum import StrEnum, auto

# [Note] Keep declarations ordered as ErrorCode -> ErrorSpec -> ERROR_SPECS.
# ErrorSpec references ErrorCode, and ERROR_SPECS instantiates ErrorSpec.


class ErrorCode(StrEnum):
    # Generate each enum value from its member name so name and value match.
    @staticmethod
    def _generate_next_value_(name, start, count, last_values):
        return name

    INVALID_SETTINGS_PROFILE = auto()
    BLOB_STORAGES_REQUIRED = auto()
    DEFAULT_BLOB_STORAGE_REQUIRED = auto()
    DEFAULT_EMBEDDING_PROFILE_REQUIRED = auto()
    INVALID_DOCUMENT_CHUNK_CONFIGURATION = auto()
    SERVICE_PRINCIPAL_CREDENTIALS_REQUIRED = auto()
    POSTGRESQL_PASSWORD_REQUIRED = auto()
    STORAGE_ACCOUNT_NOT_FOUND = auto()
    PUBLIC_BLOB_STORAGE_AUTHENTICATION_INVALID = auto()
    AZURE_BLOB_STORAGE_AUTHENTICATION_INVALID = auto()
    AZURE_BLOB_STORAGE_CLIENT_ID_REQUIRED = auto()
    EMBEDDING_PROFILE_NOT_FOUND = auto()
    PUBLIC_EMBEDDING_PROVIDER_INVALID = auto()
    PUBLIC_EMBEDDING_AUTHENTICATION_INVALID = auto()
    PRIVATE_EMBEDDING_PROVIDER_INVALID = auto()
    AZURE_EMBEDDING_PROVIDER_INVALID = auto()
    AZURE_EMBEDDING_AUTHENTICATION_INVALID = auto()
    AZURE_EMBEDDING_CLIENT_ID_REQUIRED = auto()
    INVALID_BLOB_PATH = auto()


@dataclass(frozen=True)
class ErrorSpec:
    code: ErrorCode
    status_code: int
    message_template: str


ERROR_SPECS = {
    ErrorCode.INVALID_SETTINGS_PROFILE: ErrorSpec(
        code=ErrorCode.INVALID_SETTINGS_PROFILE,
        status_code=400,
        message_template="SETTINGS_PROFILE must be public, private, or azure",
    ),
    ErrorCode.BLOB_STORAGES_REQUIRED: ErrorSpec(
        code=ErrorCode.BLOB_STORAGES_REQUIRED,
        status_code=400,
        message_template="at least one blob storage must be configured",
    ),
    ErrorCode.DEFAULT_BLOB_STORAGE_REQUIRED: ErrorSpec(
        code=ErrorCode.DEFAULT_BLOB_STORAGE_REQUIRED,
        status_code=400,
        message_template="blob_storages must include a DEFAULT storage",
    ),
    ErrorCode.DEFAULT_EMBEDDING_PROFILE_REQUIRED: ErrorSpec(
        code=ErrorCode.DEFAULT_EMBEDDING_PROFILE_REQUIRED,
        status_code=400,
        message_template="embedding_profiles must include a DEFAULT profile",
    ),
    ErrorCode.INVALID_DOCUMENT_CHUNK_CONFIGURATION: ErrorSpec(
        code=ErrorCode.INVALID_DOCUMENT_CHUNK_CONFIGURATION,
        status_code=400,
        message_template="document_chunk_overlap must be smaller than document_chunk_size in embedding profile '{name}'",
    ),
    ErrorCode.SERVICE_PRINCIPAL_CREDENTIALS_REQUIRED: ErrorSpec(
        code=ErrorCode.SERVICE_PRINCIPAL_CREDENTIALS_REQUIRED,
        status_code=400,
        message_template="service_principal authentication requires tenant, client, and secret",
    ),
    ErrorCode.POSTGRESQL_PASSWORD_REQUIRED: ErrorSpec(
        code=ErrorCode.POSTGRESQL_PASSWORD_REQUIRED,
        status_code=400,
        message_template="POSTGRESQL_PASSWORD is required for password authentication",
    ),
    ErrorCode.STORAGE_ACCOUNT_NOT_FOUND: ErrorSpec(
        code=ErrorCode.STORAGE_ACCOUNT_NOT_FOUND,
        status_code=400,
        message_template="blob storage '{name}' is not configured",
    ),
    ErrorCode.PUBLIC_BLOB_STORAGE_AUTHENTICATION_INVALID: ErrorSpec(
        code=ErrorCode.PUBLIC_BLOB_STORAGE_AUTHENTICATION_INVALID,
        status_code=400,
        message_template="public blob storage '{name}' requires account_key authentication",
    ),
    ErrorCode.AZURE_BLOB_STORAGE_AUTHENTICATION_INVALID: ErrorSpec(
        code=ErrorCode.AZURE_BLOB_STORAGE_AUTHENTICATION_INVALID,
        status_code=400,
        message_template="azure blob storage '{name}' requires managed_identity authentication",
    ),
    ErrorCode.AZURE_BLOB_STORAGE_CLIENT_ID_REQUIRED: ErrorSpec(
        code=ErrorCode.AZURE_BLOB_STORAGE_CLIENT_ID_REQUIRED,
        status_code=400,
        message_template="azure blob storage '{name}' requires azure_client_id",
    ),
    ErrorCode.EMBEDDING_PROFILE_NOT_FOUND: ErrorSpec(
        code=ErrorCode.EMBEDDING_PROFILE_NOT_FOUND,
        status_code=400,
        message_template="embedding profile '{name}' is not configured",
    ),
    ErrorCode.PUBLIC_EMBEDDING_PROVIDER_INVALID: ErrorSpec(
        code=ErrorCode.PUBLIC_EMBEDDING_PROVIDER_INVALID,
        status_code=400,
        message_template="public embedding profile '{name}' requires openrouter",
    ),
    ErrorCode.PUBLIC_EMBEDDING_AUTHENTICATION_INVALID: ErrorSpec(
        code=ErrorCode.PUBLIC_EMBEDDING_AUTHENTICATION_INVALID,
        status_code=400,
        message_template="public embedding profile '{name}' requires an OpenRouter API key",
    ),
    ErrorCode.PRIVATE_EMBEDDING_PROVIDER_INVALID: ErrorSpec(
        code=ErrorCode.PRIVATE_EMBEDDING_PROVIDER_INVALID,
        status_code=400,
        message_template="private embedding profile '{name}' requires azure_openai",
    ),
    ErrorCode.AZURE_EMBEDDING_PROVIDER_INVALID: ErrorSpec(
        code=ErrorCode.AZURE_EMBEDDING_PROVIDER_INVALID,
        status_code=400,
        message_template="azure embedding profile '{name}' requires azure_openai",
    ),
    ErrorCode.AZURE_EMBEDDING_AUTHENTICATION_INVALID: ErrorSpec(
        code=ErrorCode.AZURE_EMBEDDING_AUTHENTICATION_INVALID,
        status_code=400,
        message_template="azure embedding profile '{name}' requires managed_identity",
    ),
    ErrorCode.AZURE_EMBEDDING_CLIENT_ID_REQUIRED: ErrorSpec(
        code=ErrorCode.AZURE_EMBEDDING_CLIENT_ID_REQUIRED,
        status_code=400,
        message_template="azure embedding profile '{name}' requires azure_client_id",
    ),
    ErrorCode.INVALID_BLOB_PATH: ErrorSpec(
        code=ErrorCode.INVALID_BLOB_PATH,
        status_code=400,
        message_template=(
            "invalid blob path '{blob_path}'; expected "
            "'<container>/<blob-name>'; blob-name may contain '/'"
        ),
    ),
}
