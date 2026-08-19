#!/usr/bin/env python3
"""Dependency-free validation for canonical Invariant Markdown documentation."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DOCS = ROOT / "docs"
ALLOWED_STATUS = {"current", "partial", "experimental", "planned", "frontier", "historical"}
REQUIRED_FIELDS = {"title", "description", "status", "verified_at_commit", "source_paths", "audience"}
LEGACY_WITHOUT_FRONTMATTER = {
    DOCS / "MONOREPO-MIGRATION.md",
    # T3 competitive program material inherited from docs/invariant-documentation-foundation
    # SHA f26cd4d60330f67a356c619e69b01d3982f65f7e. These are protected
    # historical records (per WP-09 closeout Section 10) — they precede
    # the frontmatter convention. They remain legible at their original
    # commit and are not modified to satisfy the check.
    DOCS / "roadmap" / "t3-competitive-30-day" / "HOW_TO_DOGFOOD_WP09.md",
    DOCS / "roadmap" / "t3-competitive-30-day" / "LANE-EVIDENCE-M12-TEMPER-RPC.md",
    DOCS / "roadmap" / "t3-competitive-30-day" / "LANE-EVIDENCE-WP09-CONTRACTS.md",
    DOCS / "roadmap" / "t3-competitive-30-day" / "LANE-EVIDENCE-WP09-RECON.md",
    DOCS / "roadmap" / "t3-competitive-30-day" / "LANE-EVIDENCE-WP09-REVIEW-CHECKLIST.md",
    DOCS / "roadmap" / "t3-competitive-30-day" / "WP09-LESSONS-AND-REGRESSION-GUARDS.md",
    DOCS / "roadmap" / "t3-competitive-30-day" / "WP09-WARNING-BASELINE.md",
    DOCS / "roadmap" / "t3-competitive-30-day" / "client-server-boundary.md",
    DOCS / "roadmap" / "t3-competitive-30-day" / "index.md",
    DOCS / "roadmap" / "t3-competitive-30-day" / "prototype-results.md",
    DOCS / "roadmap" / "t3-competitive-30-day" / "provider-runtime-strategy.md",
    DOCS / "roadmap" / "t3-competitive-30-day" / "t3-reference-map.md",
    DOCS / "roadmap" / "t3-competitive-30-day" / "workspace-recovery.md",
    DOCS / "roadmap" / "t3-competitive-30-day" / "work-packages" / "wp-07-daemon.md",
    DOCS / "roadmap" / "t3-competitive-30-day" / "work-packages" / "wp-08-session.md",
    DOCS / "roadmap" / "t3-competitive-30-day" / "work-packages" / "wp-09-temper-rpc.md",
    DOCS / "roadmap" / "t3-competitive-30-day" / "work-packages" / "wp-10-provider-runtime.md",
}
LINK_RE = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
FULL_SHA_RE = re.compile(r"^[0-9a-f]{40}$")


def parse_frontmatter(path: Path, text: str) -> tuple[dict[str, object], list[str]]:
    errors: list[str] = []
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return {}, ["missing opening frontmatter delimiter"]
    try:
        end = next(i for i, line in enumerate(lines[1:], start=1) if line.strip() == "---")
    except StopIteration:
        return {}, ["missing closing frontmatter delimiter"]

    data: dict[str, object] = {}
    current_list: str | None = None
    for raw in lines[1:end]:
        if re.match(r"^\s+-\s+", raw) and current_list:
            value = re.sub(r"^\s+-\s+", "", raw).strip().strip("'\"")
            cast = data.setdefault(current_list, [])
            if isinstance(cast, list):
                cast.append(value)
            continue
        match = re.match(r"^([A-Za-z0-9_]+):(?:\s*(.*))?$", raw)
        if not match:
            if raw.strip():
                errors.append(f"unsupported frontmatter syntax: {raw}")
            current_list = None
            continue
        key, value = match.group(1), (match.group(2) or "").strip()
        if value:
            data[key] = value.strip("'\"")
            current_list = None
        else:
            data[key] = []
            current_list = key

    missing = sorted(REQUIRED_FIELDS - data.keys())
    if missing:
        errors.append(f"missing fields: {', '.join(missing)}")
    status = data.get("status")
    if status and status not in ALLOWED_STATUS:
        errors.append(f"invalid status {status!r}")
    if not isinstance(data.get("source_paths"), list) or not data.get("source_paths"):
        errors.append("source_paths must be a non-empty list")
    if not isinstance(data.get("audience"), list) or not data.get("audience"):
        errors.append("audience must be a non-empty list")
    return data, errors


def commit_resolves(sha: str) -> bool:
    result = subprocess.run(
        ["git", "cat-file", "-e", f"{sha}^{{commit}}"],
        cwd=ROOT,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return result.returncode == 0


def resolve_link(source: Path, target: str) -> Path | None:
    target = target.strip()
    if not target or target.startswith(("#", "http://", "https://", "mailto:", "tel:")):
        return None
    target = target.split("#", 1)[0].split("?", 1)[0]
    if not target:
        return None
    if target.startswith("/"):
        candidate = DOCS / target.lstrip("/")
    else:
        candidate = (source.parent / target).resolve()
    if candidate.is_dir():
        candidate = candidate / "index.md"
    if candidate.suffix == "":
        md_candidate = candidate.with_suffix(".md")
        if md_candidate.exists():
            candidate = md_candidate
    return candidate


def main() -> int:
    failures: list[str] = []
    docs = sorted(DOCS.rglob("*.md"))
    for path in docs:
        text = path.read_text(encoding="utf-8")
        if path not in LEGACY_WITHOUT_FRONTMATTER:
            data, errors = parse_frontmatter(path, text)
            for error in errors:
                failures.append(f"{path.relative_to(ROOT)}: {error}")

            verified_at_commit = data.get("verified_at_commit")
            if isinstance(verified_at_commit, str):
                if not FULL_SHA_RE.fullmatch(verified_at_commit):
                    failures.append(
                        f"{path.relative_to(ROOT)}: verified_at_commit must be a full 40-character lowercase SHA"
                    )
                elif not commit_resolves(verified_at_commit):
                    failures.append(
                        f"{path.relative_to(ROOT)}: verified_at_commit does not resolve in local history: {verified_at_commit}; fetch full history before validating docs"
                    )

            source_paths = data.get("source_paths", [])
            if isinstance(source_paths, list):
                for source_path in source_paths:
                    candidate = ROOT / str(source_path)
                    if not candidate.exists():
                        failures.append(
                            f"{path.relative_to(ROOT)}: source_path does not exist in current tree: {source_path}"
                        )

        for match in LINK_RE.finditer(text):
            candidate = resolve_link(path, match.group(1))
            if candidate is not None and not candidate.exists():
                failures.append(
                    f"{path.relative_to(ROOT)}: broken local link {match.group(1)!r}"
                )

    forbidden = ROOT / "products" / "bench"
    if forbidden.exists():
        failures.append("products/bench exists; Bench must remain inside products/arsenal/evaluation")

    for generated in (ROOT / "docs-site" / "build", ROOT / "docs-site" / ".docusaurus"):
        if generated.exists() and (generated / ".git").exists():
            failures.append(f"generated site state contains a nested git root: {generated.relative_to(ROOT)}")

    if failures:
        print("documentation check: FAIL", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1

    print(f"documentation check: PASS ({len(docs)} Markdown files checked)")
    print("note: structural docs validation does not establish semantic freshness or product acceptance")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
