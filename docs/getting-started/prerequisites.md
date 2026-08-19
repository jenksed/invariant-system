---
title: Prerequisites
description: Toolchains required by current Invariant product gates.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - invariant
  - products/kiln/mise.toml
  - products/loadout/package.json
  - products/temper/package.json
audience:
  - developer
---

# Prerequisites

Run the repository's own diagnostic first:

```bash
./invariant doctor
```

The current root command checks for Git, GitHub CLI, Python 3, Node, npm, Mix/Elixir, a C compiler, Vale, jq, PyYAML, and `jsonschema`. Loadout and Temper currently target Node 20.10+; Kiln's exact Elixir/Erlang pins live in `products/kiln/mise.toml`.

`doctor` reports state. It does not install global tooling.

## Product-specific setup

Use each product's current README/AGENTS guidance for its canonical environment. The root command deliberately delegates rather than creating a second package-management layer.

The documentation site has an isolated Node toolchain under `docs-site/`; it must not change product runtime requirements.
