"""Thin Azure Functions adapter for the document vectorization service."""

from adapters.azure_function_web.routes import create_blueprint
from vectorizer.app import ApplicationContext

try:
    import azure.functions as func
except ImportError:  # permits core-only local tests
    func = None

if func is not None:
    application_context = ApplicationContext()
    application_context.initialize()
    app = func.FunctionApp()
    app.register_functions(
        create_blueprint(application_context.get_blob_document_vectorization_service)
    )
else:
    app = None
