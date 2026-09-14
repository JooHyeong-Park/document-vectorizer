from dataclasses import dataclass


@dataclass(frozen=True)
class BlobDocument:
    container: str
    name: str
    etag: str
    metadata: dict[str, str]
    content: bytes
