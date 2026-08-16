# LocalStack → Floci Migration Acceptance Matrix

Status: template

Use one row per behavioral assumption that matters to the repository. Do not use this as a generic feature checklist.

| Area | Legacy evidence | LocalStack assumption | Floci disposition | Verification command/evidence | Result | Residual risk |
|---|---|---|---|---|---|---|
| Image/runtime | | `localstack/localstack:<tag>` | pin Floci standard or compat image | | | |
| Endpoint | | `localhost:4566` or equivalent | preserve and fail closed | | | |
| Credentials | | dummy/test credentials | preserve synthetic-only local credentials | | | |
| Init paths | | `/etc/localstack/init/...` | keep compatibility path or migrate deliberately | | | |
| Init tooling | | `aws` / `boto3` inside image | use pinned `-compat` image when required | | | |
| Persistence | | `/var/lib/localstack`, `PERSISTENCE`, volumes | map to explicit Floci storage mode + `/app/data` | | | |
| Docker daemon | | socket/network assumptions | verify exact spawned-container behavior | | | |
| Lambda | | executor/remote-docker assumptions | verify Docker execution; `LAMBDA_REMOTE_DOCKER` is a blocker | | | |
| DNS | | `localhost.localstack.cloud` | compatibility DNS may be retained; verify from actual caller context | | | |
| Health/readiness | | `/_localstack/init` / health or Ready log | preserve compat probe or adopt native init surface | | | |
| Service operation | | exact API operation/semantic | verify against current Floci operation evidence | | | |
| Inspection | | `_aws/*` debug endpoints | verify endpoint used by tests/tooling | | | |
| CI isolation | | per-job state assumptions | prove jobs/runtimes do not share writable state | | | |
| Provider-only claim | | behavior inferred from LocalStack | classify separately; do not inherit the old assumption | | | |

## Required decision states

Every row must end in one of:

- `PASS` — behavior verified on the pinned Floci runtime;
- `INTENTIONAL_CHANGE` — behavior changed by design and downstream expectations were updated;
- `BLOCKED` — migration cannot proceed safely;
- `PROVIDER_ONLY` — local emulation cannot establish the acceptance claim;
- `NOT_APPLICABLE` — the assumption is not used by this repository.

Blank rows are unresolved work.

## Migration completion gate

A migration can be called complete only when:

- inventory has zero unresolved `BLOCKER` findings;
- every load-bearing legacy behavior has a matrix row;
- the local endpoint guard is green;
- init/readiness is green;
- target integration tests are green from clean state;
- relevant direct state assertions are green;
- the matrix contains no blank result;
- provider-only residue is explicitly listed;
- rollback or revert path is known until the migration PR is accepted.
