# GCP Overlay Completion Receipt Template

Use the common provider receipt schema and add:

- synthetic project ID;
- `STORAGE_EMULATOR_HOST` and `PUBSUB_EMULATOR_HOST`;
- pinned `floci-gcp` image;
- Google SDK versions;
- GCS/Pub/Sub operations exercised;
- deterministic result SHA-256;
- explicit provider-only IAM/project/quota/durability residue.
