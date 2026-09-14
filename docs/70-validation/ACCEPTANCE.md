# Acceptance Criteria

## 1. 문서 처리

- [ ] Blob metadata와 ETag를 조회한다.
- [ ] Blob 내용을 다운로드한다.
- [ ] 지원 문서에서 텍스트를 추출한다.
- [ ] 설정된 Chunk 크기와 overlap으로 텍스트를 분할한다.
- [ ] 여러 Chunk를 설정된 batch 크기로 Embedding 요청한다.
- [ ] Provider 응답 순서를 Chunk 순서와 일치시킨다.
- [ ] vector dimension이 설정값과 다르면 처리를 실패시킨다.
- [ ] PostgreSQL pgvector에 Chunk와 Embedding을 저장한다.

## 2. Idempotency 및 처리 상태

- [ ] 동일 Blob, ETag, Embedding model을 다시 처리하면 성공 결과를 재생성하지 않는다.
- [ ] Blob ETag가 변경되면 변경된 문서를 처리한다.
- [ ] 처리 시작 상태를 기록한다.
- [ ] 처리 성공 상태를 기록한다.
- [ ] 처리 실패 상태와 오류 메시지를 기록한다.
- [ ] 성공한 새 버전 저장 시 기존 문서 Chunk를 최신 결과로 교체한다.

## 3. 실행 진입점

- [ ] Web App HTTP endpoint가 문서 처리 요청을 수신한다.
- [ ] Function App HTTP endpoint가 문서 처리 요청을 수신한다.
- [ ] Python command가 문서 처리 요청을 실행한다.
- [ ] Web App, Function App, Command가 문서 처리 로직을 중복 구현하지 않는다.
- [ ] 오류 응답이 `ErrorResponse` contract를 따른다.

## 4. 설정 및 인증

- [ ] 설정 profile 선택과 필수 설정 검증이 실행 시작 시 수행된다.
- [ ] Blob Storage 인증 방식이 설정으로 선택된다.
- [ ] PostgreSQL은 Password 또는 Managed Identity 인증을 사용한다.
- [ ] Embedding Provider와 인증 방식이 설정으로 선택된다.
- [ ] Secret, access token, password가 로그와 이미지에 포함되지 않는다.

## 5. Docker 이미지

- [ ] Web App 이미지가 `Dockerfile.web-app`으로 build된다.
- [ ] Function App 이미지가 `Dockerfile.function-app`으로 build된다.
- [ ] Python package가 대상 Linux 오프라인 설치 패키지에서 `--no-index`로 설치된다.
- [ ] Web App 이미지가 non-root user로 실행된다.
- [ ] Function App 이미지가 non-root user로 실행된다.
- [ ] runtime 이미지에 오프라인 설치 패키지와 Python cache가 남지 않는다.
- [ ] clean build 기준으로 이미지가 정상적으로 build된다.

## 6. 환경 연결

- [ ] Local 환경에서 Azurite Blob, Local PostgreSQL pgvector, OpenRouter를 사용한 전체 흐름이 동작한다.
- [ ] Azure App Service Environment에서 Function App이 기동한다.
- [ ] Azure App Service에서 FastAPI Web App이 기동한다.
- [ ] Azure Private Endpoint와 Private DNS 환경에서 Storage, PostgreSQL, Azure OpenAI에 연결한다.
