from vectorizer.service.documents.models import ProcessingResult, StoredChunk


class BlobDocumentVectorizationService:
    def __init__(
        self,
        storage,
        extractor,
        chunker,
        embeddings,
        repository,
        max_document_size_mb=50,
    ):
        self.storage, self.extractor, self.chunker = storage, extractor, chunker
        self.embeddings, self.repository = embeddings, repository
        self.max_bytes = max_document_size_mb * 1024 * 1024

    def process(self, container: str, name: str) -> ProcessingResult:
        blob = self.storage.fetch(container, name)
        if len(blob.content) > self.max_bytes:
            raise ValueError("document exceeds MAX_DOCUMENT_SIZE_MB")
        if self.repository.already_processed(
            blob.container, blob.name, blob.etag, self.embeddings.model
        ):
            return ProcessingResult("skipped", blob.container, blob.name, blob.etag, 0)
        try:
            self.repository.mark_processing(
                blob.container, blob.name, blob.etag, self.embeddings.model
            )
            text = self.extractor.extract(blob.content, blob.name)
            chunks = self.chunker.split(text)
            if not chunks:
                raise ValueError("document does not contain extractable text")
            vectors = self.embeddings.embed([chunk.content for chunk in chunks])
            if len(vectors) != len(chunks):
                raise ValueError("embedding count does not match chunk count")
            self.repository.replace_document(
                blob.container,
                blob.name,
                blob.etag,
                self.embeddings.model,
                [
                    StoredChunk(chunk.index, chunk.content, vector, blob.metadata)
                    for chunk, vector in zip(chunks, vectors)
                ],
            )
        except Exception as exc:
            record_failure = getattr(self.repository, "record_failure", None)
            if record_failure is not None:
                try:
                    record_failure(
                        blob.container,
                        blob.name,
                        blob.etag,
                        self.embeddings.model,
                        str(exc),
                    )
                except Exception:
                    pass
            raise
        return ProcessingResult(
            "processed", blob.container, blob.name, blob.etag, len(chunks)
        )

    def documents_process(
        self, request: "DocumentsProcessRequest"
    ) -> "DocumentsProcessResponse":
        from vectorizer.contracts.requests import parse_blob_path
        from vectorizer.contracts.responses import DocumentsProcessResponse

        return DocumentsProcessResponse.from_result(
            self.process(*parse_blob_path(request.blob_path))
        )


def create_blob_document_vectorization_service(
    settings,
    storage_name: str | None = None,
    embedding_profile_name: str | None = None,
):
    from vectorizer.contracts.errors import ErrorCode, create_error
    from vectorizer.service.documents import DocumentExtractor, TextChunker
    from vectorizer.infrastructure.embedding import create_embedding_client
    from vectorizer.infrastructure.storage import (
        StorageBlobClient,
        create_storage_account_client,
    )
    from vectorizer.infrastructure.database import create_database_client

    storage_name = storage_name or settings.default_blob_storage
    embedding_profile_name = (
        embedding_profile_name or settings.default_embedding_profile
    )
    profile_key = next(
        (
            name
            for name in settings.embedding_profiles
            if name.casefold() == embedding_profile_name.casefold()
        ),
        None,
    )
    if profile_key is None:
        raise create_error(
            ErrorCode.EMBEDDING_PROFILE_NOT_FOUND,
            name=embedding_profile_name,
        )
    embedding_profile = settings.embedding_profiles[profile_key]
    return BlobDocumentVectorizationService(
        StorageBlobClient(create_storage_account_client(settings, storage_name)),
        DocumentExtractor(),
        TextChunker(
            embedding_profile.document_chunk_size,
            embedding_profile.document_chunk_overlap,
            embedding_profile.model,
        ),
        create_embedding_client(settings, profile_key),
        create_database_client(settings),
        settings.max_document_size_mb,
    )
