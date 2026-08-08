# Lumi V1 — Specification

**Status:** Draft · 2026-08-07 · Derived from ADRs 0001–0015

---

## 1. What Lumi is

A native macOS app that lists **every agent skill installed on the machine** — across every
agent, every scope, and every origin — and lets the user reorganise them.

Today no tool can do this. `npx skills list` cannot see plugin-provided skills; nothing
surfaces project-scoped skills across projects; nothing reports that two copies of the same
skill have diverged.

### Non-goals for V1

| Not in V1 | Why | Reference |
| --- | --- | --- |
| Installing skills from the internet | Lean scope; shares ~80% of its machinery with update | ADR 0007 |
| Applying updates | Same | ADR 0007 |
| Browsable catalog / search | skills.sh API is Vercel-OIDC gated (HTTP 401) | BACKLOG |
| Cleanup / orphan removal | Deleting live agent caches is a trust-destroying failure | BACKLOG |
| Org / team registry | Requires a backend, changes the economics | BACKLOG |
| Live filesystem watching | Scan-on-launch is sufficient | ADR 0012 |
| Windows | Symlink privileges break the install model | ADR 0006 |

**Guard rail:** Lumi is an inventory browser. Drift and staleness are *annotations on the
inventory*, not the product's identity. It is not a security or auditing tool, and no feature
may reshape it into one without revisiting ADR 0011.

---

## 2. Domain model

- **Skill** — a directory containing `SKILL.md`. The atom.
- **Plugin** — a versioned bundle containing skills plus hooks/agents/MCP servers. The unit
  of install/update/remove for anything it contains.
- **Marketplace** — a git repo whose `marketplace.json` catalogues plugins.
- **Origin** — what put a skill on disk, and therefore which actions are legal on it.
- **Scope** — global/user, or project.
- **Agent** — a consumer of skills, with its own directory conventions.

Full definitions in [GLOSSARY.md](GLOSSARY.md).

### Legal actions by origin

| Origin | Version | Move | Remove | Notes |
| --- | --- | --- | --- | --- |
| Plugin | semver | ✗ | ✗ | managed at plugin level; disabled actions must explain why |
| Repo install | git sha / content hash | ✓ | ✓ | |
| Hand-written | none | ✓ | ✓ | |
| Agent built-in | ships with CLI | ✗ | ✗ | |

---

## 3. Discovery

Three layers (ADR 0003):

1. **Known-path table** — bundled data file, scanned automatically. V1 ships **only verified
   agents**: claude-code, codex, cursor, opencode, github-copilot (ADR 0014).
   **All paths are environment-overridable** (`CLAUDE_CONFIG_DIR`, `CODEX_HOME`,
   `XDG_CONFIG_HOME`) and must be resolved at scan time, never hardcoded.
2. **User-configured roots** — directories registered for project scanning. Bounded depth,
   skipping `node_modules`, `.git`, `dist`, `build`, `__pycache__`.
3. **Registry hints** — `~/.claude/projects/` suggests roots at first launch. Names are lossy
   (`/` and `-` both encode to `-`), so candidates must be validated by existence, never
   trusted.

**Completeness claim is "everywhere you told me to look," not "everywhere."** Empty states and
marketing must not overstate this.

Users can add or override agent definitions. **User-supplied paths are untrusted input** —
validate before scanning, and never let them direct writes outside their declared scope.

---

## 4. Sources of truth to parse

| File | Schema | Contents |
| --- | --- | --- |
| `~/.agents/.skill-lock.json` (or `$XDG_STATE_HOME/skills/…`) | v3 | global installs; `skillFolderHash` = **git tree SHA**, 40 hex |
| `<project>/skills-lock.json` | v1 | project installs; `computedHash` = **SHA-256 content**, 64 hex |
| `~/.claude/plugins/installed_plugins.json` | — | plugin version, `gitCommitSha`, scope, `projectPath` |
| `~/.claude/settings.json` → `enabledPlugins` | — | *enabled* state, independent of installed |
| `<marketplace>/.claude-plugin/marketplace.json` | — | catalogue with pinned source shas |

Both lockfile schemas must be supported. They are **not** interchangeable — see
[RESEARCH-skills-sh.md](RESEARCH-skills-sh.md).

---

## 5. Identity, hashing, and detection

### Identity
Resolve symlinks to real paths **before** any comparison. All 10 entries in `~/.claude/skills`
are symlinks into `~/.agents/skills` — one skill at two paths, not two skills. Skipping this
produces ten fabricated duplicates on first launch.

Two skills are the same upstream skill when `source` + `skillPath` match.

### Content hashing
Reimplement `computeSkillFolderHash` exactly (RESEARCH §3): SHA-256 over sorted
`relativePath + fileBytes`, skipping `.git` and `node_modules`.

> ⚠️ **Sort with ICU collation, matching JS `localeCompare` — not code-point order.**
> Code-point sorting reproduced only 3 of 7 entries on the reference machine; correct
> collation reproduced 6 of 7. Getting this wrong reports most multi-file skills as modified
> when they are not.

### Detection rules

| Signal | Rule | Network |
| --- | --- | --- |
| **Local drift** | recomputed hash ≠ recorded `computedHash` | none |
| **Plugin catalog drift** | installed `gitCommitSha` ≠ catalog pinned sha | none |
| **Shadowing** | same name resolving differently per context, following agent resolution order | none |
| **Divergence** | distinct real copies sharing `source`+`skillPath` with different content | none |
| **Upstream staleness** | local catalog ≠ upstream | one read-only GET |

**Wording discipline:** the install-time hash is computed from the temp clone, not the
installed folder, so a mismatch does not prove user editing. Report *"content differs from
what the lockfile records"* — never *"you modified this."*

---

## 6. Write operations

Only two: **move** and **remove**. Plus **copy**, which falls out of the matrix.

### Mechanism (ADR 0013)

| Operation | Mechanism | Why |
| --- | --- | --- |
| Fan out to more agents **within** a scope | relative symlink into that scope's `.agents/skills/` | stays inside the repo, survives clone |
| Add to a **different** scope | **copy** | a link would escape the project and dangle for teammates |

A move **re-materialises** — create at destination, build the destination link farm, tear down
the source. Never repoint an existing link, which would leave a global link aimed into a
project.

### Lockfile writes
Add/remove entries in the appropriate schema. **A cross-scope copy is a schema translation:**
drop fields the project schema lacks, and *compute* a fresh `computedHash` from destination
contents — the global git tree SHA is not convertible.

Preserve project-lock conventions: sorted keys, repo-relative `local` sources.

### Safety
- **Preview before execute is mandatory.** Show the literal operation list with a Confirm
  button. This is V1's only write path.
- Writes are atomic (temp + rename).
- Removals go to **Trash** via `NSFileManager.trashItem`, never `unlink`.
- Creating `<project>/skills-lock.json` adds a file to a git repo — it must appear in the
  preview, never as a surprise.
- Operations are multi-step; keep a transaction log so partial failure is reported precisely.

---

## 7. Interface

Three-column `NavigationSplitView` (ADR 0011).

**Sidebar:** All Skills *(default)*, By Scope, By Agent, Plugins, Needs Attention.

**List:** name, origin badge, scope, agent chips, version where real, quiet status chips.

**Detail:** description, origin, real paths, **activation matrix** (scope × agent), drift diff,
plugin info where applicable.

The matrix shows **detected agents only**, with explicit user-added agents included.
Disabled actions always state their reason.

Launch lands on the full inventory regardless of health. No alarmism.

---

## 8. Build order

Each stage is independently testable against the reference machine.

1. **Agent registry** — data file, env-var resolution, user overrides
2. **Scanner** — discovery layers, skip rules, symlink resolution → raw inventory
3. **Parsers** — both lockfile schemas, `installed_plugins.json`, `settings.json`, marketplaces
4. **Hash engine** — `computeSkillFolderHash` with ICU collation, verified against the 7
   `abakon-abacus` entries as a fixture
5. **Detection** — drift, shadowing, divergence, catalog staleness
6. **Read-only UI** — sidebar, list, detail. *Shippable and useful at this point.*
7. **Write engine** — plan → preview → execute → verify, with trash and rollback
8. **Matrix UI** — wired to the write engine
9. **Packaging** — Developer ID, notarization, Sparkle, DMG, Homebrew cask

Stage 6 is a natural internal milestone: the app is genuinely useful before any write code
exists.

### Acceptance fixtures (verified on the reference machine, 2026-08-07)

- Resolves `~/.claude/skills` symlinks so its 10 entries are **not** double-counted
- Surfaces the 26 plugin-provided skills that no directory listing reveals
- Reports `superpowers 6.0.3` installed vs `896224c` pinned in the local catalog — **offline**
- Flags `grill-me` as shadowed in `abakon-abacus` and diverged from the global copy
- Flags `next-best-practices` as drifted, and **does not** flag the other six
- Ignores 608 `SKILL.md` files under `~/.codex/.tmp`

---

## 9. Open items

| Item | Status |
| --- | --- |
| `skills-lock.json` schema stability | v1 vs global v3 — re-verify per skills.sh release |
| ICU collation parity with `localeCompare` | needs a Swift fixture test against the 7 known entries |
| Agent resolution order per agent | required for shadowing; verified only for claude-code |
| Codex `.system` skills | decide whether hidden built-ins are listed |
| Tip jar mechanism | GitHub Sponsors vs alternatives (ADR 0009) |
| Domain + bundle identifier | exact-match domain unavailable (ADR 0015) |
| Trademark | pending LUMI mark in software services class (ADR 0015) |
