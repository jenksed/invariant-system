-- P1-S01-T06 durable idempotency lookup by key alone.
--
-- The workflow's start_session/1 retry must find the original commit by
-- idempotency_key without knowing the original session_id, since the
-- retry generates a fresh session_id. The existing
-- UNIQUE (session_id, idempotency_key) constraint requires the session_id
-- to be known at lookup time, so we add a global UNIQUE INDEX on
-- idempotency_key. Idempotency keys are random 16-byte opaque identifiers,
-- so global uniqueness is the right contract.
--
-- The per-session UNIQUE constraint from migration 0001 is left in place
-- because it is logically implied by the new global uniqueness and dropping
-- it would require recreating the table. The new index is the only one
-- that enforces the lookup contract.

CREATE UNIQUE INDEX action_commits_idempotency_key_idx
  ON action_commits (idempotency_key);
