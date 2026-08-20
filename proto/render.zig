// M4-R0 — Zig render kernel prototype (headless).
//
// Input: a JSON document describing a declarative tree of cells.
// Output: ANSI bytes to stdout.
//
// Architecture: Elixir (Temper) builds the JSON tree. Zig owns only
// cell buffer, diff, and ANSI. Zig knows NOTHING about Session,
// Run, Worker, PatchProposal, Verification, Review, HumanDecision,
// Evidence, authority, providers, or graph dependency semantics.
//
// Build:
//   zig build-exe render.zig -O ReleaseSafe
//
// Run:
//   ./render < input.json
//   ./render --diff <previous.json> < input.json
//
// The JSON input shape (intentionally generic):
// {
//   "cols": 80,
//   "rows": 24,
//   "cells": [
//     [{"ch": "H", "style": "bold"}, {"ch": "i", "style": "normal"}],
//     [{"ch": " ", "style": "normal"}]
//   ]
// }

const std = @import("std");

const Style = enum { normal, bold, dim, header, footer, success, warn, error_, muted, accent, border, input_focused, input_unfocused };

const Cell = struct {
    ch: []const u8,
    style: []const u8,
};

const Frame = struct {
    cols: u32,
    rows: u32,
    cells: [][]Cell,
};

const StyleAnsiMap = std.ComptimeStringMap([]const u8, .{
    .{ "normal", "\x1b[0m" },
    .{ "bold", "\x1b[1m" },
    .{ "dim", "\x1b[2m" },
    .{ "header", "\x1b[1;36m" },
    .{ "footer", "\x1b[2m" },
    .{ "success", "\x1b[32m" },
    .{ "warn", "\x1b[33m" },
    .{ "error_", "\x1b[31m" },
    .{ "muted", "\x1b[2m" },
    .{ "accent", "\x1b[1m" },
    .{ "border", "\x1b[2m" },
    .{ "input_focused", "\x1b[1m" },
    .{ "input_unfocused", "\x1b[0m" },
});

fn ansiForStyle(name: []const u8) []const u8 {
    return StyleAnsiMap.get(name) orelse "\x1b[0m";
}

fn renderFrame(frame: Frame, writer: anytype) !void {
    try writer.writeAll("\x1b[H\x1b[?25l");
    var current_style: []const u8 = "\x1b[0m";
    for (frame.cells) |row| {
        for (row) |cell| {
            const style_seq = ansiForStyle(cell.style);
            if (!std.mem.eql(u8, style_seq, current_style)) {
                try writer.writeAll(style_seq);
                current_style = style_seq;
            }
            try writer.writeAll(cell.ch);
        }
        try writer.writeAll("\r\n");
    }
    try writer.writeAll("\x1b[0m");
}

fn diffFrame(prev: Frame, next: Frame, writer: anytype) !void {
    // Minimal diff: emit full frame if dimensions or any cell differ.
    // A production version would emit per-cell ANSI moves.
    var any_diff = false;
    if (prev.cols != next.cols or prev.rows != next.rows) {
        any_diff = true;
    } else {
        outer: for (next.cells, 0..) |row, r| {
            for (row, 0..) |cell, c| {
                if (r >= prev.cells.len or c >= prev.cells[r].len) {
                    any_diff = true;
                    break :outer;
                }
                const pcell = prev.cells[r][c];
                if (!std.mem.eql(u8, pcell.ch, cell.ch) or !std.mem.eql(u8, pcell.style, cell.style)) {
                    any_diff = true;
                    break :outer;
                }
            }
        }
    }

    if (any_diff) {
        try writer.writeAll("DIFF=true\n");
        try renderFrame(next, writer);
    } else {
        try writer.writeAll("DIFF=false\n");
    }
}

fn parseFrame(allocator: std.mem.Allocator, input: []const u8) !Frame {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, input, .{});
    defer parsed.deinit();

    const root = parsed.value;
    const obj = root.object;

    const cols = @as(u32, @intCast(obj.get("cols").?.integer));
    const rows = @as(u32, @intCast(obj.get("rows").?.integer));
    const cells_json = obj.get("cells").?.array;

    var cells = try allocator.alloc([]Cell, rows);
    for (cells_json.items, 0..) |row_value, r| {
        const row_array = row_value.array;
        var row_cells = try allocator.alloc(Cell, cols);
        for (row_array.items, 0..) |cell_value, c| {
            if (c >= cols) break;
            const cell_obj = cell_value.object;
            row_cells[c] = Cell{
                .ch = try allocator.dupe(u8, cell_obj.get("ch").?.string),
                .style = try allocator.dupe(u8, cell_obj.get("style").?.string),
            };
        }
        // Pad short rows.
        var c: usize = row_array.items.len;
        while (c < cols) : (c += 1) {
            row_cells[c] = Cell{ .ch = " ", .style = "normal" };
        }
        cells[r] = row_cells;
    }

    return Frame{ .cols = cols, .rows = rows, .cells = cells };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    defer bw.flush() catch {};
    const out = bw.writer();

    // Simplified: read all of stdin, parse as a single frame, render
    // to stdout. No CLI args — we use a separate --diff helper.
    const stdin = std.io.getStdIn().reader();
    const input = try stdin.readAllAlloc(allocator, 10 * 1024 * 1024);
    const frame = try parseFrame(allocator, input);
    try renderFrame(frame, out);
}
