from dataclasses import dataclass

from vectorizer.service.documents.models import ProcessingResult


@dataclass(frozen=True)
class DocumentsProcessResponse:
    status: str
    container: str
    name: str
    etag: str
    chunks: int

    def as_dict(self) -> dict[str, object]:
        return {
            "status": self.status,
            "container": self.container,
            "name": self.name,
            "etag": self.etag,
            "chunks": self.chunks,
        }

    @classmethod
    def from_result(cls, result: ProcessingResult) -> "DocumentsProcessResponse":
        return cls(
            result.status,
            result.container,
            result.name,
            result.etag,
            result.chunks,
        )
