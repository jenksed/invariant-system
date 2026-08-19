---
title: Doctor
description: What ./invariant doctor checks and how to interpret missing dependencies.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - invariant
audience:
  - developer
---

# Doctor

```bash
./invariant doctor
```

The command checks executable/tool availability and selected Python modules. A missing tool means the corresponding gate may be unavailable; it does not authorize the script to install software on the machine.

Notable checks include:

- Git and `gh`;
- Python 3 + PyYAML + `jsonschema`;
- Node + npm;
- Mix + Elixir;
- C compiler;
- Vale;
- jq.

If a product gate fails after `doctor` passes, treat the gate's own error as the next source of truth rather than assuming the environment is healthy because every binary exists.
