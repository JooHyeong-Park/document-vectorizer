"""Azure Function App Only :: host entry point."""

import sys
from pathlib import Path

# Azure Functions loads function_app.py from the function app root (/home/site/wwwroot),
# while the application modules are maintained under `src``.
# Add `src`` to the Python module search path before importing the application.
sys.path.insert(0, str(Path(__file__).resolve().parent / "src"))

# The host entry point is delegated to function_trigger_app.
from adapters.azure_function_web.function_trigger_app import app

__all__ = ["app"]
