import os
from functools import lru_cache
from typing import TypeAlias

from vectorizer.contracts.errors import ErrorCode, create_error

from .settings_azure import AzureSettings
from .settings_private import PrivateSettings
from .settings_public import PublicSettings

Settings: TypeAlias = PublicSettings | PrivateSettings | AzureSettings
SETTINGS_CLASS_BY_PROFILE = {
    "public": PublicSettings,
    "private": PrivateSettings,
    "azure": AzureSettings,
}


@lru_cache
def get_settings() -> Settings:
    profile = os.getenv("VECTORIZE_SETTINGS_PROFILE", "azure").lower()
    try:
        return SETTINGS_CLASS_BY_PROFILE[profile]()
    except KeyError as error:
        raise create_error(ErrorCode.INVALID_SETTINGS_PROFILE) from error
