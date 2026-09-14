# AI 기능

## 1. 범위

현재 AI 기능은 문서 Chunk의 Embedding vector 생성이다. Chat completion, 요약, 분류
등의 기능은 구현 범위에 포함하지 않는다.

## 2. Embedding Provider

현재 지원 Provider는 다음과 같다.

- `azure_openai`
- `openrouter`

Azure OpenAI는 Azure OpenAI client를 사용하고, OpenRouter는 OpenAI 호환 client를
사용한다. 두 Provider 모두 동일한 `EmbeddingClient` action을 통해 호출한다.

## 3. Embedding 처리

- 여러 Chunk 텍스트를 설정된 `batch_size` 단위로 나누어 요청한다.
- Provider 응답의 `index`를 기준으로 원래 Chunk 순서에 맞게 정렬한다.
- 각 vector의 dimension이 설정된 `dimensions`와 다르면 저장하지 않고 실패한다.
- 요청에 사용한 `model`과 설정된 dimension은 처리 결과와 함께 저장한다.
- Chunking은 Embedding profile의 `document_chunk_size`와 `document_chunk_overlap`을 사용한다.
- Chunk tokenization은 model encoding을 우선 사용하고, 인식하지 못하는 model은 `cl100k_base`로 대체한다.

## 4. Model 일관성

Embedding model은 처리 상태와 저장 row의 식별 기준에 포함된다. 따라서 동일 Blob에
대해 다른 model로 생성한 vector를 같은 처리 결과로 취급하지 않는다.

Embedding profile을 변경하면 변경된 model과 dimension으로 다시 처리한다. 현재 저장
동작은 동일 Blob name의 기존 Chunk를 삭제하고 새 결과로 교체하므로, vector 검색 시
사용하는 model과 현재 저장된 vector의 model을 일치시켜야 한다.
