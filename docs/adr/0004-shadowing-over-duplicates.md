# ADR 0004 — Detect shadowing and drift, not "duplicates"

**Status:** Accepted · 2026-08-07

## Context

Proposed feature: flag duplicate skills installed at both global and project scope, and
compare contents to distinguish true copies from modified ones.

Measurement on the reference machine sharpened this considerably.

**Naive name-matching produces false positives.** All 10 entries in `~/.claude/skills` are
symlinks into `~/.agents/skills`. That is one skill visible at two paths, not two skills.
Without resolving symlinks first, the app's first screen shows ten fabricated duplicates.

**The one real duplicate is interesting for a different reason.** `grill-me` exists at two
distinct real paths and the contents have diverged:

| Path | State |
| --- | --- |
| `~/.agents/skills/grill-me` | current — a thin delegator to `/grilling` |
| `~/Developer/abakon-abacus/.agents/skills/grill-me` | fork from 2026-06-13, full inline text |

Inside `abakon-abacus`, `.claude/skills/grill-me` symlinks to the **project** copy. So
`/grill-me` in that project silently resolves to the June version while every other context
gets the current one. Nothing anywhere surfaces this.

## Decision

The feature is **shadow and drift detection**, not duplicate detection.

1. **Resolve symlinks to real paths before any comparison.** Group by resolved inode/path,
   not by name.
2. For each skill name, compute **which copy actually wins** in each context, following the
   agent's own resolution order (project scope shadows global).
3. Compare contents of genuinely distinct copies via a **directory-tree hash** covering all
   files, not just `SKILL.md` — skills carry `references/`, `scripts/`, and assets.
4. Report as: *"in project X, `/name` resolves to a copy that diverged from your global one
   on DATE"*, with a diff view.

## Consequences

- "You have a duplicate" is a weak notification. "This project runs a stale fork of a skill
  you've since updated" is the useful one. Framing drives the UI.
- **Scope guard:** this is an *annotation on the inventory*, not the product's identity. The
  app is a listing of every skill on the machine; drift and shadowing are facts shown about
  those skills. It is not a security or auditing tool, and the UI must not drift into
  presenting itself as one. See ADR 0011.
- Requires modelling each agent's skill resolution order — real research per agent, and a
  source of wrongness if guessed.
- Directory-tree hashing must have a defined normalisation (sorted paths, excluded
  `.DS_Store` / `.git`) or it will report spurious drift.

## Related gap

~~`.skill-lock.json`'s `skillFolderHash` does not match any local content hash tried. Nothing
on the machine currently detects that a user hand-edited an installed skill. Storing our own
local-content hash closes a gap no existing tool covers.~~

**Corrected 2026-08-07 after reading `skills@1.5.22`:**

- The **global** lock's `skillFolderHash` is a **git tree SHA** (40 hex) — an upstream
  reference, so it genuinely cannot detect local edits.
- The **project** lock (`<project>/skills-lock.json`, a file missed in the original survey)
  stores `computedHash` — a **SHA-256 content hash** (64 hex). Local drift on project skills
  *is* already detectable, and Lumi should recompute and compare rather than invent a scheme.

**Verified on the reference machine:** `next-best-practices` in `abakon-abacus` genuinely
differs from its recorded hash. An earlier count of "4 drifted" was an artifact of using
code-point sorting instead of `localeCompare`. See
[RESEARCH-skills-sh.md](../RESEARCH-skills-sh.md) §3 for the algorithm and the sorting trap.
