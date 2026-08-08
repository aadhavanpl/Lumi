# Read-only UI (SPEC §8 stage 6) — design

**Date:** 2026-08-08 · **Status:** Approved, pending implementation

## Context

Stage 6 of SPEC §8's build order: "the app is genuinely useful before any write code exists."
`SkillInventoryBuilder` (PR #18) now produces `[SkillInventoryItem]` from the full pipeline
(agent registry → scanner → parsers → builder). Nothing consumes it yet — `ContentView.swift` is
still Xcode's default placeholder. This doc designs the three-column `NavigationSplitView` from
ADR 0011 that presents that array.

Full context: `docs/SPEC-v1.md` §7 (interface), `docs/adr/0011-information-architecture.md`,
`docs/adr/0008-activation-matrix.md`, `docs/adr/0012-freshness-model.md`, and
`docs/superpowers/specs/2026-08-08-inventory-builder-design.md`'s Part 2 sketch (superseded by
this doc).

## Scope decisions (confirmed in brainstorming)

- **One row per `SkillInventoryItem`, not grouped by skill across agents.** `SkillInventoryItem`
  is currently one record per (skill, agent) pair — no cross-agent identity grouping exists in
  the builder. SPEC §7's "agent chips" (plural, implying one row per skill) is not implemented
  this stage; each row shows a single agent. Revisit if/when the builder gains cross-agent
  grouping.
- **"By Scope" ships now as a single-bucket ("Global") sidebar section**, per ADR 0011's five
  specified entries, even though project scope isn't wired into the builder yet. No rework
  needed when project scope lands — the section already exists, it just gains a second bucket.
- **Status signals are exactly what `SkillInventoryBuilder` emits today**: `pluginCatalogDrifted`
  and `installedButDisabled`. Local drift, shadowing, divergence, and upstream staleness are not
  surfaced — the builder doesn't compute them yet (deferred per the inventory-builder design doc,
  pending project scope / issue #14).
- **No activation matrix, no drift diff view.** SPEC §7 describes both in the detail pane, but
  neither has backing data yet: the matrix needs the write engine (stage 8), and a diff view is a
  future addition once local drift is wired in. The detail pane shows only fields
  `SkillInventoryItem` actually has.
- **Loading/error handling: silent best-effort.** A brief loading state on launch, no error
  banners for individual source-parse failures — matches `SkillInventoryBuilder`'s existing
  per-item degrade-gracefully behavior and ADR 0011's "no alarmism."
- **Filtering strategy: computed, not precomputed.** `InventoryStore` holds one flat
  `[SkillInventoryItem]`; sidebar filtering is a plain function of `(items, selection)`, recomputed
  on selection change. At ~50 skills this is effectively free — no grouped-dictionary state to
  keep in sync (rejected as premature; see Approaches below).
- **Agent icons are real per-agent SVG logos**, not placeholder initials — the user has the
  assets available. Exact asset sourcing/licensing is an implementation detail, not a design
  blocker.
- **Status is a dot, not a column.** A small red dot next to the skill name indicates
  `!statuses.isEmpty`; the detail pane spells out which status(es) apply in full sentences.

## Approaches considered

1. **Single source of truth + computed filter (chosen).** `@Observable InventoryStore` holds one
   `items: [SkillInventoryItem]` array. Sidebar selection is a `SidebarSection` enum. The list
   view computes its visible rows via a pure `filteredItems(items:, selection:)` function — plain
   `filter`/`sort`, no caching. Simplest option; matches CLAUDE.md's "no abstractions for a single
   use site" and the actual data scale (~50 skills, ADR 0011).
2. **Precomputed grouped dictionaries** (`byScope`/`byAgent` maintained alongside `items`).
   Rejected — extra state to keep in sync for an O(50) filtering problem that doesn't need it.
3. **Generic filter/grouping engine** (pluggable `Filterable` strategy). Rejected — five fixed,
   known sidebar sections don't need an extensibility mechanism.

## Components

### `InventoryStore` — `Lumi/UI/InventoryStore.swift`

```swift
@Observable
final class InventoryStore {
    private(set) var items: [SkillInventoryItem] = []
    private(set) var isLoading = false
    var selection: SidebarSection = .allSkills

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        items = /* run AgentRegistry → SkillScanner → parsers → SkillInventoryBuilder */
    }
}
```

`refresh()` runs on `.task` at launch (ADR 0012 — scan on launch) and again from a manual
refresh control (toolbar button). No filesystem watching.

### `SidebarSection` — `Lumi/UI/SidebarSection.swift`

```swift
enum SidebarSection: Hashable {
    case allSkills
    case byScope(SkillScope)
    case byAgent(String)
    case plugins
    case needsAttention
}
```

Fixed top-level entries: **All Skills** (default), **By Scope**, **By Agent**, **Plugins**,
**Needs Attention**. By Scope and By Agent expand to the distinct values actually present in
`items` (e.g. today, By Scope has exactly one child: Global). Needs Attention carries a badge
count (`items.filter { !$0.statuses.isEmpty }.count`).

### Filtering — `Lumi/UI/InventoryFiltering.swift`

```swift
func filteredItems(_ items: [SkillInventoryItem], selection: SidebarSection) -> [SkillInventoryItem] {
    switch selection {
    case .allSkills: items
    case .byScope(let scope): items.filter { $0.scope == scope }
    case .byAgent(let agentID): items.filter { $0.agentID == agentID }
    case .plugins: items.filter { if case .plugin = $0.origin { true } else { false } }
    case .needsAttention: items.filter { !$0.statuses.isEmpty }
    }
    // sorted ascending by `name`, case-insensitive
}
```

Pure function — no dependency on `InventoryStore`, testable with synthetic fixtures.

### Views

- **`ContentView.swift`** — replaced with the `NavigationSplitView` root: sidebar, list, detail,
  wired to one shared `InventoryStore`.
- **`SidebarView`** — renders `SidebarSection` entries as a `List` with `Section`s for By Scope /
  By Agent's children. Selection binds to `InventoryStore.selection`.
- **`SkillListView`** — renders `filteredItems(store.items, selection: store.selection)`. Header
  row with fixed column widths (Name | Origin | Scope | Agent | Version); each row shows name +
  description, a small red status dot next to the name when `!statuses.isEmpty`, an origin chip,
  scope text, a per-agent SVG icon, and version text (plugins only, `—` otherwise).
- **`SkillDetailView`** — shown for the selected row: name, description, origin badge with
  origin-specific fields (plugin → marketplace + version; repo install → source + skill folder
  hash; hand-written → nothing extra), real resolved path (monospace), scope, agent, and each
  `SkillStatus` spelled out as a full sentence (e.g. "Installed version `896224c` differs from
  marketplace catalog `2bf8d8b`"; "Installed but not enabled in `settings.json`"). Empty-selection
  state is a centered placeholder, not an error.

Only `InventoryStore` touches the scan/parse pipeline; views take plain data/bindings.

## Error handling

No new error handling beyond what `SkillInventoryBuilder` and its parsers already do
(best-effort, degrade per-item). The UI adds nothing on top — no banners, no error states beyond
"the item list may be shorter than expected," consistent with ADR 0011's "no alarmism."

## Testing

Same fixture-based pattern as stages 2–5 (mirrors `SkillInventoryBuilderTests`):

- `InventoryFilteringTests` — pure function tests for each `SidebarSection` case against synthetic
  `[SkillInventoryItem]` fixtures: correct filtering, correct sort, `.needsAttention` matches
  non-empty `statuses`, `.byAgent`/`.byScope` produce correct buckets including the single-bucket
  Global case.
- `InventoryStoreTests` — `refresh()` populates `items` and toggles `isLoading`, using the same
  fixture-based pipeline inputs `SkillInventoryBuilderTests` already establishes.
- No view-level snapshot testing — no such infrastructure exists in this repo yet, and visual
  correctness is verified by running the app per the project's existing PR-review workflow.

## Explicitly out of scope

- Cross-agent row grouping (needs builder changes — `SkillInventoryItem` identity work)
- Project-scope workspace registration and its second By Scope bucket
- Local drift / shadowing / divergence / upstream staleness surfacing (builder doesn't compute
  them yet)
- Activation matrix, drift diff view (need write engine / diff UI — later stages)
- Filesystem watching (ADR 0012 — deferred to V2)
- Search/filter-by-text within the list (not called for in SPEC §7; add later if wanted)
- Real per-agent SVG asset sourcing/licensing (implementation detail, not a design blocker)
