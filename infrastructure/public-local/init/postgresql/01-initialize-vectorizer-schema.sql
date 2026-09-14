DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'vectorizer') THEN
    CREATE ROLE vectorizer LOGIN PASSWORD 'vectorizer1!';
  ELSE
    ALTER ROLE vectorizer LOGIN PASSWORD 'vectorizer1!';
  END IF;
END
$$;

CREATE SCHEMA IF NOT EXISTS vectorizer AUTHORIZATION pgadmin;
CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA vectorizer;

ALTER ROLE vectorizer IN DATABASE vectorizer SET search_path = vectorizer;

CREATE TABLE IF NOT EXISTS vectorizer.vectorizer_documents (
  document_id BIGSERIAL PRIMARY KEY,
  blob_container TEXT NOT NULL,
  blob_name TEXT NOT NULL,
  blob_etag TEXT NOT NULL,
  chunk_index INTEGER NOT NULL,
  content TEXT NOT NULL,
  -- The provider validates the configured dimension before this insert.  An
  -- unconstrained pgvector column allows deployments to use 1536, 3072, or
  -- another configured model dimension without changing application code.
  embedding vectorizer.vector NOT NULL,
  embedding_model TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  status TEXT NOT NULL CHECK (status IN ('processing', 'succeeded', 'failed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (blob_container, blob_name, blob_etag, embedding_model, chunk_index)
);

CREATE TABLE IF NOT EXISTS vectorizer.vectorizer_processing (
  processing_id BIGSERIAL PRIMARY KEY,
  blob_container TEXT NOT NULL,
  blob_name TEXT NOT NULL,
  blob_etag TEXT NOT NULL,
  embedding_model TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('processing', 'succeeded', 'failed')),
  error TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (blob_container, blob_name, blob_etag, embedding_model)
);

GRANT USAGE ON SCHEMA vectorizer TO vectorizer;
GRANT SELECT, INSERT, UPDATE, DELETE
  ON vectorizer.vectorizer_documents, vectorizer.vectorizer_processing
  TO vectorizer;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA vectorizer TO vectorizer;

-- A vector index requires a fixed dimension.  The application validates the
-- configured dimension before persistence, while deployments may create the
-- matching HNSW index after choosing their embedding model.
