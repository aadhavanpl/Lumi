# ADR 0001 — The wedge is unified inventory, not a store frontend

**Status:** Accepted · 2026-08-07

## Context

The initial framing was "a native UI for skills.sh." Research killed that framing:

- skills.sh is free, open source, made by Vercel, supports 75+ agents, and already ships
  `add` / `remove` / `update` / `list` / `find`, project vs global scope, per-agent
  targeting, and symlink-vs-copy install.
- That is the entire proposed V1 feature list, already built and free.
- A GUI over a free CLI has near-zero switching cost and can be neutralised by the
  incumbent shipping their own UI.

Measurement of the reference machine found the actual unmet need. ~50 real skills spread
across: `~/.agents/skills` (10), `~/.claude/skills` (same 10, symlinked),
`~/.codex/skills/.system` (5, hidden), three project directories (9), and two plugins
(26). **Roughly half the inventory lives inside plugins and is invisible to any directory
listing** — including to `npx skills list`, which has no knowledge of the expo plugin's
12 skills.

A naive `find` for `SKILL.md` returns 782 hits, ~95% of them cache noise
(`~/.codex/.tmp` alone holds 608 files / 443 MB).

## Decision

The product is the **inventory and control layer for skills on a machine** — every skill,
every agent, every scope, with provenance. Downloading from the internet is one action
inside it, not the product.

## Consequences

- Competition is not skills.sh; it is "no tool does this."
- Cross-agent support is mandatory, not a nice-to-have — single-agent scope forfeits the
  wedge.
- The hard problem is **classification and identity**, not UI. Distinguishing 50 real
  skills from 782 filesystem hits is the engineering work.
- Correctness features (pinning, diff-before-update, provenance) are natural extensions;
  a store frontend would not have earned them.
