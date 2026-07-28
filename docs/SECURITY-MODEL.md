# Security model

**Status:** Initial threat-model direction, not a claim of complete sandboxing.

## Principles

- least privilege;
- explicit capability requests;
- conservative defaults;
- repository-scoped writes;
- no browser-held provider secrets;
- no ambient plugin authority;
- honest distinction between policy mediation and OS containment.

## Candidate capabilities

```text
workspace.read
workspace.write
filesystem.read:<path>
filesystem.write:<path>
process.spawn
process.interactive
process.network
network.host:<hostname>
git.read
git.commit
git.push
secrets.read:<name>
extension.execute:<extension>
```

A tool or extension declares required capabilities. Policy classifies each request as automatically granted, granted once, granted for the session, confirmation required, or denied.

## Initial defaults

- allow reads inside the active repository;
- record and mediate repository writes;
- deny writes outside the workspace by default;
- ask before accessing a new network host;
- deny sensitive directories by default;
- deny Git push unless explicitly initiated;
- never expose provider credentials to browser code;
- supervise external commands and record their termination state.

## Important limitation

BEAM process isolation is not an operating-system sandbox. A supervised process can still invoke a destructive external command if policy allows it.

Kiln's early security layer is permission mediation and process supervision. Stronger containment may later require platform-specific sandboxing, containers, namespaces, resource limits, or a small Rust helper.

Security documentation must state which guarantees are implemented and which remain aspirational.
