from collections.abc import Callable

from fastapi import APIRouter
from fastapi.responses import JSONResponse

from vectorizer.contracts.constants import API_ROUTE_PREFIX, HttpApiPath
from vectorizer.contracts.errors import VectorizerError
from vectorizer.contracts.requests import DocumentsProcessRequest
from vectorizer.contracts.responses import HealthResponse
from vectorizer.service import BlobDocumentVectorizationService


def create_router(
    get_blob_document_vectorization_service: Callable[
        [], BlobDocumentVectorizationService
    ],
):
    router = APIRouter(prefix=API_ROUTE_PREFIX)

    @router.get(f"/{HttpApiPath.HEALTH}")
    async def health():
        return HealthResponse().as_dict()

    @router.post(f"/{HttpApiPath.DOCUMENTS_PROCESS}")
    async def process(request: DocumentsProcessRequest):
        try:
            return (
                get_blob_document_vectorization_service()
                .documents_process(request)
                .as_dict()
            )
        except VectorizerError as error:
            return JSONResponse(
                status_code=error.status_code,
                content=error.as_dict(),
            )

    return router
