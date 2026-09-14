import tiktoken

from vectorizer.service.documents.models import TextChunk


class TextChunker:
    def __init__(self, size: int, overlap: int, model: str = "cl100k_base"):
        if size <= 0 or overlap < 0 or overlap >= size:
            raise ValueError(
                "chunk size must be positive and overlap must be smaller than size"
            )
        try:
            self.encoding = tiktoken.encoding_for_model(model)
        except KeyError:
            self.encoding = tiktoken.get_encoding("cl100k_base")
        self.size, self.overlap = size, overlap

    def split(self, text: str) -> list[TextChunk]:
        tokens = self.encoding.encode(text)
        result, start, index = [], 0, 0
        step = self.size - self.overlap
        while start < len(tokens):
            part = tokens[start : start + self.size]
            result.append(TextChunk(index, self.encoding.decode(part), len(part)))
            index += 1
            start += step
        return result
