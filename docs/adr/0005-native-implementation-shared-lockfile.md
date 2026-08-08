# ADR 0005 — Implement install/update natively; read and write skills.sh's lockfile format

**Status:** Accepted · 2026-08-07

## Context

The app must install, update, move, and remove skills. Three approaches were considered.

The reference machine carries **three separate tracking systems and one hole**:

| Artifact | Tracks | Coverage |
| --- | --- | --- |
| `~/.agents/.skill-lock.json` (v3) | source repo, `sourceUrl`, `skillPath`, `skillFolderHash`, `installedAt`, `updatedAt` | 10 global skills |
| `~/.claude/plugins/installed_plugins.json` | version, `gitCommitSha`, scope, `projectPath` | 26 plugin skills |
| ships with the CLI | — | 5 Codex built-ins |
| ~~*nothing*~~ **`<project>/skills-lock.json` (v1)** | `source`, `sourceType`, `skillPath`, `computedHash` | 7 project skills in `abakon-abacus` |

> **Correction (2026-08-07, same day).** The "7 untracked project skills" claim was wrong.
> They *are* tracked — in `<project>/skills-lock.json`, a **differently named file with a
> different schema at the project root**, not inside `.agents/`. The original search only
> looked in `.agents/`. See [RESEARCH-skills-sh.md](../RESEARCH-skills-sh.md).

## Decision

**Implement natively, but read and write skills.sh's `.skill-lock.json` v3 format.**

Rejected — **shell out to `npx skills`**: requires Node on the user's machine. Shipping a
native Mac app that fails at launch for anyone without `npx` is disqualifying for a paid
product aimed at developers who are not necessarily in the JS ecosystem. Sandboxed apps
also cannot reliably spawn arbitrary user binaries. Inherits their flags, error strings, and
breaking changes.

Rejected — **own manifest format**: two tools writing the same directories with different
bookkeeping produces corrupted state for users who have both.

## Consequences

- No Node dependency. Sandbox-clean. Full control over error handling and progress UI.
- **Ongoing cost:** track `.skill-lock.json` format changes (already at v3) and maintain the
  per-agent path table (skills.sh covers 75+ agents).
- **New responsibility:** correct git fetching, symlink-vs-copy semantics, and atomic writes
  into directories another tool also manages. Concurrency bugs here corrupt user setups.
  Writes must be atomic (temp + rename) and lock-aware.
- ~~**Capability gain the CLI does not have:** the app can write lockfiles where none
  exist.~~ **Withdrawn** — the premise was false. skills.sh already tracks project skills.
  Lumi must instead support **both** lockfile schemas correctly.

## Open implementation question — how to fetch

Shelling out to `git` is tempting (present on this machine, 2.50.1) but on a clean Mac it
triggers the Command Line Tools install prompt, reintroducing the dependency problem in a
different costume.

**Preferred: HTTPS tarball fetch.** `marketplace.json` already provides `url` + pinned `sha`
per plugin, so GitHub's codeload endpoint can supply an exact tree with no external binary
and no libgit2 embed. Verify this covers the non-GitHub `sourceType` values before
committing.
