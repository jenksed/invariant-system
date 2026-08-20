#!/usr/bin/env python3
"""M4-R0 fixture B: minimal M4 Graph (rendering only).

Visualization of the accepted M3 lifecycle as a graph. No real
graph semantics; just a visual representation for testing the
renderer.

Layout (rows x cols grid):
  Row 0-1:  header
  Row 2-3:  Engineering Objective node
  Row 4:    ↓ edge
  Row 5-6:  Worker node
  Row 7:    ↓
  Row 8-9:  Patch Proposal node
  Row 10:   ↓
  Row 11-12: Verification | Review (side by side)
  Row 13:   ↓
  Row 14-15: Human Decision node
  Row 16:   ↓
  Row 17-18: Governed Apply node
  Row 19:   ↓
  Row 20-21: Evidence node
  Row 22-23: footer
"""
import json
import sys


def node(label, row_start, cols, style="normal"):
    """Render a centered node box at row_start (2 rows tall)."""
    row_a = ("┌" + "─" * (len(label) + 2) + "┐").center(cols)
    row_b = (f"│ {label} │").center(cols)
    return [
        [{"ch": c, "style": style} for c in row_a],
        [{"ch": c, "style": style} for c in row_b],
    ]


def edge(row_idx, cols, style="dim"):
    return [[{"ch": c, "style": style} for c in "│".center(cols)]]


def build(cols, rows, change_at=None):
    cells = []
    cells.append([{"ch": c, "style": "header"} for c in "M4 Graph — M3 Lifecycle".center(cols).ljust(cols, " ")])
    cells.append([{"ch": " ", "style": "normal"} for _ in range(cols)])

    rows_used = 2

    def append_node(label, style="normal"):
        nonlocal rows_used
        if rows_used + 2 > rows - 2:
            return
        for r in node(label, rows_used, cols, style):
            cells.append(r)
            rows_used += 1

    def append_edge():
        nonlocal rows_used
        if rows_used + 1 > rows - 2:
            return
        cells.append(edge(rows_used, cols)[0])
        rows_used += 1

    append_node("Engineering Objective", "accent")
    append_edge()
    append_node("Worker (MiniMax)", "normal")
    append_edge()
    append_node("Patch Proposal", "normal")
    append_edge()
    if rows_used + 3 <= rows - 2:
        side_a = "Verification"
        side_b = "Review"
        row_a = (side_a + "    " + side_b).center(cols)
        row_b = ("(PASS)    (APPROVE)").center(cols)
        cells.append([{"ch": c, "style": "normal"} for c in row_a])
        rows_used += 1
        cells.append([{"ch": c, "style": "muted"} for c in row_b])
        rows_used += 1
        append_edge()
    append_node("Human Decision (ACCEPT)", "success")
    append_edge()
    append_node("Governed Apply", "normal")
    append_edge()
    append_node("Patch Evidence", "normal")

    # Pad to rows-1 with blank.
    while len(cells) < rows - 1:
        cells.append([{"ch": " ", "style": "normal"} for _ in range(cols)])
    # Footer at last row.
    cells.append([{"ch": c, "style": "footer"} for c in "↑↓ navigate | ENTER inspect | q quit".ljust(cols, " ")])

    # Optional: simulate a change at a specific node label.
    if change_at is not None:
        for r, row in enumerate(cells):
            for c, cell in enumerate(row):
                if change_at in (cells[r][c].get("ch", "") + (cells[r + 1][c].get("ch", "") if r + 1 < len(cells) else "")):
                    if cells[r][c]["style"] != "footer" and cells[r][c]["style"] != "header":
                        cells[r][c]["style"] = "success"
                    break

    return {"cols": cols, "rows": rows, "cells": cells}


if __name__ == "__main__":
    cols = int(sys.argv[1]) if len(sys.argv) > 1 else 80
    rows = int(sys.argv[2]) if len(sys.argv) > 2 else 24
    change = sys.argv[3] if len(sys.argv) > 3 else None
    print(json.dumps(build(cols, rows, change)))
