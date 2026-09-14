# 실행 환경 정의

프로젝트는 Local 개발, 내부망 통합 검증 및 Public/Private Azure 배포 환경을 지원한다.

- 동일 소스를 각 환경에서 사용한다.

## 1. PUBLIC-WSL2

Public Internet 접속, AI Agent 기반 개발이 가능한 Local 개발 환경

```text
OS              WSL2 Linux
Python          3.13
Container       Rootless Podman
```

```text
Azure Blob        -> Azurite 으로 대체
Azure PostgreSQL  -> Local PostgreSQL + pgvector container 으로 대체
Azure OpenAI      -> OpenAI API 호환 OpenRouter
```

- OpenRouter 는 `openai/text-embedding-3-small` 등 openai-compatiable Model 등 제공한다.
- Azure OpenAI 와 OpenRouter 간 Provider 를 변경해도 Embedding 입력·응답의 공통 계약은 변경하지 않아야 한다.
- 위 항목은 Local 개발 환경의 실행 설정으로 사용하며, Azure 환경의 Provider 설정과 분리한다.

## 2. PRIVATE-LOCAL

Internet 접속 불가/Azure Private Endpoint 접속 가능한 부 사설망 개발 환경

- 저장소 소스를 Python 3.13 으로 직접 실행한다.
- Web App 은 FastAPI 기반 Python process 로 직접 기동 가능해야 한다.
- 공통 Core 검증은 `src/adapters/commands/common_core_integration_runner.py`를 통해 수행한다.

```text
OS              Windows x86_64
Python          3.13
Podman/Docker   없음 -> Image 빌드/실행 불가
```


```text
Blob        -> 실제 Azure Blob Storage Private Endpoint
Database    -> 실제 Azure PostgreSQL Private Endpoint
AI          -> 실제 Azure OpenAI Private Endpoint
```

## 3. AZURE-PRIVATE-ASE

Azure App Service Environment (ASE) 기반 실제 Azure NP/운영 배포 환경

- Azure 운영 환경 배포 시 운영 이미지를 다시 빌드하지 않고 Azure NP 환경에서 검증된 이미지를 운영 환경에 배포한다.

```text
Web App       -> python:3.13-slim 기반 Container-based Azure Web-app,
Function App  -> Azure Functions Python 3.13 공식 이미지 기반 Container-based Azure Function App,
Blob          -> Azure Blob Storage / Private Endpoint
Database      -> Azure PostgreSQL / Private Endpoint
AI            -> Azure OpenAI / Private Endpoint
```

## 4. AZURE-PUBLIC-APP-SERVICE

Public Internet 접속이 가능한 Azure App Service 기반 배포 환경

```text
Web App       -> python:3.13-slim 기반 Container-based Azure Web App
Function App  -> Azure Functions Python 3.13 공식 이미지 기반 Container-based Azure Function App
Blob          -> Azure Blob Storage
Database      -> Azure PostgreSQL
AI            -> Azure OpenAI
```
