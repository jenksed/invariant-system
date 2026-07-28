# Architecture

**Status:** Initial direction; implementation details remain provisional.

## System shape

Kiln separates its durable runtime from its interfaces.

```text
                         Developer
                             |
             +---------------+----------------+
             |               |                |
            CLI       Phoenix LiveView   Headless API
             |               |                |
             +---------------+----------------+
                             |
                    Harness domain API
                             |
                    Workspace session
             +---------------+----------------+
             |               |                |
       Context engine   Execution engine   Event journal
             |               |                |
      Provider layer    Tool supervisor      SQLite
                             |
                    Capability broker
                             |
             +---------------+----------------+
             |               |                |
        Native tools    Extensions       External systems
```

The CLI, web interface, and future clients are projections. They do not own session truth.

## Runtime ownership

A process should exist only when it owns mutable state, a resource lifetime, concurrency, cancellation, failure isolation, or external communication.

A likely later supervision shape is:

```text
Kiln.Application
├── Kiln.Store
├── Kiln.ProviderRegistry
├── Kiln.ExtensionRegistry
├── Kiln.WorkspaceRegistry
└── Kiln.WorkspaceSupervisor
    └── Kiln.WorkspaceSession
        ├── model request supervisor
        ├── tool execution supervisor
        ├── permission broker
        ├── context projection
        └── evidence collector
```

This is directional, not a mandate to create a process for every module.

## Domain API

All interfaces must use explicit commands and queries.

Candidate commands:

- start session;
- record intent;
- submit message;
- interrupt session;
- approve or deny a capability;
- create checkpoint;
- resume session;
- run verification;
- request completion.

Candidate queries:

- session snapshot;
- event history;
- workspace status;
- current context;
- active executions;
- verification status;
- unresolved findings;
- completion readiness.

Interfaces must not directly manipulate arbitrary GenServers or persistence records.

## Source authority

- SQLite owns harness events and resumable session state.
- Git owns committed source history and branch identity.
- The filesystem owns current working artifacts.
- The transcript is a projection, not the canonical session.

## Initial implementation rule

Version 0.1 remains one Mix project. An umbrella is deferred until actual dependency, release, or ownership boundaries justify it.
