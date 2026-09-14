"""Shared application and API constants."""

from enum import StrEnum

APPLICATION_TITLE = "Document Vectorizer"
API_ROUTE_PREFIX = "/api"


class HttpApiPath(StrEnum):
    HEALTH = "health"
    DOCUMENTS_PROCESS = "documents/process"
