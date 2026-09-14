import io


class PdfDocumentExtractor:
    def extract(self, content: bytes) -> str:
        from pypdf import PdfReader

        return "\n".join(
            page.extract_text() or "" for page in PdfReader(io.BytesIO(content)).pages
        )
