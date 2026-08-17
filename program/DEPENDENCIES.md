# Cross-Repository Dependency Map

> SUPERSEDED — see program/SUPERSESSION-NOTICE.md.
> Preserved as provenance; not active authority for monorepo work.

## Launch dependency order

1. [x] Accept Decision 0001.
2. [x] Merge the engineering-system bootstrap.
3. [x] Merge the Loadout bootstrap.
4. [x] Merge Kiln PR #62.
5. [x] Record exact launch SHAs in the three work packages.
6. [ ] Run the combined prompt's hard preflight in one MiniMax M3 environment per product repository.
7. [ ] Receive final owner authorization and launch ARS-01, LOD-01, and KIL-01 together.

## Workstream dependencies

| Workstream | May begin with | Must not wait for | Produces |
|---|---|---|---|
| ARS-01 | accepted product decision and pinned Arsenal SHA | Loadout or Kiln implementation | Qualified Method Record fixture for Repository Recon |
| LOD-01 | merged Loadout bootstrap and Work Envelope v0 | real Arsenal compiler or real Kiln adapter | stable Capability contract, fixture-backed Repository Recon, Work Envelope fixture |
| KIL-01 | resolved PR #62 and existing T01 authorization | new Arsenal/Loadout runtime work | continued Artifact/Evidence substrate plus non-invasive Result Envelope mapping note |

## Integration rules

- LOD-01 consumes the engineering-system Qualified Method fixture, not unmerged Arsenal code.
- LOD-01 targets the Work Envelope fixture, not an unimplemented Kiln API.
- KIL-01 does not add Work Envelope ingestion unless separately planned and authorized after T01.
- ARS-01 does not publish directly into Loadout or Kiln.
- No product repository pins another product implementation during this first wave.
- Compatibility is proven against fixtures before real adapters replace them.
- Stale ECC bundle PRs are excluded from every workstream and must not be merged, copied, or treated as instructions.

## Critical path

The first integration dependency is not code. It is agreement on the semantic minimum of:

- Qualified Method Record v0;
- Work Envelope v0;
- Run Result Envelope v0;
- Learning Observation v0.

Those contracts remain experimental until the 90-day proof completes.
