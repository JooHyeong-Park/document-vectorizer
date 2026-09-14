# Python Dependency 및 패키징

이 문서는 Python dependency 정의 파일의 책임과 오프라인 패키징 규칙을 정의한다.
상위 정책은 `docs/10-requirements/DEPENDENCIES.md`를 따른다.

## 1. Dependency 정의 파일

설치할 dependency의 단일 기준은 문서가 아니라 다음 dependency 정의 파일이다.

| 파일 | 책임 |
| --- | --- |
| `requirements/common_python_runtime.in` | 모든 애플리케이션 실행 대상이 공유하는 runtime dependency 정의 |
| `requirements/web_app_python_runtime.in` | Web App runtime dependency의 설치 진입점 |
| `requirements/development_python_tools.in` | 개발 및 검증에만 사용하는 dependency 정의 |
| `requirements.txt` | Azure Function App runtime dependency의 설치 진입점 |

소스 루트의 `requirements.txt`는 Azure Functions가 dependency manifest로 요구하는
필수 파일이다. 파일 이름을 변경하거나 `requirements/` 디렉터리로 이동하지 않는다.
Function App 이미지도 이 파일을 설치 진입점으로 사용한다.

공통 runtime dependency는 `common_python_runtime.in`에만 정의하고 각 실행 대상의
진입 파일에서 포함한다. 특정 실행 대상이나 개발 환경에서만 필요한 dependency는 공통
파일에 추가하지 않는다.

## 2. 오프라인 패키지

오프라인 설치 파일은 `requirements/wheels/` 아래에서 용도와 대상 플랫폼별로 분리한다.

- `runtimes/`는 애플리케이션 실행에 필요한 wheel을 보관한다.
- `development/`는 개발 및 검증에 필요한 wheel을 보관한다.
- requirements 파일은 설치 대상을 정의하고 wheel 디렉터리는 설치 파일만 제공한다.
- 설치 과정에서 public package registry로 fallback하지 않는다.
- Runtime dependency 설치에 source distribution이나 외부 build tool을 요구하지 않는다.

## 3. 실행 대상별 설치

- Web App은 `requirements/web_app_python_runtime.in`을 사용한다.
- Function App은 소스 루트의 `requirements.txt`를 사용한다.
- Docker 이미지는 대상 runtime wheel 디렉터리만 사용하여 dependency를 오프라인으로 설치한다.
- Runtime dependency를 변경한 이미지는 clean build로 검증한다.

## 4. Dependency 변경

Dependency와 wheel 갱신 절차는 `UPDATE_WHEELS.md`를 따른다.
