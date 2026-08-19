---
title: Repository State
description: Inspecting Git, working-tree, and runtime-record state without confusing their authority.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - invariant
  - products/kiln/README.md
  - products/temper/README.md
audience:
  - developer
  - operator
---

# Repository State

Git and the filesystem remain source truth for repository contents. Kiln's durable records describe execution facts about observed repository state; they do not replace Git.

Useful baseline:

```bash
git status --short
git rev-parse HEAD
./invariant status
```

Temper's repository-currentness projection matters because an old Run can remain valid history while no longer proving the current checkout.

Do not infer “clean repository” from a successful historical Run, and do not infer “invalid historical Run” merely because the current HEAD moved.
