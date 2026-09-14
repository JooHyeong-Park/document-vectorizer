from azure.storage.blob import BlobServiceClient

from vectorizer.service.documents.models import BlobDocument


class StorageBlobClient:
    def __init__(self, client: BlobServiceClient):
        self._client = client

    def fetch(self, container: str, name: str) -> BlobDocument:
        container_client = self._client.get_container_client(container)
        blob = container_client.get_blob_client(name)
        properties = blob.get_blob_properties()
        return BlobDocument(
            container_client.container_name,
            name,
            properties.etag,
            dict(properties.metadata or {}),
            blob.download_blob().readall(),
        )
