# 문서 체계

이 문서는 AI Agent 기반 개발을 위한 문서 목록과 문서의 역할을 정의한다.

## 문서 목록

### `10-requirements/`

- `SPEC.md` : 제품 기능, 범위 및 제약조건
- `AUTHENTICATION.md` : 인증 원칙 및 운영 인증 정책
- `CONFIGURATION.md` : 런타임 설정 원칙 및 설정 로딩 규칙
- `DEPENDENCIES.md` : Dependency 및 패키지 관리 정책
- `ENVIRONMENTS.md` : 소스 개발 및 애플리케이션 실행 환경 원칙

### `50-application/`

애플리케이션 구현 구조와 구성요소 상세를 정의한다.

### `50-data/`

데이터 구조, 저장 및 처리 상세를 정의한다.

### `50-dependencies/`

- `PYTHON_PACKAGING.md` : Dependency 정의 파일의 책임과 오프라인 패키징 절차
- `UPDATE_WHEELS.md` : Dependency 및 wheel 갱신 절차

### `50-runtime/`

환경별 실행, 설정 및 인증 상세를 정의한다.

### `60-ai/`

AI 기능 확장과 관련 구현 상세를 정의한다.

### `70-validation/`

테스트와 검증 기준을 정의한다.


## 문서 작성 원칙

- 동일한 규칙 또는 정보는 각 문서별로 중복 정의하지 않고 하나의 문서에서 단일 기준으로 관리한다.
- `10-requirements/`
  - 프로젝트의 목표, 요구사항, 정책, 환경 등의 기준 항목을 정의한다.
  - 변경 가능성이 높은 상세 내용등은, `10-requirements/` 에서 정의하지 말고 `50-` 이상 문서를 참조한다.
- `50-` 이상의 문서
  - 구현, 계약, 절차, 기술 선택 등 변경 가능성이 높은 상세 내용을 정의한다.
