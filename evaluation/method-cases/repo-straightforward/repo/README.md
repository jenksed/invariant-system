# Fixture: Straightforward Repository

This is the simplest case the recon method must handle.

It contains:
- an AGENTS.md (the always-loaded entrypoint the recon method reads first);
- a README.md (project context);
- a small src/ tree with one module.

It does NOT contain canonical contracts, governance, or capability fragments.
The recon method should report a clean, simple architecture anchor with no
unsupported claims and no unknowns that block understanding.
