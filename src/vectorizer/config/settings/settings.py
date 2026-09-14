import os
from functools import lru_cache
from typing import TypeAlias

from vectorizer.contracts.errors import ErrorCode, create_error

from .settings_azure import AzureSettings
from .settings_private import PrivateSettings
from .settings_public import PublicSettings

# Environment variable used to select the application settings profile.
SETTINGS_PROFILE_ENV_VAR = "VECTORIZE_SETTINGS_PROFILE"

# Settings profile used when the environment variable is not defined.
DEFAULT_SETTINGS_PROFILE = "azure"

Settings: TypeAlias = PublicSettings | PrivateSettings | AzureSettings
SETTINGS_CLASS_BY_PROFILE = {
    "public": PublicSettings,
    "private": PrivateSettings,
    "azure": AzureSettings,
}


@lru_cache
def get_settings() -> Settings:
    profile = os.getenv(SETTINGS_PROFILE_ENV_VAR, DEFAULT_SETTINGS_PROFILE).lower()
    try:
        return SETTINGS_CLASS_BY_PROFILE[profile]()
    except KeyError as error:
        raise create_error(ErrorCode.INVALID_SETTINGS_PROFILE) from error
