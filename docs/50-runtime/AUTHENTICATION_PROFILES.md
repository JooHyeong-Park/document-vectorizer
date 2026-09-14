# 인증 상세

이 문서는 Storage, PostgreSQL, Embedding Provider에 대한 인증 전략과 설정 프로필별
인증 조합을 정의한다. 인증 객체 생성은 infrastructure의 credential factory가 담당하며,
문서 처리 로직은 인증 방식과 credential 구현을 직접 다루지 않는다.

## 1. 대상별 지원 인증

### Blob Storage

지원 인증 방식:

- `account_key`: Storage account key로 인증
- `service_principal`: tenant ID, client ID, client secret으로 인증
- `managed_identity`: user-assigned Managed Identity client ID로 인증
- `azure_cli`: Azure CLI credential으로 인증

### PostgreSQL

지원 인증 방식:

- `password`: username과 password로 인증
- `managed_identity`: Managed Identity access token을 password로 사용

PostgreSQL Managed Identity 인증에서
`https://ossrdbms-aad.database.windows.net/.default`는 Azure Database for PostgreSQL
access token의 audience를 지정하는 값이다. 해당 URL로 직접 통신하는 endpoint가 아니다.

### Embedding Provider

OpenRouter는 API key 인증을 사용한다. Azure OpenAI는 다음 인증 방식을 지원한다.

- `api_key`
- `service_principal`
- `managed_identity`
- `azure_cli`

Azure OpenAI Managed Identity 인증의 token audience는
`https://cognitiveservices.azure.com/.default`다.

## 2. 설정 프로필별 전략

### `public`

- Blob Storage: `account_key`
- PostgreSQL: `password`
- Embedding Provider: `openrouter` + `api_key`

이 프로필은 로컬 공개 인프라와 OpenRouter API key 사용을 대상으로 한다.

### `private`

- Blob Storage: 설정된 authentication mode 사용
- PostgreSQL: `password` 또는 `managed_identity`
- Embedding Provider: `azure_openai` + 설정된 authentication mode 사용

`service_principal`을 선택하면 대상별 tenant ID, client ID, client secret이 필요하다.
내부망의 실제 credential 발급 경로와 endpoint 접근 가능 여부는 배포 환경에서 보장해야 한다.

### `azure`

- Blob Storage: `managed_identity`
- PostgreSQL: `password` 또는 `managed_identity`
- Embedding Provider: `azure_openai` + `managed_identity`

Azure App Service에 배포된 Web App과 Function App은 user-assigned Managed Identity를
사용한다. 따라서 Blob Storage와 Azure OpenAI profile에는 해당 identity의 client ID를
설정한다. System-assigned Managed Identity는 현재 지원하지 않는다.

## 3. 보안 및 네트워크 원칙

- Secret과 access token을 소스, 이미지, 로그에 포함하지 않는다.
- 인증 방식은 환경 이름이 아니라 `authentication_mode` 설정으로 선택한다.
- Managed Identity는 Azure 플랫폼의 token 발급 경로를 사용하며, 각 대상 서비스의
  Private Endpoint와 Private DNS 구성은 별도로 필요하다.
- Service Principal과 API key 방식은 해당 credential 발급 endpoint에 접근할 수 있어야 한다.
