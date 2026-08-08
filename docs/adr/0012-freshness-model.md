# ADR 0012 — Scan on launch with manual refresh

**Status:** Accepted · 2026-08-07

## Context

How the inventory stays current. Measured on the reference machine:

| Watch strategy | Directories under watch |
| --- | --- |
| Naive FSEvents on `~/Developer` | **14,359**, including **1.9 GB** of `node_modules` across 4 projects |
| Precise: known skill directories only | **10** |

Watching a registered root naively would wake the app on every `npm install`, build, and
`git checkout`.

## Decision

**V1 scans on launch and offers a manual refresh.** No filesystem watching.

## Consequences

- The inventory goes stale if a skill is installed via CLI while the window is open. The
  user refreshes. Acceptable for V1, and consistent with the lean scope of ADR 0007.
- No FSEvents plumbing, no debouncing, no background-activity power cost.
- Scan performance must be good enough that manual refresh feels instant — the bounded
  discovery model of ADR 0003 makes this achievable.

## Deferred to V2

Precise watching (see BACKLOG). Watch the ~10 known skill directories and the handful of
state files, plus a bounded rescan on app activation to catch newly created locations.
