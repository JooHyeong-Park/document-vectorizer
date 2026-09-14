# 애플리케이션 설계

## 1. 소스 구조

```text
<>Repository>/
├── docs/                       # 설계, 요구사항, 실행 및 검증 문서
├── requirements/               # 런타임 및 개발 dependency 정의
├── infrastructure/             # 각 환경 /Infra 관련 스크립트 경로
├── src/
│   ├── adapters/               # HTTP 및 명령줄 실행 진입점
│   │   ├── azure_function_web/ # Azure Functions HTTP 요청 처리
│   │   ├── azure_web_app/      # Web App HTTP 요청 처리
│   │   └── commands/           # Python 명령줄 실행 처리
│   └── vectorizer/             # 문서 벡터화 비즈니스 구현
│       ├── config/             # 런타임 설정 및 프로필 선택
│       ├── contracts/          # 요청, 응답, 오류 및 HTTP 경로 계약
│       ├── infrastructure/     # Azure 등 각 Infra 연동 로직 구현
│       └── service/            # 문서 벡터화 처리 흐름
├── .dockerignore                # Container build 제외 규칙
├── .gitignore                   # Git 추적 제외 규칙
├── AGENTS.md                   # AI Agent 작업 지침
├── Dockerfile.function-app     # Function App 이미지 정의
├── Dockerfile.web-app          # Web App 이미지 정의
├── function_app.py             # Azure Functions host 진입점
├── host.json                   # Azure Functions host 설정
├── local.settings.json         # 로컬 Functions host 설정
├── pyproject.toml              # Python 프로젝트 설정
├── README.md                   # 프로젝트 안내
└── requirements.txt            # Azure Function App 필수 dependency manifest
```

`vectorizer/`는 문서 벡터화의 비즈니스 로직과 이를 지원하는 설정, 계약, 외부 시스템
연동을 구현한다. `adapters/`는 HTTP 요청 또는 명령줄 인자를 받아 `vectorizer/`의
문서 처리 기능을 호출하고 실행 방식에 맞는 결과를 반환한다.

## 2. 문서 벡터화 구현

### `config/`

환경변수를 읽고 선택된 설정 프로필을 검증한다. 설정은 외부 시스템 연결과 문서
처리에 필요한 값을 제공하며, 환경 이름에 따른 비즈니스 로직 분기를 포함하지 않는다.

### `contracts/`

HTTP와 명령줄 실행에서 공유하는 요청, 응답, 오류 및 HTTP API 경로를 정의한다. 오류는
`ERROR_SPECS`를 단일 기준으로 하며, 모든 실행 진입점은 동일한 오류 응답 계약을 사용한다.

### `service/`

문서 벡터화의 처리 순서를 조합하고 제어한다.

```text
Blob 조회 및 다운로드
-> 텍스트 추출
-> Chunk 생성
-> Embedding 생성
-> 처리 결과 저장
```

### `infrastructure/`

Storage, Embedding Provider, PostgreSQL 같은 외부 시스템에 대한 연결, 인증 및 작업을
구현한다. 문서 처리 흐름은 외부 SDK를 직접 호출하지 않고 이 계층을 통해 외부 시스템과
연동한다.

## 3. 실행 진입점

`azure_web_app/`과 `azure_function_web/`은 각각 Web App과 Function App의 HTTP 요청을
처리한다. `commands/`는 `python -m adapters.commands.commands_dispatcher`로 실행되는
명령줄 진입점이다. 세 진입점은 실행 방식만 다르며 문서 벡터화 로직을 중복 구현하지 않는다.

허용 책임:

- 입력 parsing 및 validation
- 문서 처리 기능 호출
- 실행 환경별 응답 또는 종료 상태 생성

금지 책임:

- 직접 Blob 처리
- 직접 Chunking 또는 Embedding API 호출
- 직접 데이터 저장소 처리
