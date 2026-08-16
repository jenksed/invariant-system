# Azure Overlay Completion Receipt Template

Use the common provider receipt schema and add:

- Azure storage connection mode;
- Blob and Queue path-style local endpoints;
- pinned `floci-az` image;
- Azure SDK versions;
- Blob/Queue operations exercised;
- deterministic result SHA-256;
- explicit provider-only Azure identity/RBAC/durability residue.
