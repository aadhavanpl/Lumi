# ADR 0007 — V1 scope: local writes, no network

**Status:** Accepted · 2026-08-07

## Context

Three coherent V1 shapes were considered:

| Shape | Contents | Risk |
| --- | --- | --- |
| **A** — read-only | inventory, version detection, drift/shadow detection, update-available badges | cannot corrupt anything; hard to charge for |
| **B** — local writes | A + move + remove | all operations local and reversible |
| **C** — B + apply-update | fetch from recorded origin and write | network, integrity verification, partial writes, lockfile reconciliation |

`update` and `install` share most of their machinery: detecting that `superpowers 6.0.3`
is behind upstream `6.2.0` is cheap and read-only, but *applying* it means fetching a
tarball and writing to disk — roughly 80% of installing.

## Decision

**V1 = shape B.** Inventory, detection, move, remove. No network operations.

## Rationale

B is the largest scope in which **every operation is local and reversible**. Move and remove
need no fetch machinery, no tarball verification, no origin resolution, and no reconciliation
with a remote. They are also the operations where a GUI genuinely beats a CLI — dragging a
skill between scopes is a direct-manipulation problem.

C looks like a small step beyond B but is not: it carries the entire risky surface of
installation with none of the discovery payoff, and once built, full install is just a browse
screen away. **C is not a lean middle ground; it is most of V2 without the reward.**

## Amendment (same day) — "no network" was too strong

The original wording paired "no network operations" with "update-available badges." Those
are contradictory: knowing that `superpowers 6.0.3` is behind upstream `6.2.0` requires
fetching upstream's `plugin.json`.

Investigation showed staleness splits into two kinds. Verified via the GitHub API that
`6fd4507` (the installed `gitCommitSha`) and `896224c` (the sha pinned in the user's own
local `marketplace.json`) are **both commits in `obra/superpowers`, and they differ**:

| Kind | Signal | Network |
| --- | --- | --- |
| **Local drift** | installed sha ≠ local catalog sha | **none** — both values already on disk |
| **Upstream drift** | local catalog ≠ actual upstream | one read-only HTTPS GET |

**Revised rule: V1 performs no network *writes*.** Read-only HTTPS GETs for version
checking are in scope — fetching a JSON manifest carries none of the risk of fetching and
unpacking a tarball into a user's directories.

Local drift detection must work fully offline, since it is real on the reference machine
today and requires nothing but reading two files.

## Consequences

- The app detects that a skill is outdated but cannot fix it. The user is sent to a terminal.
  This is a knowingly accepted rough edge, and the strongest argument for reaching V2 quickly.
- No backend, no server costs, no uptime obligation, no third-party API dependency.
- **Open commercial question:** B is likely not a paid product on its own — "shows your
  skills and lets you move them" is a utility. The compelling intelligence (version, drift,
  shadowing) all sits in A. A plausible path is V1 free to build audience and prove the
  wedge, with money arriving alongside V2's install/update/sync. Not yet decided; flagged
  deliberately rather than assumed.
