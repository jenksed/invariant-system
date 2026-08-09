# Implementation authorization records

This directory contains active authorization records consumed by `scripts/agent-preflight`. The absence of a record means the ticket or slice is not authorized.

Each record is named `<WORK-ID>.authorization`, for example `P1-S02-T01.authorization`, and contains exactly these keys in this order:

```text
work_id=P1-S02-T01
state=authorized
owner=Joshua Jenks
base_sha=<40 lowercase hexadecimal Git commit>
plan_sha256=<64 lowercase hexadecimal SHA-256 of the complete accepted plan file>
authorized_at=<RFC 3339 timestamp>
scope=<one non-empty line describing the bounded authorized package>
```

The key order shown above is canonical and enforced. Values are parsed as data and are never sourced or executed. Blank or whitespace-only owner and scope values, duplicate or reordered keys, unknown keys, malformed digests, invalid RFC 3339 calendar, clock, or offset values, a non-ancestor base, a work-ID mismatch, an owner absent from `TRUSTED-OWNERS`, or any state other than `authorized` fails preflight.

The accepted plan and authorization record must both be tracked and byte-identical to their active versions at freshly fetched `refs/remotes/origin/main`. Preflight identifies the trusted commit that contains the exact pair and requires that commit to be ancestral to the implementation state. Creating or committing either file only on an implementation branch cannot issue authority.

`TRUSTED-OWNERS` contains one exact owner identity per line. The registry is read from trusted Repository authority, not from an implementation working-tree edit.

An authorization record does not prove implementation, verification, acceptance, integration, or delivery. It only permits the bounded package to begin after the plan and record integrate through the trusted governance path.
