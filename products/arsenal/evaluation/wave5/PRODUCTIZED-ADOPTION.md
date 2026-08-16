# Productized Adoption Evidence

The selected research method is now implemented beneath Loadout's unchanged
`repository-recon` Capability at exact commit
`c29a1df7d302c9043360fdf40431a6f079bbb4b1` on canonical `main`.

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
`sha256:d3b42aaef36e4c7d8c2c10a86aecee228e04a2b84fb22e5bbc920b95fc2fe6e9`.

The result is deterministic and records one useful unknown on Temper:
governance authority is not claimed when neither accepted root governance file
exists. Full machine-readable evidence is in `results/productized.json`.

This is evaluation and adoption evidence, not a qualified QMR. The QMR v0
target/adapter binding gap remains exactly as documented in
`CONTRACT-ADJUDICATION-REQUIRED.md`.
