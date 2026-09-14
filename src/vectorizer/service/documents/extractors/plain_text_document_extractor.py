from vectorizer.service.documents.text_decoder import TextDecoder


class PlainTextDocumentExtractor:
    def __init__(self, text_decoder: TextDecoder | None = None) -> None:
        self.text_decoder = text_decoder or TextDecoder()

    def extract(self, content: bytes) -> str:
        return self.text_decoder.decode(content)
