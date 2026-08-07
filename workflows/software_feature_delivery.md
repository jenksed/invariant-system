# Software Feature Delivery

Use this playbook when substantial repository work must move from uncertain current state to independently verified completion.

## Sequence

1. `agent.repository-truth-audit` — establish actual repository state when current state is uncertain.
2. `agent.execution-plan` — convert the objective into a dependency-aware plan and acceptance gates.
3. `agent.project-session-kickoff` or `agent.resume-from-checkpoint` — execute the next coherent slice.
4. Repeat execution slices as needed without reopening completed discovery.
5. `agent.independent-verification` — verify completion claims against acceptance criteria.
6. `agent.session-handoff` — record the exact continuation point when anything remains.

## Handoff contract

Each stage must pass forward verified state, unresolved uncertainty, relevant files, and acceptance evidence. Plans and status claims never outrank repository evidence.

## Stop when

The requested capability is implemented, applicable acceptance gates pass, independent verification supports the completion claim, and remaining work is either absent or explicitly outside scope.
