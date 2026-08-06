# Reference Index

These references informed the proposed design. They are precedents, not dependencies.

| System | Design lesson | Canonical reference |
| --- | --- | --- |
| Frama-C | Collaborative analyzers and property-status consolidation | https://frama-c.com/ |
| Infer | Incremental analysis and change classification | https://fbinfer.com/ |
| Scalafix | Syntactic/semantic rules and lint/rewrite separation | https://scalacenter.github.io/scalafix/ |
| Stan | Inspection catalog and compiler-derived observations | https://hackage.haskell.org/package/stan |
| HLint | Audit-to-baseline adoption and cautious rewrites | https://github.com/ndmitchell/hlint |
| Semgrep | Multi-language rules and policy distribution | https://semgrep.dev/ |
| SARIF | Static-analysis result interchange | https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html |
| Rosette | Counterexample-first solver-aided verification | https://docs.racket-lang.org/rosette-guide/ |
| LiquidHaskell | Refinement-type proof obligations | https://ucsd-progsys.github.io/liquidhaskell/ |
| ACL2 | Properties, assumptions, and proof results | https://acl2.org/ |
| Eastwood | Analysis can load and execute Project code | https://github.com/jonase/eastwood |
| LSP | Request identity, cancellation, progress, terminal results | https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/ |
| in-toto | Digest-bound typed statements and optional envelopes | https://github.com/in-toto/attestation |

## Usage rule

Documentation and implementation tickets should cite a predecessor when borrowing a mechanism and state where Kiln deliberately diverges.
