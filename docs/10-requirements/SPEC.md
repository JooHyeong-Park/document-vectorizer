# 기능 요구사항

이 문서는 제품 기능, 범위 및 기능 제약조건을 정의한다.

## 1. 목표

Azure Blob Storage 의 문서를 읽어 다음 파이프라인을 수행한다.

```text
Blob 조회
-> 문서 다운로드
-> 텍스트 추출
-> Chunking
-> Embedding API 호출
-> PostgreSQL pgvector 저장
```

해당 애플리케이션은 Azure App Service Environment (ASE) 에 Function App 또는 Web App 으로 배포한다.


## 2. 필수 기능

### 2.1 Blob 처리

- 지정된 Storage Endpoint, Container, Blob Name 을 기준으로 Blob 을 조회한다.
- Blob metadata 와 ETag 를 조회할 수 있어야 한다.
- Blob 내용을 다운로드하여 문서 처리 계층으로 전달한다.

### 2.2 문서 추출

- Blob 에서 내려받은 파일에서 텍스트를 추출한다.

### 2.3 Chunking

- 추출된 텍스트를 Embedding 입력 단위로 분리한다.
- Chunk 크기와 overlap 은 런타임 설정으로 받는다.

### 2.4 Embedding

- 각 Chunk 에 대한 Embedding vector 를 생성한다.
- 서로 다른 모델의 vector 를 동일 데이터 집합에서 무분별하게 혼합하지 않는다.

지원 Provider:

- Azure OpenAI 및 OpenAI 호환 OpenRouter 를 Embedding Provider 로 사용한다.

### 2.5 처리 결과 저장

- 문서별 Chunk, Embedding, 원본 추적 정보 및 처리 상태를 저장한다.
- 저장 및 재처리의 데이터 규칙은 `docs/50-data/DATA_MODEL.md`에서 정의한다.

### 2.6 Idempotency 및 재처리

- 동일한 Blob + ETag 가 이미 성공적으로 처리된 경우 중복 Chunk/Vector 를 생성하지 않는다.
- Blob 의 ETag 가 변경된 경우 변경된 문서로 판단한다.
- 처리 결과의 성공 상태와 실패 상태를 구분한다.

## 3. AI 기능 범위

AI 기능 범위는 Embedding 을 기본으로 한다.
추가 기능 구현 및 계약 상세는 `docs/60-ai/`에서 정의한다.
