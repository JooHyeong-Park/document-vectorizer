# 데이터 모델

## 1. 범위

문서 처리 결과와 처리 상태를 PostgreSQL `vectorizer` schema에 저장한다.

## 2. 문서 Chunk 저장

`vectorizer_documents` 테이블은 문서의 Chunk와 Embedding을 저장한다.

```text
document_id       BIGSERIAL primary key
blob_container    원본 Blob container
blob_name         원본 Blob name
blob_etag         처리 시점의 Blob ETag
chunk_index       문서 내 Chunk 순서
content           Chunk 텍스트
embedding         pgvector vector
embedding_model   Embedding model 식별자
metadata          Blob metadata를 담은 JSONB
status            현재 구현에서는 `succeeded`로 저장
created_at        생성 시각
updated_at        변경 시각
```

각 문서·ETag·Embedding model·Chunk 조합은 하나의 row만 가질 수 있다.

```text
(blob_container, blob_name, blob_etag, embedding_model, chunk_index)
```

Embedding vector의 dimension은 provider 응답을 애플리케이션 설정값과 비교해 검증한다.
Database의 vector column은 dimension을 고정하지 않으므로 설정된 모델에 따라 사용할 수
있으며, `embedding_model`을 함께 저장한다.

## 3. 처리 상태 저장

`vectorizer_processing` 테이블은 문서·ETag·Embedding model 단위의 처리 상태를 저장한다.

```text
processing_id     BIGSERIAL primary key
blob_container    원본 Blob container
blob_name         원본 Blob name
blob_etag         처리 시점의 Blob ETag
embedding_model   Embedding model 식별자
status            processing | succeeded | failed
error             실패 메시지
updated_at        변경 시각
```

동일한 문서·ETag·Embedding model 조합은 하나의 처리 상태 row만 가진다.

## 4. 처리 및 재처리 규칙

- 처리 시작 전에 동일한 Blob container, Blob name, ETag, Embedding model로 성공한 문서가 있는지 확인한다.
- 이미 성공한 조합이면 문서 처리와 저장을 생략한다.
- 새 ETag이면 변경된 문서로 처리한다.
- 새 처리 성공 시 해당 Blob name의 기존 문서 Chunk row를 삭제하고 현재 결과를 저장한다.
- 기존 ETag의 처리 상태 row는 이력으로 남고, 현재 문서 Chunk row는 최신 처리 결과로 교체된다.
- 처리 시작, 성공, 실패 상태는 `vectorizer_processing`에 기록한다.
- 실패 메시지는 최대 2,000자로 저장한다.
