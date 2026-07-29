-- P1-S01-T02 initial state schema for kiln-state/v1.
-- Forward-only. The applied checksum of this file is immutable once recorded.
-- The schema_migrations and store_metadata bookkeeping tables are created by
-- the startup runner before any migration is applied, so the store format can
-- be verified independently of the domain schema; they are not defined here.

-- Immutable ordered work facts. sequence is the global monotonic order.
CREATE TABLE journal_entries (
  sequence INTEGER PRIMARY KEY AUTOINCREMENT,
  entry_id TEXT NOT NULL UNIQUE,
  entry_schema TEXT NOT NULL,
  entry_type TEXT NOT NULL,
  payload_schema TEXT NOT NULL,
  session_id TEXT NOT NULL,
  session_revision INTEGER NOT NULL,
  action_id TEXT NOT NULL,
  actor_kind TEXT NOT NULL,
  actor_id TEXT NOT NULL,
  idempotency_key TEXT NOT NULL,
  request_digest TEXT NOT NULL,
  causation_entry_id TEXT REFERENCES journal_entries (entry_id),
  correlation_id TEXT,
  recorded_at TEXT NOT NULL,
  payload TEXT NOT NULL,
  payload_digest TEXT NOT NULL,
  UNIQUE (session_id, session_revision)
);

CREATE INDEX journal_entries_session_seq ON journal_entries (session_id, sequence);

-- One idempotency record and canonical result per committed application action.
CREATE TABLE action_commits (
  action_id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  idempotency_key TEXT NOT NULL,
  request_digest TEXT NOT NULL,
  expected_session_revision INTEGER NOT NULL,
  first_sequence INTEGER NOT NULL,
  last_sequence INTEGER NOT NULL,
  result_schema TEXT NOT NULL,
  result TEXT NOT NULL,
  result_digest TEXT NOT NULL,
  committed_at TEXT NOT NULL,
  UNIQUE (session_id, idempotency_key)
);

-- One rebuildable current projection per Session. Never more authoritative
-- than the journal.
CREATE TABLE session_projections (
  session_id TEXT PRIMARY KEY,
  projection_schema TEXT NOT NULL,
  session_revision INTEGER NOT NULL,
  last_sequence INTEGER NOT NULL,
  projection TEXT NOT NULL,
  projection_digest TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

-- Bounded interaction records. Separate from domain state; a transcript write
-- cannot update a projection.
CREATE TABLE transcript_records (
  transcript_id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  run_id TEXT,
  actor_kind TEXT,
  actor_id TEXT,
  sequence INTEGER,
  recorded_at TEXT NOT NULL,
  content TEXT,
  content_ref TEXT,
  content_digest TEXT
);

CREATE INDEX transcript_records_session ON transcript_records (session_id, transcript_id);
