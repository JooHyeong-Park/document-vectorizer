# Dependency 및 Wheel 갱신

이 문서는 dependency를 추가, 제거 또는 변경할 때 wheel을 갱신하는 절차를 정의한다.
Dependency 정의 파일의 역할과 wheel 저장 원칙은 `PYTHON_PACKAGING.md`를 따른다.

## 1. 버전 선택

Dependency 정의 파일은 버전을 지정하지 않는다. `pip download`는 실행 시점에 package
registry에서 설치 가능한 호환 버전을 선택하므로, 같은 명령도 실행 시점에 따라 다른
버전의 wheel을 내려받을 수 있다.

저장소에 반영한 wheel 집합이 해당 시점의 설치 기준이다. 선택된 버전을 문서나
requirements 파일에 기록하지 않는다.

## 2. Python 및 pip 확인

PUBLIC-WSL2 에서는 `install-portable-python-3-13-for-wsl2.sh` 를 먼저 실행한다.
이 스크립트는 runtime 을 저장소 밖에 설치하며 전역 Python 환경을 변경하지 않는다.

설치 후에는 로컬 실행 스크립트와 같은 방식으로 실행 파일을 확인하고 `PATH`를 설정한다.

```bash
set -Eeuo pipefail

PYTHON_RUNTIME_ROOT="${HOME}/runtimes/python-3.13.15"
PYTHON_RUNTIME_BIN="${PYTHON_RUNTIME_ROOT}/bin"

if [[ ! -x "${PYTHON_RUNTIME_BIN}/python3.13" ]]; then
  printf '[ERROR] Python executable %s is not available\n' \
    "${PYTHON_RUNTIME_BIN}/python3.13" >&2
  exit 1
fi

export PATH="${PYTHON_RUNTIME_BIN}:${PATH}"
PYTHON="python"

command -v "${PYTHON}"
"${PYTHON}" --version
"${PYTHON}" -c 'import sys, sysconfig; print(sys.implementation.name, sysconfig.get_config_var("SOABI"))'
"${PYTHON}" -m pip --version
```

출력된 Python 버전과 ABI가 갱신할 wheel 디렉터리의 대상과 일치하지 않으면 다운로드를
진행하지 않는다. pip는 별도 `pip` 명령이 아니라 확인한 Python의
`"${PYTHON}" -m pip`로만 실행한다.

PUBLIC-WSL2 가 아닌 환경에서는 해당 환경의 Python 준비 절차를 사용하되, 이후 단계에서
사용할 `PYTHON`을 지정하고 같은 검증을 수행한다.

## 3. 다운로드 준비

wheel 다운로드는 package registry에 접근할 수 있는 환경에서 저장소 루트를 현재
디렉터리로 두고 실행한다. 대상 OS, architecture 및 Python ABI와 일치하는 Python
환경을 사용한다.

기존 wheel 디렉터리에 바로 다운로드하면 이전 버전과 새 버전이 함께 남을 수 있다.
항상 빈 staging 디렉터리에 다운로드하고 검증이 끝난 결과로 대상 디렉터리 전체를
교체한다.

Linux x86_64와 CPython 3.13용 staging 디렉터리는 다음과 같이 준비한다.

```bash
STAGING_ROOT="$(mktemp -d)"
RUNTIME_WHEELS="${STAGING_ROOT}/runtimes/linux-x86_64-cp313"

mkdir -p "${RUNTIME_WHEELS}"
```

다른 실행 대상을 갱신할 때는 디렉터리 이름과 다운로드 환경을 해당 OS, architecture 및
Python ABI에 맞춘다.

## 4. Runtime Wheel 다운로드

Function App과 Web App의 dependency 및 모든 전이 dependency를 하나의 runtime
wheel 집합으로 내려받는다.

```bash
"${PYTHON}" -m pip download \
  --only-binary=:all: \
  --dest "${RUNTIME_WHEELS}" \
  --requirement requirements.txt \
  --requirement requirements/web_app_python_runtime.in
```

`--only-binary=:all:` 조건으로 설치 가능한 패키지가 없으면 실패로 처리한다. source
distribution을 대신 내려받거나 `--no-deps`로 전이 dependency를 제외하지 않는다.

## 5. 격리된 오프라인 설치 검증

임시 virtual environment 를 만들고 다운로드한 wheel 만으로 실제 설치한다.

```bash
VERIFICATION_VENV="${STAGING_ROOT}/verification-venv"
VERIFICATION_PYTHON="${VERIFICATION_VENV}/bin/python"

"${PYTHON}" -m venv "${VERIFICATION_VENV}"
"${VERIFICATION_PYTHON}" -m pip install \
  --no-index \
  --find-links "${RUNTIME_WHEELS}" \
  --requirement requirements.txt \
  --requirement requirements/web_app_python_runtime.in

"${VERIFICATION_PYTHON}" -m pip check
```

설치 또는 `pip check` 가 실패하면 소스 wheel 을 변경하지 않는다.

## 6. 소스 Wheel 비교 및 교체

검증된 staging wheel 과 소스 wheel 의 변경 대상을 먼저 확인한다.

```bash
SOURCE_RUNTIME_WHEELS="requirements/wheels/runtimes/linux-x86_64-cp313"

test -d "${SOURCE_RUNTIME_WHEELS}"

diff --recursive --brief \
  "${SOURCE_RUNTIME_WHEELS}" \
  "${RUNTIME_WHEELS}" || [[ $? -eq 1 ]]
```

출력된 추가, 변경 및 삭제 파일이 예상과 일치하면 소스 wheel 디렉터리를 교체한다.

```bash
rm --force "${SOURCE_RUNTIME_WHEELS}"/*.whl
cp --archive "${RUNTIME_WHEELS}/." "${SOURCE_RUNTIME_WHEELS}/"

git status --short -- "${SOURCE_RUNTIME_WHEELS}"
```

기존 wheel 을 모두 제거한 뒤 staging wheel 을 복사한다. 기존 디렉터리에 새 wheel 만
추가하지 않는다.

## 7. 완료 검증

1. 변경된 wheel 파일과 삭제된 이전 wheel 파일을 함께 확인한다.
2. 외부 package registry 없이 실제 설치되는지 확인한다.
3. 애플리케이션 테스트를 실행한다.
4. Runtime wheel이 변경되었으면 Function App과 Web App 이미지를 clean build한다.

## 8. Development Wheel

Development wheel 은 Windows 또는 macOS 환경에서 해당 Python 과 pip 를 확인한 뒤
별도 대상 디렉터리에 다운로드한다.

```bash
DEVELOPMENT_WHEELS="${STAGING_ROOT}/development/<os>-<architecture>-<python-abi>"
mkdir -p "${DEVELOPMENT_WHEELS}"

"${PYTHON}" -m pip download \
  --only-binary=:all: \
  --dest "${DEVELOPMENT_WHEELS}" \
  --requirement requirements/development_python_tools.in
```

다운로드 후 `--no-index`와 `--find-links`로 오프라인 설치를 검증하고 대상
`requirements/wheels/development/` 디렉터리를 교체한다.

개별 패키지 이름과 선택된 버전은 문서에 추가하지 않는다.
