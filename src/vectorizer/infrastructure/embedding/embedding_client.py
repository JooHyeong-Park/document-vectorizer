class EmbeddingClient:
    def __init__(self, client, model: str, dimensions: int, batch_size: int = 32):
        self.client, self.model, self.dimensions, self.batch_size = (
            client,
            model,
            dimensions,
            batch_size,
        )

    def embed(self, texts: list[str]) -> list[list[float]]:
        vectors = []
        for start in range(0, len(texts), self.batch_size):
            response = self.client.embeddings.create(
                model=self.model,
                input=texts[start : start + self.batch_size],
                dimensions=self.dimensions,
            )
            ordered = sorted(response.data, key=lambda item: item.index)
            batch = [list(item.embedding) for item in ordered]
            if any(len(vector) != self.dimensions for vector in batch):
                raise ValueError(
                    f"embedding provider returned a vector with dimension other than {self.dimensions}"
                )
            vectors.extend(batch)
        return vectors
