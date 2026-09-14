import csv
import io

from vectorizer.service.documents.text_decoder import TextDecoder


class CsvDocumentExtractor:
    def __init__(self, text_decoder: TextDecoder | None = None) -> None:
        self.text_decoder = text_decoder or TextDecoder()

    def extract(self, content: bytes) -> str:
        rows = csv.reader(io.StringIO(self.text_decoder.decode(content)))
        return "\n".join(" | ".join(row) for row in rows)
