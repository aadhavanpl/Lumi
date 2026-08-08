# ADR 0008 — Skills are manipulated as an activation matrix; moves re-materialise

**Status:** Accepted · 2026-08-07

## Context

Moving `code-review` from global scope to the `abakon-abacus` project is six filesystem
operations across three directories, one of which does not exist:

| Before | After |
| --- | --- |
| `~/.agents/skills/code-review` (real dir) | removed |
| `~/.claude/skills/code-review` (relative symlink) | removed |
| `~/.agents/.skill-lock.json` entry | entry removed |
| — | `abakon-abacus/.agents/skills/code-review` (real dir) |
| — | `abakon-abacus/.claude/skills/code-review` (symlink) |
| — | `abakon-abacus/.agents/.skill-lock.json` — **must be created; none exists** |

On the reference machine every canonical directory currently has exactly one symlink, but
the lockfile's `lastSelectedAgents` lists **14 agents**. The design must handle N links per
skill. Links are *relative* (`../../.agents/skills/X`), so they break if either end moves.

## Decisions

### 1. A move re-materialises; it never repoints

The shortcut — `mv` the real directory and rewrite the existing symlink to its new home —
leaves a **global** agent link aimed into a **project** directory, silently making a
project-scoped skill globally active. That is a scope violation and exactly the class of bug
that destroys trust in a management tool.

Move = create at destination, build the destination's link farm for the same agent set, then
tear down the source directory, its links, and its lockfile entry.

### 2. The manipulable model is an activation matrix, not a location

A skill has a grid of **scope × agent** states. The user ticks and unticks; the app computes
the required filesystem operations. "Move" is tick-destination plus untick-source.

Rejected — **location-based only** (drag from global to project): matches the naive file
mental model, but cannot express "active globally for Claude Code *and* in this project for
Cursor" — a state the filesystem already supports. A location UI would force the app to lie
about real states, and would hit that wall the first time a skill is linked for three agents.

**Drag-to-move ships as a fast-follow shortcut** for the common single-destination case,
layered over the matrix rather than replacing it.

### 3. Preview before execute is mandatory

Every write shows the literal list of operations with a Confirm button before anything
touches disk. This is a genuine GUI advantage over a CLI, it is the safety net on V1's only
write path, and it converts "I'm afraid to click this" into "I can see exactly what it does."

## Consequences

- The matrix is an abstraction users must learn. Onboarding must teach it, and the UI should
  still expose real paths for users who want to reason about the filesystem.
- Destination lockfiles must be created where absent — the app writes tracking data the CLI
  never did.
- Operations are multi-step and non-atomic by nature. Needs staged execution with rollback,
  or at minimum a transaction log so a partial failure can be reported precisely rather than
  leaving silent inconsistency.
