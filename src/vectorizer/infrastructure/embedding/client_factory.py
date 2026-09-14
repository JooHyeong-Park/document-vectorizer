from openai import AzureOpenAI, OpenAI

from vectorizer.config.settings.settings_common import EmbeddingAuthenticationMode
from vectorizer.infrastructure.embedding.authentication import (
    create_azure_openai_token_provider,
)
from vectorizer.infrastructure.embedding.embedding_client import EmbeddingClient


def create_embedding_client(
    settings, profile_name: str | None = None
) -> EmbeddingClient:
    selected_name = profile_name or settings.default_embedding_profile
    profile_key = next(
        (
            name
            for name in settings.embedding_profiles
            if name.casefold() == selected_name.casefold()
        ),
        None,
    )
    if profile_key is None:
        raise ValueError(
            f"[ERROR] embedding profile '{selected_name}' is not configured"
        )
    profile = settings.embedding_profiles[profile_key]
    if profile.provider == "openrouter":
        if not profile.openrouter_api_key:
            raise ValueError(
                f"[ERROR] embedding profile '{profile_key}' requires an OpenRouter API key"
            )
        client = OpenAI(base_url=profile.endpoint, api_key=profile.openrouter_api_key)
    elif profile.authentication_mode == EmbeddingAuthenticationMode.API_KEY:
        if not profile.azure_openai_api_key:
            raise ValueError(
                f"[ERROR] embedding profile '{profile_key}' requires an Azure OpenAI API key"
            )
        client = AzureOpenAI(
            azure_endpoint=profile.endpoint,
            api_key=profile.azure_openai_api_key,
            api_version="2024-10-21",
        )
    else:
        client = AzureOpenAI(
            azure_endpoint=profile.endpoint,
            azure_ad_token_provider=create_azure_openai_token_provider(profile),
            api_version="2024-10-21",
        )
    return EmbeddingClient(
        client, profile.model, profile.dimensions, profile.batch_size
    )
