# 인증 전략

## 1. 원칙

비즈니스 로직은 인증 방식을 직접 알지 못한다.

```text
Business Core
   |
Client Factory / Credential Factory
   |
Provider + Auth Mode
```

인증 선택은 런타임 설정으로 결정한다.

## 2. Azure 환경

Azure 환경에서는 Managed Identity 를 우선한다.

## 3. 상세 인증 조합

환경별 인증 조합, Provider 별 인증 방식은 `docs/50-runtime/AUTHENTICATION_PROFILES.md`에서 정의한다.
