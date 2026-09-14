from azure.identity import (
    DefaultAzureCredential,
)

from vectorizer.config.settings.settings_common import PostgreSQLAuthenticationMode


def create_postgresql_credential(settings):
    match settings.postgresql_authentication_mode:
        case PostgreSQLAuthenticationMode.PASSWORD:
            return settings.postgresql_password
        case PostgreSQLAuthenticationMode.MANAGED_IDENTITY:
            credential = DefaultAzureCredential(
                managed_identity_client_id=settings.postgresql_azure_client_id
            )
            return lambda: (
                # "https://ossrdbms-aad.database.windows.net/.default" is the OAuth scope
                # used to request an Azure AD access token for Azure Database for PostgreSQL.
                # It identifies the token audience; it is not a network endpoint.
                credential.get_token(
                    "https://ossrdbms-aad.database.windows.net/.default"
                ).token
            )
        case _:
            raise ValueError(
                f"[ERROR] unsupported PostgreSQL authentication mode '{settings.postgresql_authentication_mode}'"
            )
