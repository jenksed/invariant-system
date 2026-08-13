# Productized Adoption Evidence

The selected research method is now implemented beneath Loadout's unchanged
`repository-recon` Capability at exact commit
`65761781968596f62327d1c6a7ab582d699f5216` on canonical `main`.

The evaluation invoked that real Loadout build through the external
`loadout-runtime` adapter. Arsenal imported no Loadout source. The four target
repositories remained at their frozen commits and the adapter performed no
writes.

| Surface | Baseline | Productized winner | Unsupported factual claims |
|---|---:|---:|---:|
| Original product target | 5/16 | 16/16 | 0 |
| Project Arsenal development | 4/15 | 15/15 | 0 |
| Loadout development | 4/15 | 15/15 | 0 |
| Kiln validation | 4/15 | 15/15 | 0 |
| Temper holdout | 4/15 | 15/15 | 0 |

The stable Capability contract digest remains
`sha256:32bf4718256a3cb5b4a6b24ad061c0863f582b99e8b71e5dd1a640077df901dd`.
The adopted procedure binding is
`sha256:d1308f3dd8d35cb414935db3e73751f683a3af944e48e8862e206bafb8218ab2`.

The result is deterministic and records one useful unknown on Temper:
governance authority is not claimed when neither accepted root governance file
exists. Full machine-readable evidence is in `results/productized.json`.

This is evaluation and adoption evidence, not a qualified QMR. The QMR v0
target/adapter binding gap remains exactly as documented in
`CONTRACT-ADJUDICATION-REQUIRED.md`.
