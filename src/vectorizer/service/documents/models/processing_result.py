from dataclasses import dataclass


@dataclass(frozen=True)
class ProcessingResult:
    status: str
    container: str
    name: str
    etag: str
    chunks: int
