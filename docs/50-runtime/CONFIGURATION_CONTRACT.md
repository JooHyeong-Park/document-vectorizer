# 설정 Contract

이 문서는 애플리케이션이 읽는 환경변수와 값의 구조를 정의한다. 환경별 설정 예시는
두지 않으며, 설정 프로필별 인증 조합은 `AUTHENTICATION_PROFILES.md`에서 정의한다.

## 1. 설정 프로필

| 환경변수 | 타입 | 필수 | 허용값 | 설명 |
| --- | --- | --- | --- | --- |
| `VECTORIZE_SETTINGS_PROFILE` | string | 아니오 | `public`, `private`, `azure` | 로드할 설정 프로필. 기본값은 `azure` |

## 2. Blob Storage

`BLOB_STORAGES`는 이름별 Blob Storage 설정을 담은 객체다. `DEFAULT` 항목은 필수이며,
`DEFAULT_BLOB_STORAGE`가 없으면 `DEFAULT`가 선택된다.

```json
{
  "DEFAULT": {
    "endpoint": "",
    "authentication_mode": "account_key",
    "account_key": "",
    "azure_tenant_id": "",
    "azure_client_id": "",
    "azure_client_secret": ""
  }
}
```

| 환경변수 또는 속성 | 타입 | 필수 | 허용값 및 설명 |
| --- | --- | --- | --- |
| `BLOB_STORAGES` | object | 예 | 하나 이상의 Storage 설정. 각 항목의 키는 Storage 이름 |
| `BLOB_STORAGES__<NAME>__ENDPOINT` | string | 예 | Storage endpoint |
| `BLOB_STORAGES__<NAME>__AUTHENTICATION_MODE` | string | 예 | `account_key`, `service_principal`, `managed_identity`, `azure_cli` |
| `BLOB_STORAGES__<NAME>__ACCOUNT_KEY` | string | 인증 방식에 따라 | `account_key` 인증에 사용 |
| `BLOB_STORAGES__<NAME>__AZURE_TENANT_ID` | string | 인증 방식에 따라 | `service_principal` 인증에 사용 |
| `BLOB_STORAGES__<NAME>__AZURE_CLIENT_ID` | string | 인증 방식에 따라 | Service Principal 또는 Managed Identity client ID |
| `BLOB_STORAGES__<NAME>__AZURE_CLIENT_SECRET` | string | 인증 방식에 따라 | `service_principal` 인증에 사용 |
| `DEFAULT_BLOB_STORAGE` | string | 아니오 | 기본 Storage 이름. 기본값은 `DEFAULT` |

## 3. PostgreSQL

| 환경변수 | 타입 | 필수 | 기본값 또는 허용값 |
| --- | --- | --- | --- |
| `POSTGRESQL_HOST` | string | 예 | PostgreSQL host |
| `POSTGRESQL_PORT` | integer | 아니오 | `5432` |
| `POSTGRESQL_DATABASE_NAME` | string | 예 | Database 이름 |
| `POSTGRESQL_USERNAME` | string | 예 | Database 사용자 |
| `POSTGRESQL_AUTHENTICATION_MODE` | string | 아니오 | `password`, `managed_identity`. 기본값은 `password` |
| `POSTGRESQL_SSL_MODE` | string | 아니오 | 기본값은 `require`. `public` 프로필은 `disable` |
| `POSTGRESQL_PASSWORD` | string | 인증 방식에 따라 | `password` 인증에 사용 |
| `POSTGRESQL_AZURE_CLIENT_ID` | string | 인증 방식에 따라 | `managed_identity` 인증에 사용 |

## 4. Embedding Profile

`EMBEDDING_PROFILES`는 이름별 Embedding 설정을 담은 객체다. `DEFAULT` 항목은 필수이며,
`DEFAULT_EMBEDDING_PROFILE`이 없으면 `DEFAULT`가 선택된다.

```json
{
  "DEFAULT": {
    "provider": "openrouter",
    "endpoint": "https://openrouter.ai/api/v1",
    "authentication_mode": "api_key",
    "model": "",
    "dimensions": 1536,
    "batch_size": 32,
    "document_chunk_size": 1000,
    "document_chunk_overlap": 100,
    "openrouter_api_key": "",
    "azure_openai_api_key": "",
    "azure_tenant_id": "",
    "azure_client_id": "",
    "azure_client_secret": ""
  }
}
```

| 환경변수 또는 속성 | 타입 | 필수 | 허용값 및 설명 |
| --- | --- | --- | --- |
| `EMBEDDING_PROFILES` | object | 예 | 하나 이상의 Embedding profile |
| `EMBEDDING_PROFILES__<NAME>__PROVIDER` | string | 예 | `openrouter`, `azure_openai` |
| `EMBEDDING_PROFILES__<NAME>__ENDPOINT` | string | 예 | Provider endpoint |
| `EMBEDDING_PROFILES__<NAME>__AUTHENTICATION_MODE` | string | 예 | `api_key`, `service_principal`, `managed_identity`, `azure_cli` |
| `EMBEDDING_PROFILES__<NAME>__MODEL` | string | 예 | Provider model 또는 Azure OpenAI deployment 이름 |
| `EMBEDDING_PROFILES__<NAME>__DIMENSIONS` | integer | 예 | `0`보다 큰 vector dimension |
| `EMBEDDING_PROFILES__<NAME>__BATCH_SIZE` | integer | 아니오 | `1` 이상 `2048` 이하. 기본값은 `32` |
| `EMBEDDING_PROFILES__<NAME>__DOCUMENT_CHUNK_SIZE` | integer | 예 | `0`보다 큰 chunk 크기 |
| `EMBEDDING_PROFILES__<NAME>__DOCUMENT_CHUNK_OVERLAP` | integer | 예 | `0` 이상이며 chunk 크기보다 작아야 함 |
| `EMBEDDING_PROFILES__<NAME>__OPENROUTER_API_KEY` | secret | Provider에 따라 | OpenRouter API key |
| `EMBEDDING_PROFILES__<NAME>__AZURE_OPENAI_API_KEY` | secret | 인증 방식에 따라 | Azure OpenAI API key |
| `EMBEDDING_PROFILES__<NAME>__AZURE_TENANT_ID` | string | 인증 방식에 따라 | Service Principal tenant ID |
| `EMBEDDING_PROFILES__<NAME>__AZURE_CLIENT_ID` | string | 인증 방식에 따라 | Service Principal 또는 Managed Identity client ID |
| `EMBEDDING_PROFILES__<NAME>__AZURE_CLIENT_SECRET` | secret | 인증 방식에 따라 | Service Principal client secret |
| `DEFAULT_EMBEDDING_PROFILE` | string | 아니오 | 기본 profile 이름. 기본값은 `DEFAULT` |

## 5. 문서 처리

| 환경변수 | 타입 | 필수 | 기본값 또는 설명 |
| --- | --- | --- | --- |
| `MAX_DOCUMENT_SIZE_MB` | integer | 아니오 | 기본값 `50` |
| `PROCESSING_TIMEOUT_SECONDS` | integer | 아니오 | 기본값 `300` |

## 6. 설정 적용 규칙

- 환경변수 중첩 구분자는 `__`다.
- 설정 프로필은 `VECTORIZE_SETTINGS_PROFILE`로 선택한다.
- 필수값과 허용값 검증은 애플리케이션 시작 시 수행한다.
- Secret은 환경변수, Key Vault reference 또는 실행 환경이 제공하는 secret source로 주입한다.
- 실제 Secret과 환경별 설정 파일은 저장소에 포함하지 않는다.
