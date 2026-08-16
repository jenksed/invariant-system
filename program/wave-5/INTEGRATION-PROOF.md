# Wave 5 Real Integration Proof

## Canonical product state

| Product | Wave 5 accepted main SHA |
|---|---|
| Project Arsenal | `c33f95121eb72518c75c3761f5428684517fc5a7` |
| Loadout | `c29a1df7d302c9043360fdf40431a6f079bbb4b1` |
| Kiln | `bd2c9bcf715c99ef4f126179c1739c3b031039fc` |
| Temper | `57e78b576105dc9c4051f133d0b4697b2e35a8a0` |

Project Arsenal and Loadout exact-head CI were green before merge. Canonical
Loadout main was then clean-installed and passed its full CI surface. The two
old ECC-only PRs in Arsenal and Kiln were deliberately ignored.

The Project Arsenal generalization Run targeted evaluation merge
`0acbad2f298cd26cfc66b6ca9ff2948bd75e03c8`. Final main
`c33f95121eb72518c75c3761f5428684517fc5a7` differs only by the subsequent
productized proof binding to repaired Loadout main; all four exact-head Arsenal
workflows passed on that final binding before merge.

## Original dogfood before and after

**Repository:** `/private/tmp/wave3-owner-proof.39u1wm/dogfood-arsenal`  
**Repository commit:** `4dcc1b0fe5c6a198c62b4b130fc9ff7c0e1b15e6`

| Fact | Old | New |
|---|---|---|
| Plan method | `repository-recon/fixture-method@0.0.0-fixture` | `repository-recon/staged-evidence-graph@0.2.0` |
| Plan | `sha256:3a77d77f84f5d05c0321510903b5eaa5afb2975308561e6e9c72949436dda199` | `sha256:0e2a43050195cc670ecf582ffd5541796c8d6150544e9d4589b1282d4a121738` |
| Recon schema | `loadout/repository-recon/v1` | `loadout/repository-recon/v2` |
| Real Run | `019ffc3f-2966-730b-a837-e424a8ac04e0` | `019ffd32-4c5f-7301-8b78-0bdfd50dcef5` |

The original six summary anchors and three honest unknowns remain unchanged.
The new result adds 7,844 deterministic evidence claims: tracked paths,
bounded absences, structured manifest values, literal manifest lines, and
literal document-reference edges. It newly supports all 11 frozen misses.
No old claim was removed or corrected because the baseline's five supported
facts were already true. Primary runtime, architecture ownership, and missing
manifest/test-root facts remain unknown or explicitly absent rather than
inferred.

The new Run completed through real Kiln with `git.read` granted, one
Kiln-authored Evidence reference, two durable Artifact references, two runtime
unknowns, and acceptance readiness `false`. A fresh Kiln process reconstructed
the same Run from SQLite with the same identity, authority, Evidence, Artifacts,
and final state.

## Four-repository real execution

Every row used a fresh `Understand this repository` Plan, the stable
`repository-recon` Capability, the adopted method, normal Loadout planning,
real Kiln supervision, and existing Temper. No special Wave 5 execution path
was introduced.

| Repository | Stack | Commit | Run ID | Benchmark | False claims | Useful unknown |
|---|---|---|---|---:|---:|---|
| Project Arsenal | Python / JSON / Markdown | `0acbad2f298cd26cfc66b6ca9ff2948bd75e03c8` | `019ffd29-fb79-7105-b207-8127264954c4` | 15/15 | 0 | primary runtime not declared |
| Loadout | TypeScript / Node | `c29a1df7d302c9043360fdf40431a6f079bbb4b1` | `019ffd30-6b91-7f01-825e-cc3aa91065e5` | 15/15 | 0 | none required by oracle |
| Kiln | Elixir / Mix | `bd2c9bcf715c99ef4f126179c1739c3b031039fc` | `019ffd2a-3303-7358-9cc7-c561ac300ca9` | 15/15 | 0 | none required by oracle |
| Temper | TypeScript / Node | `57e78b576105dc9c4051f133d0b4697b2e35a8a0` | `019ffd2a-02d7-7445-9702-8d5e4f200519` | 15/15 | 0 | no accepted governance authority |

Each Run reports completed, `git.read` granted, one Evidence reference, two
Artifact references, and acceptance readiness false. A single fresh Kiln
process reconstructed all four from the durable store.

Installing Kiln's locked Hex dependency after its first Plan changed the
workspace digest. Loadout rejected that Plan as stale. The proof regenerated
the Kiln Plan against the new state and then executed it; the freshness gate
was demonstrated rather than bypassed.

The clean-checkout proof also exposed and repaired one actual regression:
Loadout assumed `.git` was a directory and could not inspect standard linked
worktrees. Loadout PR #8 added a narrow read-only Git fallback and a real
worktree regression test. No contract changed.

## Temper proof

Canonical Temper displayed every Run as CURRENT (Temper-derived), with:

- the method identity in the real Plan;
- exact Run and Work identities;
- `git.read` authority;
- real Evidence and Artifact references;
- unknowns and acceptance readiness;
- repository currentness kept distinct from Kiln Evidence freshness;
- the exact canonical Raw Run Result.

For the final dogfood Run, canonicalized `runResult`, the Loadout run-summary
`result`, and parsed `kilnRawJson` all have SHA-256
`3a609b9274e84c944c587cb2d28a80f51d6d96f815238d79638d29ae1af4809a`.

The real interactive process accepted Plan, Run, Authority, Evidence,
Artifacts, Raw, Help, Escape, and q. It exited zero and restored the cursor.
No Temper implementation change was needed.

## Truthfulness and graduation

The winner is evaluated and adopted as **experimental**. QMR v0 cannot
canonically bind the target product commit, target procedure digest, adapter,
evaluation suite, and result digest in one structured target binding. Those
facts are preserved in Arsenal's productized evaluation artifact, but they are
not smuggled into notes and called qualification.

The smallest proposed semantic remains one optional evaluation target binding:

```text
target_product
target_commit
target_procedure_digest
adapter_id
adapter_version_or_digest
evaluation_suite_digest
result_digest
```

No engineering-system contract was evolved in Wave 5.
