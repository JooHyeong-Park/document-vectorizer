from vectorizer.service.documents.models import StoredChunk


class DatabaseClient:
    def __init__(self, connection_factory):
        self.connection_factory = connection_factory

    def _open_connection(self):
        connection = self.connection_factory()
        from pgvector.psycopg import register_vector

        register_vector(connection)
        return connection

    def already_processed(self, container, name, etag, model):
        with self._open_connection() as connection, connection.cursor() as cursor:
            cursor.execute(
                "SELECT EXISTS (SELECT 1 FROM vectorizer_documents WHERE blob_container=%s AND blob_name=%s AND blob_etag=%s AND embedding_model=%s AND status='succeeded')",
                (container, name, etag, model),
            )
            return cursor.fetchone()[0]

    def mark_processing(self, container, name, etag, model):
        with self._open_connection() as connection, connection.cursor() as cursor:
            cursor.execute(
                "INSERT INTO vectorizer_processing (blob_container, blob_name, blob_etag, embedding_model, status, error) VALUES (%s,%s,%s,%s,'processing',NULL) ON CONFLICT (blob_container, blob_name, blob_etag, embedding_model) DO UPDATE SET status='processing', error=NULL, updated_at=now()",
                (container, name, etag, model),
            )
            connection.commit()

    def replace_document(self, container, name, etag, model, chunks):
        with self._open_connection() as connection, connection.cursor() as cursor:
            cursor.execute(
                "DELETE FROM vectorizer_documents WHERE blob_container=%s AND blob_name=%s",
                (container, name),
            )
            for chunk in chunks:
                cursor.execute(
                    "INSERT INTO vectorizer_documents (blob_container, blob_name, blob_etag, chunk_index, content, embedding, embedding_model, metadata, status) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,'succeeded')",
                    (
                        container,
                        name,
                        etag,
                        chunk.index,
                        chunk.content,
                        chunk.embedding,
                        model,
                        __import__("json").dumps(chunk.metadata),
                    ),
                )
            cursor.execute(
                "INSERT INTO vectorizer_processing (blob_container, blob_name, blob_etag, embedding_model, status, error) VALUES (%s,%s,%s,%s,'succeeded',NULL) ON CONFLICT (blob_container, blob_name, blob_etag, embedding_model) DO UPDATE SET status='succeeded', error=NULL, updated_at=now()",
                (container, name, etag, model),
            )
            connection.commit()

    def record_failure(self, container, name, etag, model, error):
        with self._open_connection() as connection, connection.cursor() as cursor:
            cursor.execute(
                "INSERT INTO vectorizer_processing (blob_container, blob_name, blob_etag, embedding_model, status, error) VALUES (%s,%s,%s,%s,'failed',%s) ON CONFLICT (blob_container, blob_name, blob_etag, embedding_model) DO UPDATE SET status='failed', error=EXCLUDED.error, updated_at=now()",
                (container, name, etag, model, error[:2000]),
            )
            connection.commit()
