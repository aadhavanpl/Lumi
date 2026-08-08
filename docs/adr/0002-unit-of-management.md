# ADR 0002 — Skills are the primary list; plugins appear too, with provenance-gated actions

**Status:** Accepted · 2026-08-07

## Context

Half the reference machine's inventory arrives via plugins, and plugin-provided skills
behave differently from loose ones:

- A plugin has a real semver version (`superpowers@6.0.3`); a loose skill has none — the
  Agent Skills spec has no `version` field.
- A plugin has two independent states, *installed* and *enabled*.
- An individual skill inside a plugin cannot be deleted or moved; it sits in a
  version-numbered cache directory and returns on the next update.

Options considered:

- **(a) Loose skills only.** Clean uniform model, but the headline claim "see every skill
  on your device" is false for half of them, and the version/update feature has nothing
  truthful to display — loose skills have no versions.
- **(b) Everything in one flat list.** Honest, but half the rows have disabled buttons.
- **(c) Two separate first-class screens, Skills and Sources.** Truthful but more surface.

## Decision

**Skills are the primary list and it includes plugin-provided skills.** Every skill on the
machine appears as a row regardless of origin. Actions on each row — Move, Remove, Update —
are enabled or disabled based on that skill's origin, with the reason surfaced rather than
silently greyed out.

**Plugins are additionally manageable at their own level**, since install / enable /
disable / update / remove are genuine plugin-level operations with no per-skill equivalent.

## Consequences

- The app is also a plugin manager and a marketplace manager. Real added surface area:
  UI for `enabledPlugins`, marketplace add/remove/refresh, per-project plugin scope.
- The version and update story is **plugin-first**, because plugins are the only artifacts
  on the machine carrying real versions. Loose skills degrade to
  *changed upstream / unchanged / untracked* rather than a fabricated version number.
- A disabled action must always carry an explanation ("provided by superpowers 6.0.3 —
  manage at the plugin level"). Unexplained grey buttons read as bugs.
- Rejected: inventing a version scheme for loose skills. That would require the app to
  write its own manifest and hope the ecosystem adopts it — a far larger bet.

## Validating example

At time of writing the reference machine has `superpowers 6.0.3` installed (fetched
2026-06-20) while upstream is at **6.2.0**, and the local marketplace catalog has not been
refreshed in 7 weeks. Nothing on the machine surfaces this. That is the product's first
screen.
