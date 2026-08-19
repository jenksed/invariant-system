# Arsenal Experiment Registry

> **EXPERIMENTAL — Arsenal research program artifact (branch `research/arsenal-program-foundation`). Not doctrine, not promoted, no runtime authority. SUPPORTED ≠ QUALIFIED ≠ PROMOTED.**


Status: draft

This registry records every experiment in the Arsenal research program. An experiment must be registered here before it enters the `READY` state.

## Rules

- Every experiment registers here before entering `READY`.
- Registration fields are: `Experiment`, `Title`, `State`, `Protocol version`, `Protocol`, `Evidence`.
- States follow the vocabulary defined in `../../docs/arsenal-experiment-contract.md` (ARS-000):
  `IDEA`, `DESIGNED`, `READY`, `RUNNING`, `INCONCLUSIVE`, `FALSIFIED`, `SUPPORTED`, `REPLICATED`, `QUALIFIED`, `PROMOTION_CANDIDATE`, `PROMOTED`, `REJECTED`.
- Protocol versions are preserved, never overwritten. A new version is a new protocol artifact.
- Evidence locations are referenced, not copied. The canonical evidence manifest for each experiment is `EVIDENCE-MANIFEST.md` in the experiment directory.
- `SUPPORTED` ≠ `QUALIFIED` ≠ `PROMOTED`. Arsenal does not set `PROMOTED`; that decision belongs to the affected product or runtime authority.

## Registry

| Experiment | Title | State | Protocol version | Protocol | Evidence |
|------------|-------|-------|------------------|----------|----------|
| ARS-000 | Research Operating Contract | DESIGNED | 0.1.0 | `../../docs/arsenal-experiment-contract.md` | Foundation contract; states and vocabulary defined there. This is the contract itself, not an empirical experiment. |
| ARS-001 | Execution-State Validity Challenge | DESIGNED | 0.1.0 | `evaluation/experiments/ars-001-execution-state/PROTOCOL.md` | Pending first run; evidence manifest to follow. |
| ARS-002 | Semantic Concurrency | IDEA | — | — | Deferred until experiment machinery is credible. |
| ARS-003 | Graph Operator Comprehension Study | DESIGNED | 0.1.0 | `evaluation/experiments/ars-003-operator-comprehension/PROTOCOL.md` | Formative UX-research study; evidence manifest to follow. |
| ARS-004 | Long-Horizon Repository Health | IDEA | — | — | Explicit future program. |
| ARS-005 | Evaluator Integrity Challenge | DESIGNED | 0.1.0-draft | `evaluation/experiments/ars-005-evaluator-integrity/PROTOCOL-DRAFT.md` | Design initiated; gated on ARS-001 infrastructure. |
| ARS-006 | Steering Semantics | IDEA | — | — | Explicit future program. |
