from pydantic import BaseModel, Field

from vectorizer.contracts.errors import ErrorCode, create_error


class DocumentsProcessRequest(BaseModel):
    blob_path: str = Field(min_length=3)


def parse_blob_path(blob_path: str) -> tuple[str, str]:
    container, separator, name = blob_path.partition("/")
    if not separator or not container or not name:
        raise create_error(ErrorCode.INVALID_BLOB_PATH, blob_path=blob_path)
    return container, name
