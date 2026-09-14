from dataclasses import dataclass


@dataclass(frozen=True)
class StoredChunk:
    index: int
    content: str
    embedding: list[float]
    metadata: dict[str, str]
