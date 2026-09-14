import logging

from vectorizer.contracts.responses.base import ErrorResponse

from .error_specs import ERROR_SPECS, ErrorCode


logger = logging.getLogger(__name__)


class VectorizerError(ValueError):
    def __init__(self, code: ErrorCode, message: str):
        self.code = code
        self.message = message
        spec = ERROR_SPECS[code]
        self.status_code = spec.status_code
        super().__init__(message)

    def as_dict(self) -> dict[str, object]:
        return ErrorResponse(
            code=self.code.value,
            message=self.message,
            status=self.status_code,
        ).as_dict()


def create_error(code: ErrorCode, **parameters: str) -> VectorizerError:
    spec = ERROR_SPECS[code]
    message = spec.message_template.format(**parameters)
    logger.error("[ERROR] %s: %s", code.value, message)
    return VectorizerError(code, message)
