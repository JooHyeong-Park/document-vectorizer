from threading import Lock  # Protects one-time service creation per process.

from vectorizer.config import get_settings
from vectorizer.service import (
    BlobDocumentVectorizationService,
    create_blob_document_vectorization_service,
)


class ApplicationContext:
    """Owns application-scoped services and initializes them on first use."""

    # Holds application-scoped services shared by the Web App or Function App.
    def __init__(
        self,
        blob_document_vectorization_service: BlobDocumentVectorizationService
        | None = None,
    ):
        # An injected service keeps adapter tests independent from runtime settings.
        self._blob_document_vectorization_service = blob_document_vectorization_service
        # Prevents concurrent requests from creating multiple service instances.
        self._blob_document_vectorization_service_lock = Lock()

    def _create_blob_document_vectorization_service(
        self,
    ) -> BlobDocumentVectorizationService:
        # Settings validation and external client construction happen here.
        self._blob_document_vectorization_service = (
            create_blob_document_vectorization_service(get_settings())
        )
        return self._blob_document_vectorization_service

    def initialize(self) -> BlobDocumentVectorizationService | None:
        # This is the common startup hook called by each platform adapter.
        # Azure App Service 최초 배포를 위한 임시 우회 처리입니다.
        #
        # 정상 동작에서는 애플리케이션 시작 시 모든 필수 설정을 검증하고
        # 공용 BlobDocumentVectorizationService를 생성합니다. 현재 배포 환경에는
        # Blob Storage, PostgreSQL, Embedding Profile 등 애플리케이션 전용 설정이
        # 아직 없으므로 이 동작을 임시로 비활성화합니다.
        #
        # 이 줄이 주석 처리된 동안에는 위 설정 없이도 health endpoint가 기동합니다.
        # 문서 처리 요청은 get_blob_document_vectorization_service()를 호출하므로
        # 처리 전에 동일한 설정 검증이 수행됩니다. Azure에 필수 애플리케이션 설정을
        # 구성한 후에는 다음 줄의 주석을 해제하여 시작 시 검증을 복원해야 합니다.

        # return self.get_blob_document_vectorization_service()
        return self._blob_document_vectorization_service

    def get_blob_document_vectorization_service(
        self,
    ) -> BlobDocumentVectorizationService:
        # Defer validation and service construction until a business request.
        if self._blob_document_vectorization_service is None:
            with self._blob_document_vectorization_service_lock:
                # Check again after acquiring the lock to avoid duplicate creation.
                if self._blob_document_vectorization_service is None:
                    return self._create_blob_document_vectorization_service()
        return self._blob_document_vectorization_service
