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

Values are parsed as data and are never sourced or executed. Blank values, duplicate keys, unknown keys, malformed digests, a non-ancestor base, a work-ID mismatch, or any state other than `authorized` fails preflight.

An authorization record does not prove implementation, verification, acceptance, integration, or delivery. It only permits the bounded package to begin from the recorded authority state.
