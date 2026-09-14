from contextlib import asynccontextmanager
import os

from fastapi import FastAPI

from adapters.azure_web_app.routes import create_router
from vectorizer.app import ApplicationContext
from vectorizer.contracts.constants import APPLICATION_TITLE


def create_app(blob_document_vectorization_service=None) -> FastAPI:
    application_context = ApplicationContext(blob_document_vectorization_service)

    @asynccontextmanager
    async def lifespan(_app):
        application_context.initialize()
        yield

    app = FastAPI(title=APPLICATION_TITLE, lifespan=lifespan)
    app.include_router(
        create_router(application_context.get_blob_document_vectorization_service)
    )

    return app


app = create_app()


def main() -> None:
    import uvicorn

    uvicorn.run(
        app,
        host=os.getenv("HOST", "0.0.0.0"),
        port=int(os.getenv("WEBSITES_PORT", "8080")),
    )


if __name__ == "__main__":
    main()
