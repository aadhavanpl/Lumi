# Inventory Builder — design

**Date:** 2026-08-08 · **Status:** Approved, pending implementation

## Context

SPEC §8's stage 6 ("Read-only UI") assumed the four stages before it (agent registry, scanner,
parsers, hash engine, detection — stages 1–5, all merged) could feed a SwiftUI view directly.
They can't: nothing yet joins `DiscoveredSkill` (scanner) with the lockfile/plugin/marketplace
models (parsers) into one per-skill record, and nothing parses `SKILL.md`'s own frontmatter for
`name`/`description`. This doc designs that correlation layer — the **Inventory Builder** — as
its own PR, before the UI PR that will consume it.

Full context: `docs/SPEC-v1.md` §2 (domain model), §3 (discovery), §5 (detection),
`docs/adr/0011-information-architecture.md`.

## Scope decisions (confirmed in brainstorming)

- **Global skills only.** Project-scope workspace registration is a separate follow-up — it
  needs its own persistence and settings UI, not just display wiring.
- **Frontmatter: `name` + `description` only.** YAGNI — nothing planned reads the rest of the
  GLOSSARY's frontmatter field list yet.
- **Status signals for this slice:** plugin catalog drift (stage 5's `PluginCatalogDriftDetector`)
  plus a new installed-vs-enabled check. Local drift, shadowing, and divergence all need
  project-scope data they won't have yet, so the builder doesn't call them this round — wiring
  them in is trivial once project scope exists, but there's no real input to test against today.
- **The UI itself is a separate PR/design cycle**, sketched at the end of this doc but not
  finalized — its shape depends on what `SkillInventoryItem` actually looks like once built.

## Components

### `SkillFrontmatter` — `Lumi/Parsers/SkillFrontmatter.swift`

Parses `SKILL.md`'s YAML frontmatter (between `---` delimiters) for `name` and `description`
only. Missing file, missing frontmatter block, or fields absent are not errors — the caller
falls back to the directory name for `name`, and `description` stays `nil`.

```swift
struct SkillFrontmatter: Equatable {
    let name: String?
    let description: String?

    static func parse(contentsOf skillMDPath: URL, fileManager: FileManager = .default) -> SkillFrontmatter
}
```

### `Marketplace.discoveredURLs` — addition to existing `Lumi/Parsers/Marketplace.swift`

Enumerates registered marketplace catalog files:
`<CLAUDE_CONFIG_DIR or ~/.claude>/plugins/marketplaces/*/.claude-plugin/marketplace.json`.

`settings.json`'s `extraKnownMarketplaces` only lists marketplaces added beyond the default, not
`claude-plugins-official` itself (verified against this machine's real settings.json) — a
directory scan is the complete source, not that key.

```swift
extension Marketplace {
    static func discoveredURLs(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default
    ) -> [URL]
}
```

A marketplace directory whose `marketplace.json` fails to decode is skipped, not fatal to the
whole scan.

### `SkillOriginResolver` — `Lumi/Inventory/SkillOriginResolver.swift`

Given one discovered skill's resolved path, the global lockfile, and installed plugins, resolves
origin in this order:

1. **Plugin** — path is contained under some `InstalledPluginEntry.installPath`. The
   `installed_plugins.json` key (`"superpowers@claude-plugins-official"`) splits into plugin
   name + marketplace name, so the caller knows exactly which registered marketplace to check
   for catalog drift without searching all of them.
2. **Repo install** — else the skill's directory name matches a key in the global lockfile.
3. **Hand-written** — else, no tracking data found for this skill.

Plugin match is checked first: it's a path-containment check (unambiguous), while the lockfile
match is a name lookup that could theoretically collide with an unrelated plugin skill of the
same name.

"Contained under" compares `URL.pathComponents`, not a raw string prefix — a naive
`path.hasPrefix(installPath)` would false-positive `/a/b` against `/a/bc`.

```swift
enum SkillOrigin: Equatable {
    case plugin(name: String, marketplaceName: String, version: String)
    case repoInstall(source: String, skillFolderHash: String)
    case handWritten
}

enum SkillOriginResolver {
    static func resolve(
        path: URL,
        globalLockfile: GlobalLockfile,
        installedPlugins: InstalledPlugins
    ) -> SkillOrigin
}
```

### `SkillInventoryBuilder` — `Lumi/Inventory/SkillInventoryBuilder.swift`

The orchestrator. For each `DiscoveredSkill`: resolve origin, parse frontmatter, and — for
plugin origin only — run `PluginCatalogDriftDetector` (against the marketplace named by the
origin) plus an installed-vs-enabled check against `ClaudeSettings.enabledPlugins` (keyed by the
same `"name@marketplace"` string as `installed_plugins.json`).

```swift
struct SkillInventoryItem: Equatable {
    let name: String
    let description: String?
    let path: URL
    let agentID: String
    let scope: SkillScope
    let origin: SkillOrigin
    let statuses: [SkillStatus]
}

enum SkillStatus: Equatable {
    case pluginCatalogDrifted(installedSha: String, pinnedSha: String)
    case installedButDisabled
}

enum SkillInventoryBuilder {
    static func build(
        discovered: [DiscoveredSkill],
        globalLockfile: GlobalLockfile,
        installedPlugins: InstalledPlugins,
        settings: ClaudeSettings,
        marketplaces: [Marketplace],
        fileManager: FileManager = .default
    ) -> [SkillInventoryItem]
}
```

## Error handling

Best-effort throughout — one bad input degrades gracefully, it never fails the whole build:

- Unparseable/missing frontmatter → directory name, nil description.
- A marketplace file that fails to decode → skipped.
- A plugin whose marketplace isn't in the scanned set → `PluginCatalogDriftDetector.unknown`
  (already handles this).

## Testing

Same pattern as stages 2–5:
- `SkillFrontmatter` — real temp-directory fixtures (file I/O), mirrors `SkillFolderHasherTests`.
- `SkillOriginResolver` / `SkillInventoryBuilder` — synthetic in-memory fixtures, no filesystem,
  mirrors the stage-5 detector tests.

## Part 2 sketch — Read-only UI (separate future design cycle)

Once the builder exists, the UI PR is mostly SwiftUI:

- `@Observable InventoryStore` runs the full pipeline (registry → scanner → parsers → builder)
  once on launch (ADR 0012 — scan on launch, manual refresh) and exposes `[SkillInventoryItem]`
  plus `refresh()`.
- Sidebar (All Skills default, By Scope, By Agent, Plugins, Needs Attention) as filters/groupings
  over the same array, not separate loads.
- List: name, origin badge, scope, agent chips, version (plugins only), status chips.
- Detail: description, origin, real path, plugin info. The activation matrix and drift diff from
  SPEC §7 need data this slice doesn't have (write-engine wiring, a diff view) — this pane shows
  the fields above; the matrix arrives read-only in a later stage per the existing build order.

This section is intentionally a sketch, not a committed design — it'll get its own brainstorming
pass after Part 1 merges, once `SkillInventoryItem`'s real shape is settled.

## Explicitly out of scope

- Project-scope workspace registration (follow-up)
- Local drift / shadowing / divergence wiring (need project scope; not called from the builder
  this round)
- Activation matrix interactivity, write operations (stages 7–8)
- Upstream staleness (issue #14)
