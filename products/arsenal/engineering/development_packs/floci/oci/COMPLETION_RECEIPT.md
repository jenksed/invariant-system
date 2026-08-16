# OCI Overlay Completion Receipt Template

Use the common provider receipt schema and add:

- synthetic namespace and tenancy context;
- explicit Object Storage endpoint;
- whether signature enforcement was enabled;
- pinned `floci-oci` image;
- Object Storage operations exercised;
- deterministic result SHA-256;
- explicit provider-only OCI IAM/signature/compartment/quota/durability residue.
