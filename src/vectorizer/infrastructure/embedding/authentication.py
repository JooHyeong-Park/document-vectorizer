from azure.identity import (
    AzureCliCredential,
    ClientSecretCredential,
    DefaultAzureCredential,
    get_bearer_token_provider,
)

from vectorizer.config.settings.settings_common import (
    EmbeddingAuthenticationMode,
    EmbeddingProfileSettings,
)


def create_azure_openai_token_provider(profile: EmbeddingProfileSettings):
    match profile.authentication_mode:
        case EmbeddingAuthenticationMode.API_KEY:
            return None
        case EmbeddingAuthenticationMode.AZURE_CLI:
            credential = AzureCliCredential()
        case EmbeddingAuthenticationMode.MANAGED_IDENTITY:
            credential = DefaultAzureCredential(
                managed_identity_client_id=profile.azure_client_id
            )
        case EmbeddingAuthenticationMode.SERVICE_PRINCIPAL:
            credential = ClientSecretCredential(
                profile.azure_tenant_id,
                profile.azure_client_id,
                profile.azure_client_secret,
            )
        case _:
            raise ValueError(
                f"[ERROR] unsupported embedding authentication mode '{profile.authentication_mode}'"
            )
    return get_bearer_token_provider(
        credential, "https://cognitiveservices.azure.com/.default"
    )
