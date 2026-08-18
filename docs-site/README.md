# Invariant documentation site

This directory is presentation infrastructure for canonical Markdown in `../docs`.

Do not copy documentation into this directory. Docusaurus reads `../docs` directly.

## Requirements

Node 20.10+ and npm.

## Install

```bash
cd docs-site
npm ci
```

## Validate

```bash
npm run check
```

The dependency-free checker validates major-page frontmatter, status values, declared source paths, local Markdown links, and the Bench topology invariant.

## Develop

```bash
npm run start
```

## Build static HTML

```bash
npm run build
```

Generated output is written to `docs-site/build/` and is ignored by Git.

`DOCS_SITE_URL` and `DOCS_BASE_URL` can be supplied by the eventual deployment environment. Local/default builds use `http://localhost` and `/` so this foundation does not invent a production docs domain.

Search is intentionally not coupled to an external service yet. Docusaurus supports hosted Algolia DocSearch; adding it should be a deployment decision once a stable public documentation URL exists.
