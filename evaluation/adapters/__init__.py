# Project Arsenal — Repository Recon Method Adapter Surface
#
# Status: experimental (ARS-W3 Phase 1)
#
# The adapter package provides the seam through which the ARS-04
# evaluator can be configured to invoke an EXTERNAL Repository Recon
# procedure (e.g. the Loadout productized procedure) instead of the
# internal fixture procedure in scripts/arsenal_evaluate.py.
#
# The contract between the evaluator and any adapter is intentionally
# minimal: an adapter accepts a target repository path and returns a
# list of findings in the documented shape:
#
#     [
#         {
#             "kind":    "presence" | "absence" | "capability_identity",
#             "subject": <canonical subject string>,
#             "evidence": <repo-relative path string>,
#             "actual":  <bool for presence/absence, dict for
#                          capability_identity, None when unreadable>,
#         },
#         ...
#     ]
#
# The evaluator compares those findings against the expected
# assertions declared by each corpus case. The adapter is the SOLE
# ground truth the evaluator consults; the fixture state is never
# re-inspected by the evaluator's assertion-comparison logic.
#
# Adapter constraints (Wave 3 contract):
#
#   * An adapter MUST NOT import Loadout source code.
#   * An adapter MUST NOT depend on Loadout runtime (no shelling out
#     to ``loadout run`` until Phase 2 when Loadout's interface is
#     concrete and stable).
#   * An adapter MUST emit the adapter identity (name) so the
#     evaluator can record which procedure actually produced the
#     findings in the evaluation artifact.
#   * An adapter MUST be deterministic and read-only with respect to
#     the target repository (no writes to the repo, no network, no
#     remote credentials).
#
# The bundled adapters in this package are:
#
#   * internal_fixture_adapter.InternalFixtureProcedureAdapter
#       -- the original internal procedure in scripts/arsenal_evaluate.py.
#          This adapter is the canonical reference and remains the
#          default when no --adapter option is supplied.
#
#   * shell_loadout_adapter.ShellLoadoutReconAdapter
#       -- reads pre-emitted findings from a JSON file. This is the
#          Phase 1 placeholder for the eventual Loadout
#          ``loadout run --plan <plan>`` invocation. In Phase 2 the
#          shell adapter MAY be replaced by a runtime adapter that
#          invokes the Loadout CLI through a stable, documented
#          interface; the Phase 1 adapter is not yet that runtime.
#
# The evaluator (scripts/arsenal_evaluate.py) is the only consumer
# of this package today.
