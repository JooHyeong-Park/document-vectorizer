# Dependency 및 패키지 관리 정책

## 1. 목적

내부망 PC 는 인터넷과 컨테이너 런타임이 없으므로 저장소 자체만으로 runtime dependency 를 설치할 수 있어야 한다.

컨테이너 빌드는 외부 package registry 에 의존하지 않고 재현 가능해야 한다.

## 2. 관리 원칙

- 내부망 설치는 public PyPI 로 fallback 하지 않는다.
- Runtime dependency 는 `.tar.gz` source distribution 을 요구하지 않는다.
- 내부망 설치는 C/C++/Rust build tool 을 요구하지 않는다.
- Business Core 는 Linux 전용 filesystem/path 동작에 의존하지 않는다.
- Dependency 변경 시 dependency 정의 파일과 오프라인 설치 package를 함께 갱신한다.

## 3. 변경 완료 조건

Dependency 를 하나라도 추가/변경하면 Agent 는 다음을 모두 수행한다.

1. Dependency 정의 파일 갱신
2. 대상 실행 환경의 package 갱신
3. source distribution 없이 설치 가능한지 확인
4. 외부 registry 없이 설치 가능한지 확인

Dependency 정의 파일의 역할은 `docs/50-dependencies/PYTHON_PACKAGING.md`에서 정의하고,
상세 변경 절차는 `docs/50-dependencies/UPDATE_WHEELS.md`에서 정의한다.
