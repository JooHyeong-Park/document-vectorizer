"""Shared error contracts for core services and adapters."""

from .error_specs import ERROR_SPECS, ErrorCode, ErrorSpec
from .exceptions import VectorizerError, create_error

__all__ = [
    "ERROR_SPECS",
    "ErrorCode",
    "ErrorSpec",
    "VectorizerError",
    "create_error",
]
