from dataclasses import dataclass


@dataclass(frozen=True)
class ErrorResponse:
    code: str
    message: str
    status: int

    def as_dict(self) -> dict[str, object]:
        return {
            "success": False,
            "error": {
                "code": self.code,
                "message": self.message,
                "status": self.status,
            },
        }


@dataclass(frozen=True)
class HealthResponse:
    status: str = "ok"

    def as_dict(self) -> dict[str, str]:
        return {"status": self.status}
