import json
from collections.abc import Callable

try:
    import azure.functions as func
except ImportError:
    func = None

from vectorizer.contracts.constants import HttpApiPath
from vectorizer.contracts.errors import VectorizerError
from vectorizer.contracts.requests import DocumentsProcessRequest
from vectorizer.contracts.responses import HealthResponse
from vectorizer.service import BlobDocumentVectorizationService


def create_blueprint(
    get_blob_document_vectorization_service: Callable[
        [], BlobDocumentVectorizationService
    ],
):
    if func is None:
        return None

    blueprint = func.Blueprint()

    @blueprint.route(
        route=HttpApiPath.HEALTH,
        methods=["GET"],
        auth_level=func.AuthLevel.ANONYMOUS,
    )
    def health(req: func.HttpRequest) -> func.HttpResponse:
        return func.HttpResponse(
            json.dumps(HealthResponse().as_dict()),
            status_code=200,
            mimetype="application/json",
        )

    @blueprint.route(
        route=HttpApiPath.DOCUMENTS_PROCESS,
        methods=["POST"],
        auth_level=func.AuthLevel.ANONYMOUS,
    )
    def process_document(req: func.HttpRequest) -> func.HttpResponse:
        try:
            payload = DocumentsProcessRequest.model_validate(req.get_json())
            result = get_blob_document_vectorization_service().documents_process(
                payload
            )
            return func.HttpResponse(
                json.dumps(result.as_dict()),
                status_code=200,
                mimetype="application/json",
            )
        except VectorizerError as error:
            return func.HttpResponse(
                json.dumps(error.as_dict()),
                status_code=error.status_code,
                mimetype="application/json",
            )

    return blueprint
