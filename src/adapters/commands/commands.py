import json

from vectorizer.config import get_settings
from vectorizer.contracts.errors import VectorizerError
from vectorizer.contracts.requests import DocumentsProcessRequest
from vectorizer.service import create_blob_document_vectorization_service


def documents_process(payload: str) -> int:
    try:
        request = DocumentsProcessRequest.model_validate_json(payload)
        result = create_blob_document_vectorization_service(
            get_settings()
        ).documents_process(request)
        print(json.dumps(result.as_dict()))
        return 0
    except VectorizerError as error:
        print(json.dumps(error.as_dict()))
        return 2
