# Current Program State

> SUPERSEDED — see program/SUPERSESSION-NOTICE.md.
> Preserved as provenance; not active authority for monorepo work.

**Observed:** 2026-08-12  
**Status:** Static gates complete; final launch authorization on HOLD

| Repository | Main state | Open work | Launch implication |
|---|---|---|---|
| `jenksed/project-arsenal` | `980a58d331f4ed0679e6ae306b9d55b2ee21d179` | ARS-01 has no implementation PR; stale ECC PR #2 is excluded | Start ARS-01 from this exact `main` SHA |
| `jenksed/loadout` | `cae07f9364c9a65187a7a6fa68710d72474c5dc8` | Bootstrap merged; ECC PR #2 is stale, unmergeable, and excluded | Start LOD-01 from this exact `main` SHA |
| `jenksed/kiln` | `0f6164b0eb1f1c8e2f890e18d6636f3c0311347b` | PR #62 merged; authorized T01 branch `work/p1-s02-t01-artifact-evidence-substrate-v2` is at `d489d94e1631c982f1579aa7fe378659c9d3805a`; stale ECC PR #2 is excluded | Resume the exact authorized branch; reconcile the recorded `main` merge without widening T01 |
| `jenksed/engineering-system` | Accepted contract baseline `a087c7dc3252241e06248d3a8bf2ee28544360ad` | Bootstrap merged; ECC PR #5 is stale, unmergeable, and excluded | Read-only contract and launch-coordination source for all three agents |

## Settled facts

- Arsenal and Kiln remain separate.
- Loadout is the third product and default user-facing capability environment.
- `engineering-system` is coordination only, not a product.
- MiniMax M3 is the default daily implementation model.
- A different model or independent session verifies cross-product boundary and high-risk authority changes.
- No launch task may interrupt or widen Kiln P1-S02-T01.
- Decision 0001 and ARS-01, LOD-01, and KIL-01 are owner-accepted.
- The normal Work Envelope producer is Loadout; Arsenal is optional method provenance in normal execution.
- Open ECC bundle PRs are not launch inputs, implementation authority, or approved configuration.

## Remaining launch-time assertions

- the three isolated workspaces are clean and still resolve the pinned refs;
- MiniMax M3 with thinking is available for each writer;
- each environment can execute its repository-native verification commands;
- no other writer currently owns the Kiln T01 worktree;
- the owner supplies the final simultaneous-launch authorization token.

The combined launch prompt treats any failed assertion as a hard stop before writers begin.
