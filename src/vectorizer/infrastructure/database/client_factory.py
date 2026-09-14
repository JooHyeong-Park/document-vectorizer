import psycopg

from vectorizer.infrastructure.database.authentication import (
    create_postgresql_credential,
)
from vectorizer.infrastructure.database.database_client import DatabaseClient


def create_database_client(settings) -> DatabaseClient:
    connection_options = {
        "host": settings.postgresql_host,
        "port": settings.postgresql_port,
        "dbname": settings.postgresql_database_name,
        "user": settings.postgresql_username,
        "sslmode": settings.postgresql_ssl_mode,
        "password": create_postgresql_credential(settings),
    }
    return DatabaseClient(lambda: psycopg.connect(**connection_options))
