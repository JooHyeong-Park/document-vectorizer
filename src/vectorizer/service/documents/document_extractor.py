from collections.abc import Callable
import re
from pathlib import Path

from vectorizer.service.documents.extractors import (
    CsvDocumentExtractor,
    DocxDocumentExtractor,
    PdfDocumentExtractor,
    PlainTextDocumentExtractor,
    PptxDocumentExtractor,
    XlsDocumentExtractor,
    XlsxDocumentExtractor,
)


class DocumentExtractor:
    def __init__(self) -> None:
        self._extractors: dict[str, Callable[[bytes], str]] = {
            ".txt": PlainTextDocumentExtractor().extract,
            ".csv": CsvDocumentExtractor().extract,
            ".pdf": PdfDocumentExtractor().extract,
            ".docx": DocxDocumentExtractor().extract,
            ".xlsx": XlsxDocumentExtractor().extract,
            ".xls": XlsDocumentExtractor().extract,
            ".pptx": PptxDocumentExtractor().extract,
        }

    def extract(self, content: bytes, filename: str) -> str:
        suffix = Path(filename).suffix.lower()
        extractor = self._extractors.get(suffix)
        if extractor is None:
            raise ValueError(f"unsupported document type: {suffix or '<none>'}")
        return self.normalize(extractor(content))

    @staticmethod
    def normalize(text: str) -> str:
        return re.sub(r"\n{3,}", "\n\n", re.sub(r"[ \t]+", " ", text)).strip()
