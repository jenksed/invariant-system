#!/usr/bin/env python3
"""M4-R0 fixture A: existing Temper-style screen.

Represents a small Temper screen well enough to test the Zig
renderer with text, panels, multiline input, and resize.
"""
import json
import sys


def build(cols, rows, multiline_input_lines=None):
    cells = []
    # Row 0: header banner.
    header = ("Temper Workbench " + "-" * (cols - 19))[:cols]
    cells.append([{"ch": c, "style": "header"} for c in header.ljust(cols, " ")])
    # Row 1: blank
    cells.append([{"ch": " ", "style": "normal"} for _ in range(cols)])
    # Row 2: status
    status = "Session: ses_demo123    Run: running    State: WORKING"
    cells.append([{"ch": c, "style": "muted"} for c in status.ljust(cols, " ")])
    # Row 3: blank
    cells.append([{"ch": " ", "style": "normal"} for _ in range(cols)])
    # Row 4: panel border top
    border = "+" + "-" * (cols - 2) + "+"
    cells.append([{"ch": c, "style": "border"} for c in border.ljust(cols, " ")])
    # Rows 5..rows-3: panel body
    multiline_input_lines = multiline_input_lines or ["single line input"]
    for r in range(5, rows - 2):
        if r - 5 < len(multiline_input_lines):
            line = multiline_input_lines[r - 5]
            content = f"| {line}".ljust(cols - 1) + "|"
        else:
            content = "|" + " " * (cols - 2) + "|"
        cells.append([{"ch": c, "style": "normal"} for c in content.ljust(cols, " ")])
    # Row rows-2: panel border bottom
    cells.append([{"ch": c, "style": "border"} for c in border.ljust(cols, " ")])
    # Row rows-1: footer
    footer = "q quit | ? help | ENTER submit"
    cells.append([{"ch": c, "style": "footer"} for c in footer.ljust(cols, " ")])

    return {"cols": cols, "rows": rows, "cells": cells}


if __name__ == "__main__":
    cols = int(sys.argv[1]) if len(sys.argv) > 1 else 80
    rows = int(sys.argv[2]) if len(sys.argv) > 2 else 24
    multiline = sys.argv[3:] if len(sys.argv) > 3 else None
    print(json.dumps(build(cols, rows, multiline)))
