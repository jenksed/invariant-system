#!/usr/bin/env python3
"""ARS-003 formative operator-comprehension prototype generator.

Deterministically emits:
  - graph-fixture.json: synthetic graph, event log, evidence index
  - a-conversation-tabs.html: representation A (session tabs)
  - b-graph-first.html: representation B (graph-first)
  - c-hybrid.html: representation C (graph + node conversation + timeline)

All renderings are static, self-contained HTML with inline CSS.  No JavaScript,
no network requests, no execution surface, no authority.
"""

import hashlib
import html
import json
import os

OUT_DIR = os.path.dirname(os.path.abspath(__file__))

BANNER = (
    "ARS-003 formative prototype — non-authoritative representation; "
    "not an execution surface."
)

FIXTURE_VERSION = "0.1.0"

NODES = [
    {
        "id": "root-orchestrator",
        "role": "orchestrator",
        "state": "running",
        "label": "Root Orchestrator",
        "description": "Top-level coordinator for the envelope.",
    },
    {
        "id": "contract-worker",
        "role": "worker",
        "state": "failed",
        "label": "Contract Worker",
        "description": "Drafting the shared contract; failed on contract v3 test run.",
    },
    {
        "id": "schema-worker",
        "role": "worker",
        "state": "waiting",
        "label": "Schema Worker",
        "description": "Blocked waiting for contract-worker output.",
    },
    {
        "id": "test-runner",
        "role": "worker",
        "state": "complete",
        "label": "Test Runner",
        "description": "Independent verification branch; completed during absence.",
    },
    {
        "id": "reviewer-contract",
        "role": "reviewer",
        "state": "blocked",
        "label": "Contract Reviewer",
        "description": "Assigned to review contract-worker output; nothing reviewable yet.",
    },
    {
        "id": "doc-worker",
        "role": "worker",
        "state": "complete",
        "label": "Documentation Worker",
        "description": "Child of contract-worker; produced docs before the failure.",
    },
    {
        "id": "integration-worker",
        "role": "worker",
        "state": "blocked",
        "label": "Integration Worker",
        "description": "Blocked waiting for reviewer output and schema completion.",
    },
    {
        "id": "deploy-worker",
        "role": "worker",
        "state": "running",
        "label": "Deploy Worker",
        "description": "Independent deployment branch.",
    },
    {
        "id": "report-worker",
        "role": "worker",
        "state": "failed",
        "label": "Report Worker",
        "description": "Dependent on test-runner; failed during the absence interval.",
    },
    {
        "id": "final-assembly",
        "role": "worker",
        "state": "waiting",
        "label": "Final Assembly",
        "description": "Collects all branches; waiting on several incomplete dependencies.",
    },
]

EDGES = [
    {"source": "root-orchestrator", "target": "contract-worker", "relation": "orchestrates"},
    {"source": "root-orchestrator", "target": "test-runner", "relation": "orchestrates"},
    {"source": "root-orchestrator", "target": "deploy-worker", "relation": "orchestrates"},
    {"source": "contract-worker", "target": "schema-worker", "relation": "depends_on"},
    {"source": "contract-worker", "target": "reviewer-contract", "relation": "reviews"},
    {"source": "contract-worker", "target": "doc-worker", "relation": "produces"},
    {"source": "reviewer-contract", "target": "integration-worker", "relation": "blocks_until_reviewed"},
    {"source": "doc-worker", "target": "integration-worker", "relation": "depends_on"},
    {"source": "schema-worker", "target": "final-assembly", "relation": "depends_on"},
    {"source": "test-runner", "target": "report-worker", "relation": "depends_on"},
    {"source": "deploy-worker", "target": "final-assembly", "relation": "depends_on"},
    {"source": "integration-worker", "target": "final-assembly", "relation": "depends_on"},
    {"source": "report-worker", "target": "final-assembly", "relation": "depends_on"},
]

EVENT_LOG = [
    {"timestamp": "2026-08-19T09:00:00Z", "node": "root-orchestrator", "event": "envelope_started", "details": "Envelope ARS-003-TRACE-1 started.", "evidence_ref": None},
    {"timestamp": "2026-08-19T09:05:00Z", "node": "contract-worker", "event": "started", "details": "Contract drafting began.", "evidence_ref": None},
    {"timestamp": "2026-08-19T09:06:00Z", "node": "doc-worker", "event": "started", "details": "Doc generation began as a child of contract-worker.", "evidence_ref": None},
    {"timestamp": "2026-08-19T09:08:00Z", "node": "doc-worker", "event": "completed", "details": "Documentation build succeeded.", "evidence_ref": "kiln/doc-build/v1"},
    {"timestamp": "2026-08-19T09:10:00Z", "node": "test-runner", "event": "started", "details": "Independent test branch started.", "evidence_ref": None},
    {"timestamp": "2026-08-19T09:12:00Z", "node": "deploy-worker", "event": "started", "details": "Independent deploy branch started.", "evidence_ref": None},
    {"timestamp": "2026-08-19T09:15:00Z", "node": "contract-worker", "event": "failed", "details": "Contract test failed: syntax error in contract v3.", "evidence_ref": "kiln/contract-test/v3"},
    {"timestamp": "2026-08-19T09:16:00Z", "node": "schema-worker", "event": "state_changed", "details": "Set to waiting because dependency contract-worker is failed.", "evidence_ref": None},
    {"timestamp": "2026-08-19T09:17:00Z", "node": "reviewer-contract", "event": "blocked", "details": "Blocked: no reviewable contract artifact has been produced.", "evidence_ref": None},
    {"timestamp": "2026-08-19T09:20:00Z", "node": "integration-worker", "event": "blocked", "details": "Blocked: reviewer output unavailable and schema not ready.", "evidence_ref": None},
    {"timestamp": "2026-08-19T09:30:00Z", "node": "final-assembly", "event": "waiting", "details": "Waiting on contract branch, integration, deploy, and report branches.", "evidence_ref": None},
    {"timestamp": "2026-08-19T09:35:00Z", "node": "operator", "event": "absence_interval_start", "details": "Operator stepped away.", "evidence_ref": None},
    {"timestamp": "2026-08-19T09:36:00Z", "node": "external-agent-7", "event": "change_produced", "details": "Patched contract from v3 to v4.", "evidence_ref": "kiln/contract-test/v4"},
    {"timestamp": "2026-08-19T09:38:00Z", "node": "test-runner", "event": "completed", "details": "Test branch completed with contract v4.", "evidence_ref": "kiln/contract-test/v4"},
    {"timestamp": "2026-08-19T09:40:00Z", "node": "report-worker", "event": "started", "details": "Report generation started after test-runner completion.", "evidence_ref": None},
    {"timestamp": "2026-08-19T09:41:00Z", "node": "report-worker", "event": "failed", "details": "Report failed: output format mismatch.", "evidence_ref": "kiln/report-check/v1"},
    {"timestamp": "2026-08-19T09:42:00Z", "node": "operator", "event": "reconnect", "details": "Operator returned after the absence interval.", "evidence_ref": None},
]

EVIDENCE_INDEX = {
    "kiln/contract-test/v3": {
        "node": "contract-worker",
        "status": "failed",
        "summary": "Contract v3 syntax error observed in test run.",
    },
    "kiln/contract-test/v4": {
        "node": "test-runner",
        "status": "complete",
        "summary": "Contract v4 test passed after external-agent-7 patch.",
    },
    "kiln/doc-build/v1": {
        "node": "doc-worker",
        "status": "complete",
        "summary": "Documentation build succeeded.",
    },
    "kiln/report-check/v1": {
        "node": "report-worker",
        "status": "failed",
        "summary": "Report output format mismatch.",
    },
}

ABSENCE_INTERVAL = {"start": "2026-08-19T09:35:00Z", "end": "2026-08-19T09:42:00Z"}

FIXTURE = {
    "schema_version": "0.1.0",
    "experiment_id": "ARS-003",
    "fixture_version": FIXTURE_VERSION,
    "graph": {"nodes": NODES, "edges": EDGES},
    "event_log": EVENT_LOG,
    "evidence_index": EVIDENCE_INDEX,
    "absence_interval": ABSENCE_INTERVAL,
}


def write_json(path: str, obj: dict) -> None:
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(obj, fh, indent=2, sort_keys=True, ensure_ascii=False)
        fh.write("\n")


def write_html(path: str, title: str, body: str) -> None:
    doc = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)}</title>
<style>
  body {{
    font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    margin: 0;
    padding: 0;
    background: #f7f7f8;
    color: #111;
  }}
  .banner {{
    background: #1a1a2e;
    color: #e0e0ff;
    padding: 0.75rem 1rem;
    text-align: center;
    font-size: 0.9rem;
    border-bottom: 3px solid #e94560;
  }}
  .container {{
    max-width: 1100px;
    margin: 0 auto;
    padding: 1.5rem;
  }}
  h1 {{
    font-size: 1.35rem;
    margin-top: 0;
  }}
  h2 {{
    font-size: 1.1rem;
    margin-top: 1.5rem;
    border-bottom: 1px solid #ddd;
    padding-bottom: 0.25rem;
  }}
  .meta {{
    color: #555;
    font-size: 0.9rem;
    margin-bottom: 1rem;
  }}
  .node-card {{
    background: #fff;
    border: 1px solid #ddd;
    border-radius: 6px;
    padding: 0.75rem 1rem;
    margin: 0.5rem 0;
  }}
  .node-header {{
    font-weight: 600;
    display: flex;
    gap: 0.75rem;
    align-items: baseline;
  }}
  .role {{
    font-size: 0.75rem;
    text-transform: uppercase;
    letter-spacing: 0.03em;
    color: #666;
  }}
  .state {{
    font-size: 0.75rem;
    font-weight: 700;
    padding: 0.15rem 0.45rem;
    border-radius: 999px;
  }}
  .state-running {{ background: #dbeafe; color: #1e40af; }}
  .state-waiting {{ background: #fef3c7; color: #92400e; }}
  .state-blocked {{ background: #fee2e2; color: #991b1b; }}
  .state-failed {{ background: #fecaca; color: #7f1d1d; }}
  .state-complete {{ background: #d1fae5; color: #065f46; }}
  .event {{
    background: #fff;
    border-left: 3px solid #9ca3af;
    padding: 0.5rem 0.75rem;
    margin: 0.35rem 0;
    font-size: 0.92rem;
  }}
  .event time {{
    color: #6b7280;
    font-size: 0.8rem;
    margin-right: 0.5rem;
  }}
  .event .actor {{
    font-weight: 600;
  }}
  .evidence {{
    font-size: 0.8rem;
    color: #374151;
    margin-top: 0.25rem;
  }}
  .edge-list {{
    font-size: 0.9rem;
    color: #374151;
  }}
  table {{
    border-collapse: collapse;
    width: 100%;
    font-size: 0.9rem;
    background: #fff;
  }}
  th, td {{
    border: 1px solid #ddd;
    padding: 0.45rem 0.6rem;
    text-align: left;
    vertical-align: top;
  }}
  th {{
    background: #f3f4f6;
  }}
  svg {{
    background: #fff;
    border: 1px solid #ddd;
    border-radius: 6px;
    max-width: 100%;
  }}
</style>
</head>
<body>
<div class="banner">{html.escape(BANNER)}</div>
<div class="container">
{body}
</div>
</body>
</html>
"""
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(doc)


def state_class(state: str) -> str:
    return f"state-{state}"


def render_a_conversation_tabs() -> str:
    """Representation A: session/conversation tabs (static radio-button tabs)."""
    body_parts = [
        "<h1>Representation A: Conversation / Session Tabs</h1>",
        '<p class="meta">Each tab is a node session. Events are shown as messages in chronological order. The Global tab shows cross-cutting events.</p>',
    ]

    # Build radio buttons and tab labels
    tabs = [("global", "Global")] + [(n["id"], n["label"]) for n in NODES]
    radios = []
    labels = []
    for idx, (nid, label) in enumerate(tabs):
        checked = " checked" if idx == 0 else ""
        radios.append(f'<input type="radio" name="tab" id="tab-{nid}"{checked}>')
        labels.append(f'<label for="tab-{nid}">{html.escape(label)}</label>')

    body_parts.append(
        "<style>"
        ".tabs { display: flex; flex-wrap: wrap; gap: 0.25rem; border-bottom: 2px solid #ddd; margin-bottom: 1rem; }"
        ".tabs label { padding: 0.5rem 0.75rem; cursor: pointer; background: #eee; border-radius: 4px 4px 0 0; }"
        ".tabs input { display: none; }"
        ".tabs input:checked + label { background: #1a1a2e; color: #fff; }"
        ".panel { display: none; }"
        + "".join(f"#tab-{nid}:checked ~ #panel-{nid} {{ display: block; }}" for nid, _ in tabs)
        + "</style>"
    )
    body_parts.append('<div class="tabs">')
    for nid, label in tabs:
        body_parts.append(f'<input type="radio" name="tab" id="tab-{nid}"{" checked" if nid == "global" else ""}>')
        body_parts.append(f'<label for="tab-{nid}">{html.escape(label)}</label>')
    body_parts.append("</div>")

    # Global panel
    body_parts.append('<div class="panel" id="panel-global">')
    body_parts.append("<h2>Global timeline</h2>")
    for ev in EVENT_LOG:
        body_parts.append(render_event(ev))
    body_parts.append("</div>")

    # Per-node panels
    for node in NODES:
        nid = node["id"]
        body_parts.append(f'<div class="panel" id="panel-{nid}">')
        body_parts.append(f"<h2>{html.escape(node['label'])} <span class='role'>{node['role']}</span> <span class='state {state_class(node['state'])}'>{node['state']}</span></h2>")
        body_parts.append(f"<p class='meta'>{html.escape(node['description'])}</p>")
        node_events = [ev for ev in EVENT_LOG if ev["node"] == nid]
        if node_events:
            for ev in node_events:
                body_parts.append(render_event(ev))
        else:
            body_parts.append("<p class='meta'>No direct events in this session.</p>")
        body_parts.append("</div>")

    return "\n".join(body_parts)


def render_event(ev: dict) -> str:
    evidence = ""
    if ev.get("evidence_ref"):
        ei = EVIDENCE_INDEX.get(ev["evidence_ref"], {})
        evidence = f"<div class='evidence'>Evidence: {html.escape(ev['evidence_ref'])} — {html.escape(ei.get('summary', ''))}</div>"
    return (
        f"<div class='event'>"
        f"<time>{html.escape(ev['timestamp'])}</time>"
        f"<span class='actor'>{html.escape(ev['node'])}</span> "
        f"<strong>{html.escape(ev['event'])}</strong>: {html.escape(ev['details'])}"
        f"{evidence}"
        f"</div>"
    )


NODE_POSITIONS = {
    "root-orchestrator": (400, 40),
    "contract-worker": (200, 120),
    "test-runner": (400, 120),
    "deploy-worker": (600, 120),
    "schema-worker": (120, 220),
    "reviewer-contract": (280, 220),
    "report-worker": (400, 220),
    "doc-worker": (200, 300),
    "integration-worker": (240, 380),
    "final-assembly": (400, 480),
}

NODE_SIZE = (130, 44)


def svg_graph(selected_node: str | None = None) -> str:
    """Return an SVG graph rendering."""
    lines = [
        '<svg viewBox="0 0 800 560" xmlns="http://www.w3.org/2000/svg" aria-label="Static graph layout">',
        '<defs>',
        '  <marker id="arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">',
        '    <polygon points="0 0, 10 3.5, 0 7" fill="#6b7280" />',
        '  </marker>',
        '</defs>',
    ]

    # Edges
    for edge in EDGES:
        sx, sy = NODE_POSITIONS[edge["source"]]
        tx, ty = NODE_POSITIONS[edge["target"]]
        # Adjust start/end to box borders
        dx, dy = tx - sx, ty - sy
        length = max(1, (dx ** 2 + dy ** 2) ** 0.5)
        ux, uy = dx / length, dy / length
        start_x, start_y = sx + NODE_SIZE[0] / 2 + ux * NODE_SIZE[0] / 2, sy + NODE_SIZE[1] / 2 + uy * NODE_SIZE[1] / 2
        end_x, end_y = tx + NODE_SIZE[0] / 2 - ux * NODE_SIZE[0] / 2, ty + NODE_SIZE[1] / 2 - uy * NODE_SIZE[1] / 2
        mid_x = (start_x + end_x) / 2
        mid_y = (start_y + end_y) / 2
        lines.append(
            f'<line x1="{start_x:.1f}" y1="{start_y:.1f}" x2="{end_x:.1f}" y2="{end_y:.1f}" '
            f'stroke="#6b7280" stroke-width="1.5" marker-end="url(#arrowhead)" />'
        )
        lines.append(
            f'<text x="{mid_x:.1f}" y="{mid_y:.1f}" font-size="10" fill="#4b5563" text-anchor="middle" '
            f'dy="-3">{html.escape(edge["relation"])}</text>'
        )

    # Nodes
    node_by_id = {n["id"]: n for n in NODES}
    for nid, (x, y) in sorted(NODE_POSITIONS.items()):
        node = node_by_id[nid]
        fill = state_fill(node["state"])
        stroke = "#111" if selected_node == nid else "#9ca3af"
        stroke_width = 3 if selected_node == nid else 1
        lines.append(
            f'<rect x="{x}" y="{y}" width="{NODE_SIZE[0]}" height="{NODE_SIZE[1]}" rx="4" '
            f'fill="{fill}" stroke="{stroke}" stroke-width="{stroke_width}" />'
        )
        lines.append(
            f'<text x="{x + NODE_SIZE[0] / 2}" y="{y + NODE_SIZE[1] / 2}" font-size="11" '
            f'text-anchor="middle" dominant-baseline="middle" fill="#111" font-weight="600">'
            f'{html.escape(node["label"])}</text>'
        )
        lines.append(
            f'<text x="{x + NODE_SIZE[0] / 2}" y="{y + NODE_SIZE[1] + 14}" font-size="10" '
            f'text-anchor="middle" fill="#374151">{html.escape(node["state"])}</text>'
        )

    lines.append("</svg>")
    return "\n".join(lines)


def state_fill(state: str) -> str:
    return {
        "running": "#dbeafe",
        "waiting": "#fef3c7",
        "blocked": "#fee2e2",
        "failed": "#fecaca",
        "complete": "#d1fae5",
    }.get(state, "#e5e7eb")


def render_b_graph_first() -> str:
    """Representation B: graph-first static layout."""
    body_parts = [
        "<h1>Representation B: Graph-First</h1>",
        '<p class="meta">Nodes, edges, and current states are primary. Event details are listed below the graph.</p>',
        svg_graph(),
        "<h2>Node table</h2>",
        render_node_table(),
        "<h2>Edge table</h2>",
        render_edge_table(),
        "<h2>Event log</h2>",
    ]
    for ev in EVENT_LOG:
        body_parts.append(render_event(ev))
    return "\n".join(body_parts)


def render_node_table() -> str:
    rows = []
    for node in NODES:
        rows.append(
            f"<tr>"
            f"<td>{html.escape(node['id'])}</td>"
            f"<td>{html.escape(node['label'])}</td>"
            f"<td>{html.escape(node['role'])}</td>"
            f"<td><span class='state {state_class(node['state'])}'>{html.escape(node['state'])}</span></td>"
            f"<td>{html.escape(node['description'])}</td>"
            f"</tr>"
        )
    return (
        "<table><tr><th>id</th><th>label</th><th>role</th><th>state</th><th>description</th></tr>"
        + "\n".join(rows)
        + "</table>"
    )


def render_edge_table() -> str:
    rows = []
    for edge in EDGES:
        rows.append(
            f"<tr>"
            f"<td>{html.escape(edge['source'])}</td>"
            f"<td>{html.escape(edge['relation'])}</td>"
            f"<td>{html.escape(edge['target'])}</td>"
            f"</tr>"
        )
    return (
        "<table><tr><th>source</th><th>relation</th><th>target</th></tr>"
        + "\n".join(rows)
        + "</table>"
    )


def render_c_hybrid() -> str:
    """Representation C: hybrid (graph overview + per-node conversation + timeline/evidence)."""
    body_parts = [
        "<h1>Representation C: Hybrid (Graph / Node / Timeline)</h1>",
        '<p class="meta">Top: graph overview. Middle: per-node conversation panel. Bottom: timeline and evidence strip.</p>',
        "<h2>Graph overview</h2>",
        svg_graph(),
        "<h2>Per-node conversation panel</h2>",
    ]
    for node in NODES:
        nid = node["id"]
        body_parts.append(
            f"<div class='node-card' id='node-{nid}'>"
            f"<div class='node-header'>{html.escape(node['label'])} <span class='role'>{node['role']}</span> "
            f"<span class='state {state_class(node['state'])}'>{node['state']}</span></div>"
            f"<div class='meta'>{html.escape(node['description'])}</div>"
        )
        node_events = [ev for ev in EVENT_LOG if ev["node"] == nid]
        if node_events:
            for ev in node_events:
                body_parts.append(render_event(ev))
        else:
            body_parts.append("<div class='meta'>No direct events.</div>")
        body_parts.append("</div>")

    body_parts.append("<h2>Timeline / evidence strip</h2>")
    body_parts.append(
        "<table><tr><th>time</th><th>actor</th><th>event</th><th>details</th><th>evidence</th></tr>"
    )
    for ev in EVENT_LOG:
        evidence = html.escape(ev["evidence_ref"] or "—")
        if ev.get("evidence_ref"):
            ei = EVIDENCE_INDEX.get(ev["evidence_ref"], {})
            evidence += f" <span class='evidence'>({html.escape(ei.get('summary', ''))})</span>"
        body_parts.append(
            f"<tr>"
            f"<td>{html.escape(ev['timestamp'])}</td>"
            f"<td>{html.escape(ev['node'])}</td>"
            f"<td>{html.escape(ev['event'])}</td>"
            f"<td>{html.escape(ev['details'])}</td>"
            f"<td>{evidence}</td>"
            f"</tr>"
        )
    body_parts.append("</table>")

    body_parts.append("<h2>Evidence index</h2>")
    body_parts.append(
        "<table><tr><th>evidence_ref</th><th>node</th><th>status</th><th>summary</th></tr>"
    )
    for ref, info in sorted(EVIDENCE_INDEX.items()):
        body_parts.append(
            f"<tr>"
            f"<td>{html.escape(ref)}</td>"
            f"<td>{html.escape(info['node'])}</td>"
            f"<td>{html.escape(info['status'])}</td>"
            f"<td>{html.escape(info['summary'])}</td>"
            f"</tr>"
        )
    body_parts.append("</table>")

    return "\n".join(body_parts)


def main() -> None:
    fixture_path = os.path.join(OUT_DIR, "graph-fixture.json")
    write_json(fixture_path, FIXTURE)

    write_html(
        os.path.join(OUT_DIR, "a-conversation-tabs.html"),
        "ARS-003 Representation A — Conversation Tabs",
        render_a_conversation_tabs(),
    )
    write_html(
        os.path.join(OUT_DIR, "b-graph-first.html"),
        "ARS-003 Representation B — Graph-First",
        render_b_graph_first(),
    )
    write_html(
        os.path.join(OUT_DIR, "c-hybrid.html"),
        "ARS-003 Representation C — Hybrid",
        render_c_hybrid(),
    )

    with open(fixture_path, "rb") as fh:
        digest = hashlib.sha256(fh.read()).hexdigest()

    print(f"graph-fixture.json sha256: {digest}")
    print("emitted:")
    for name in ("graph-fixture.json", "a-conversation-tabs.html", "b-graph-first.html", "c-hybrid.html"):
        print(f"  {os.path.join(OUT_DIR, name)}")


if __name__ == "__main__":
    main()
