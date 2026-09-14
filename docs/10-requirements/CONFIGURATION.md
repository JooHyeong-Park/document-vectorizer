# 런타임 설정 Contract

## 1. 기본 원칙

환경별 설정을 이미지 또는 소스에 포함하지 않는다.

금지 예:

```python
if ENV == "prod":
    ...
```

권장 방식:

```python
if settings.embedding_provider == "azure_openai":
    ...
```

애플리케이션 동작은 환경 이름이 아니라 명시적 capability/provider 설정으로 결정한다.

## 2. 설정 로딩 규칙

- 단일 설정 계층에서 읽고 validation 한다.
- 필수 값이 누락되면 요청 처리 중이 아니라 application startup 단계에서 실패하도록 한다.

## 3. 상세 Contract

설정 키, 허용 값, Secret 후보 및 환경별 주입 방식은 `docs/50-runtime/CONFIGURATION_CONTRACT.md`에서 정의한다.
