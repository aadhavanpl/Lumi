# skills.sh on-disk contracts — verified reference

Derived from the shipped npm package `skills@1.5.22` (`dist/cli.mjs`), cross-checked against
the reference machine on 2026-08-07. This is the implementation contract Lumi must honour.

Re-verify against the current package version before implementing; several of these details
are undocumented and may change.

---

## 1. There are TWO lockfiles, with different names, locations, and schemas

| | Global | Project |
| --- | --- | --- |
| **Path** | `$XDG_STATE_HOME/skills/.skill-lock.json`, else `~/.agents/.skill-lock.json` | `<project-root>/skills-lock.json` |
| **Filename** | `.skill-lock.json` (leading dot) | `skills-lock.json` (**no** leading dot) |
| **Location** | `~/.agents/` | **project root** — *not* inside `.agents/` |
| **Schema version** | `3` | `1` |
| **Top-level keys** | `version`, `skills`, `dismissed`, `lastSelectedAgents` | `version`, `skills` only |
| **Hash field** | `skillFolderHash` | `computedHash` |

Source: `LOCAL_LOCK_FILE = "skills-lock.json"` (line ~899), `LOCK_FILE = ".skill-lock.json"`
(line ~3477), `getLocalLockPath(cwd) = join(cwd, LOCAL_LOCK_FILE)`.

### Global entry (v3)

```json
"grill-me": {
  "source": "mattpocock/skills",
  "sourceType": "github",
  "sourceUrl": "https://github.com/mattpocock/skills.git",
  "skillPath": "skills/productivity/grill-me/SKILL.md",
  "skillFolderHash": "8320e7b87f7b208f50ce165b1dd43d1e93c8e801",
  "pluginName": "mattpocock-skills",
  "installedAt": "2026-06-25T16:51:13.669Z",
  "updatedAt": "2026-07-12T12:44:37.642Z"
}
```

### Project entry (v1) — fewer fields, different hash

```json
"frontend-design": {
  "source": "anthropics/skills",
  "sourceType": "github",
  "skillPath": "skills/frontend-design/SKILL.md",
  "computedHash": "4eabc66183767153e404b39d1b839b1c37f2d82d86f0a0d7e880a579d8d62336"
}
```

No `sourceUrl`, no `installedAt`/`updatedAt`, no `pluginName`.

Project locks sort keys on write and rewrite `sourceType: "local"` entries to
**repo-relative** paths (`getPortableLocalSource`) so the file stays portable across clones.
Lumi must preserve this behaviour when writing.

---

## 2. The hash field holds two incompatible algorithms — discriminate by length

| Length | Field | Meaning |
| --- | --- | --- |
| **40 hex** | `skillFolderHash` | **git tree SHA** of the skill folder, read from the GitHub tree API. *Not* a content hash. |
| **64 hex** | `computedHash` | **SHA-256 content hash** computed locally. |

`getSkillFolderHashFromTree()` strips a trailing `SKILL.md` from `skillPath` and looks up the
matching `type: "tree"` entry's `sha`. That is why the global lock's hashes never match any
local content digest — verified earlier by testing `git hash-object` and plain SHA-1 against
`find-skills`, both of which failed.

All 10 global entries on the reference machine are 40 hex. All project entries are 64 hex.

---

## 3. `computeSkillFolderHash` — verified algorithm

```
files = recursive walk of the skill directory
        skipping any directory named ".git" or "node_modules"
sort files by relativePath using JS String.localeCompare
h = sha256()
for each file, in order:
    h.update(utf8(relativePath))     # POSIX separators, "\" → "/"
    h.update(rawFileBytes)
return h.digest("hex")
```

**Verified:** reproduced 6 of 7 project entries byte-exactly on the reference machine.

### ⚠️ The sorting trap — this will cause false drift reports

The sort uses **`localeCompare`**, which is ICU collation, **not** byte or code-point order.
They disagree whenever a skill mixes cases across filenames — e.g. `SKILL.md` alongside
`references/…`:

- code-point order: `SKILL.md` first (`S` = 0x53 < `r` = 0x72)
- `localeCompare` order: `references/…` first (case-insensitive primary strength)

A naïve code-point sort matched only **3 of 7** entries. Switching to case-insensitive
primary ordering matched **6 of 7**. The remaining mismatch (`next-best-practices`) is
genuine content drift — no collation variant reproduces it.

**In Swift:** use ICU-backed collation (`String.compare(_:options:range:locale:)`), never `<`.
Get this wrong and Lumi reports most multi-file skills as modified when they are not.

---

## 4. Directory tables

**Project skill directories** (`AGENT_PROJECT_SKILL_DIRS`, 27 entries):

```
.agents/skills   .claude/skills   .cline/skills      .codebuddy/skills  .codex/skills
.commandcode/…   .continue/…      .github/skills     .goose/skills      .grok/skills
.iflow/…         .junie/…         .kilocode/…        .kimchi/…          .kiro/skills
.minimax/…       .mux/skills      .neovate/…         .opencode/…        .openhands/…
.pi/skills       .qoder/skills    .roo/skills        .trae/skills       .windsurf/skills
.zcode/skills    .zencoder/skills
```

**Scan skip list** (`SKIP_DIRS`): `node_modules`, `.git`, `dist`, `build`, `__pycache__`.

**Global directories** — a 76-agent table with a `globalSkillsDir` per agent. The four
relevant to V1 (ADR 0014), with their environment overrides:

| Agent | Global skills dir | Override |
| --- | --- | --- |
| claude-code | `$CLAUDE_CONFIG_DIR/skills` else `~/.claude/skills` | `CLAUDE_CONFIG_DIR` |
| codex | `$CODEX_HOME/skills` else `~/.codex/skills` | `CODEX_HOME` |
| cursor | `~/.cursor/skills` | — |
| opencode | `$XDG_CONFIG_HOME/opencode/skills` else `~/.config/opencode/skills` | `XDG_CONFIG_HOME` |
| github-copilot | `~/.copilot/skills` | — |

**Every path is environment-overridable.** Hardcoding `~/.claude/skills` is wrong for anyone
who sets `CLAUDE_CONFIG_DIR`. Resolve the variables at scan time.

---

## 5. Caution on interpreting drift

At install time the hash is computed from the **temp clone** —
`computeSkillFolderHash(join(tempDir, dirname(skillPath)))` — not from the installed
destination. A mismatch therefore does not prove the user edited anything.

Lumi must report this factually: *"content differs from what the lockfile records"*, never
*"you modified this skill."*
