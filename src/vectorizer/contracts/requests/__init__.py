"""Shared request contracts for core services and adapters."""

from .documents_process import DocumentsProcessRequest, parse_blob_path

__all__ = ["DocumentsProcessRequest", "parse_blob_path"]
