---
title: Documentation Site Generator Decision
description: Selection of an isolated Markdown-first static documentation stack for Invariant.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - docs/
  - products/loadout/package.json
  - products/temper/package.json
audience:
  - developer
---

# Documentation Site Generator Decision

## Decision

Use **Docusaurus 3.10.2** in an isolated `docs-site/` toolchain, with the docs plugin pointed at `../docs` so canonical Markdown is not copied into a framework-owned content tree.

The site layer is presentation. `docs/` remains the documentation source of truth.

## Why Docusaurus wins here

Invariant already supports Node 20.10+ for Loadout and Temper. Docusaurus 3.10.2 supports Node 20+, generates static output, supports Markdown/MDX, can read a docs directory relative to the site directory, has first-party Mermaid integration, strong theming, syntax highlighting, responsive navigation, dark/light modes, and mature static deployment paths.

The important point is compatibility: the docs layer does not need to raise Invariant's existing Node baseline.

## Alternatives considered

### VitePress

Strengths: excellent Markdown ergonomics, compact docs-focused default theme, built-in local search, clean static output, deep visual customization.

Rejected for this baseline because the current VitePress documentation requires Node 22+. Adopting the current line would increase the root toolchain floor solely for documentation. Pinning an older major line would avoid that but starts the docs system on a deliberately non-current framework.

### Astro Starlight

Strengths: polished documentation UX, Pagefind search by default, strong component model, static-first architecture.

Rejected for this baseline because current Astro requires Node 22.12+. The same toolchain-floor problem applies.

### MkDocs Material

Strengths: excellent documentation IA, search, navigation, Markdown extensions, mature theming.

Not selected because Invariant already requires Node for two current products, while introducing a second docs-specific Python dependency graph adds another environment to maintain. It remains a credible fallback if the Node strategy changes.

### Bespoke generator

Rejected. A custom Markdown parser/search/theme stack would create maintenance work unrelated to Invariant's actual product problem and would violate the “smallest mechanism that protects the property” principle.

## Source layout

```text
docs/                 canonical Markdown/MDX
docs-site/            isolated Docusaurus configuration/theme/tooling
docs-site/build/      generated static HTML (ignored)
```

The Docusaurus docs plugin uses `path: '../docs'` and `routeBasePath: '/'`.

## Search

Docusaurus has first-class Algolia DocSearch support. Local search options are community-maintained. For the foundation, search should not introduce an external service or an unreviewed community dependency merely to satisfy a checkbox. The site architecture leaves the search slot available; enabling hosted DocSearch is a deployment decision once the public docs URL exists.

## Diagrams

Use first-party `@docusaurus/theme-mermaid` and `markdown.mermaid: true`. Diagrams remain fenced Mermaid blocks in canonical Markdown.

## Dependency policy

All direct Docusaurus packages must use the same pinned version. The docs package is isolated under `docs-site/`; product package manifests remain unchanged.

A reproducible dependency lock must be committed before this branch can receive an A-level promotion verdict. If the authoring environment cannot resolve the npm graph, the foundation may be committed with a declared limitation, but it is not fully promotion-verified until `npm ci` and `npm run build` succeed from the committed lockfile.

## Build contract

```bash
cd docs-site
npm ci
npm run build
```

Development:

```bash
cd docs-site
npm ci
npm run start
```

Validation should run metadata/link checks before the static build.
