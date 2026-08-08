# ADR 0013 — Copy vs move semantics, and lockfile writes without a sidecar

**Status:** Accepted · 2026-08-07

## Context

ADR 0008 modelled *move* only. The more common real need is **copy** — "I use this skill in
project X and want it in Y too." The activation matrix already expresses both: ticking a new
scope while the old stays ticked is a copy; unticking the old makes it a move.

## Decision 1 — copy across scopes, symlink within a scope

| Operation | Mechanism |
| --- | --- |
| Fan out to more agents **within** one scope | symlink into that scope's `.agents/skills/` |
| Add to a **different** scope (global→project, project→project) | **copy** |

This is forced by git, not chosen for ergonomics. An existing link on the reference machine:

```
abakon-abacus/.claude/skills/grill-me -> ../../.agents/skills/grill-me
```

is *relative* and stays inside the repo — it survives commit and clone. A link from a project
out to `~/.agents/skills/grill-me` escapes the repo and becomes a **dangling symlink for
every teammate who clones**. Cross-scope therefore has to duplicate.

## Decision 2 — write their lockfile; keep no sidecar for skill metadata

On copy/move/remove: add or delete entries in `.skill-lock.json`, creating the file with
`"version": 3` if absent. Fields are copied verbatim from the source entry — **never
synthesised**. Top-level `dismissed` and `lastSelectedAgents` are UI preferences and are
omitted rather than invented.

**A lineage sidecar was proposed and rejected.** The proposal was to record parent path and
copy timestamp in our own store so drift detection could be exact rather than name-based.

This was over-engineering: **the lockfile already carries the lineage.** Two skills sharing
`source` + `skillPath` are provably the same upstream skill — a stronger and cheaper
relationship than "copied from path P at time T", requiring no second store and no
reconciliation.

App preferences (registered workspace roots, window state) live in normal user defaults.
That is app config, not skill metadata, and is not a sidecar in the rejected sense.

## Consequences and accepted caveats

- **Untracked sources produce untracked copies.** The 7 skills in `abakon-abacus` have no
  lockfile entries, so copying one writes *nothing*. Correct behaviour: fabricating `source`
  and `sourceUrl` risks breaking `npx skills update` for that user. Coverage stays patchy
  exactly where it is already patchy.
- **`skillFolderHash` is an upstream reference, not a local content hash**, so a
  copied-then-edited skill carries an entry claiming an upstream identity it no longer
  matches. Inherited from skills.sh rather than caused by us. Mitigation needs no stored
  state: two copies sharing an origin whose contents differ means one has drifted — computed
  live at scan time, which is how the `grill-me` divergence was found.
- **Creating `<project>/.agents/.skill-lock.json` writes a new file into a git repo** and
  will appear in `git status`. Must never be a surprise; ADR 0008's mandatory preview lists
  file creations, which covers it.
## Correction (2026-08-07, same day) — resolved by reading `skills@1.5.22`

The inferred project lockfile path was **wrong on filename, location, and schema**:

| Assumed | Actual |
| --- | --- |
| `<project>/.agents/.skill-lock.json` | **`<project>/skills-lock.json`** |
| same schema as global (v3) | **separate schema, version 1** |
| `skillFolderHash` (git tree SHA) | **`computedHash`** (SHA-256 of content) |

Consequences for this ADR:

- **"Untracked sources produce untracked copies" is largely moot.** The 7 `abakon-abacus`
  skills are tracked; there was simply a second lockfile the original survey never looked for.
- **Lumi must implement two schemas, not one**, and must not copy fields between them blindly
  — the global lock has `sourceUrl`, `installedAt`, `updatedAt`, and `pluginName` that the
  project schema does not define.
- **A cross-scope copy is a schema translation, not a field copy.** Moving global → project
  means dropping fields the project schema lacks and *computing* a fresh `computedHash` from
  the destination contents, since the source's git tree SHA is not convertible.
- The core decision stands: write their formats, keep no sidecar. Lineage still comes free
  from `source` + `skillPath` matching across both schemas.

See [RESEARCH-skills-sh.md](../RESEARCH-skills-sh.md) for the full verified contract.
