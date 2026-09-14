from charset_normalizer import from_bytes


class TextDecoder:
    def decode(self, content: bytes) -> str:
        detected_text = from_bytes(content).best()
        return str(detected_text) if detected_text is not None else ""
