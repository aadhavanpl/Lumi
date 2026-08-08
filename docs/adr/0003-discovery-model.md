# ADR 0003 — Hybrid discovery: known paths + user-configured roots + registry hints

**Status:** Accepted · 2026-08-07

## Context

Listing "every skill on the device" requires finding them. The two halves differ:

- **Global / agent-level** paths are bounded and knowable (`~/.claude/skills`,
  `~/.agents/skills`, `~/.codex/skills`, `~/.config/opencode`, …).
- **Project-scoped** skills live in arbitrary directories anywhere on disk.

No reliable project registry exists. Claude Code's `~/.claude/projects/` holds one entry
per project used (9 on the reference machine) but the directory names are lossy — `/` and
`-` both encode to `-`, so `-Users-aadhavan-Developer-abakon-abacus` is ambiguous and
reverses to a path that does not exist. Codex records no cwd at all; its
`session_index.jsonl` carries only `id`, `thread_name`, `updated_at`.

A full-disk scan finds everything but returns 782 `SKILL.md` hits on the reference machine
against ~50 real skills, requires **Full Disk Access**, and permanently disqualifies the
app from the Mac App Store.

## Decision

Three layers:

1. **Known-path table**, shipped with the app and scanned automatically — the per-agent
   global locations. Extended over time via updates as users report agents we missed.
2. **User-configured roots.** The user registers directories (e.g. `~/Developer`) to be
   scanned for project-scoped skills, with bounded depth and ignore rules
   (`node_modules`, `.git`, `.tmp`, `cache`, `vendor_imports`).
3. **Registry hints.** Agent-local registries such as `~/.claude/projects/` are read to
   *suggest* roots at first launch ("found 9 projects you've worked in — add them?"), never
   treated as authoritative. Ambiguous names are resolved by testing candidate paths for
   existence.

## Consequences

- **The completeness claim is "everywhere you told me to look," not "everywhere."** This is
  accepted deliberately. Marketing and empty states must not overstate it.
- The app stays **sandbox-legal**: a single `NSOpenPanel` grant on the Home folder, retained
  as a security-scoped bookmark, covers every path needed. Mac App Store distribution
  remains available, and with it StoreKit for subscriptions.
- The known-path table is a maintenance obligation. skills.sh tracks 75+ agents; parity is
  an ongoing cost, not a one-time build.
- First-launch experience is not an empty screen — registry hints seed it with real
  projects in one click.
