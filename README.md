# Lumi

A native macOS app that inventories every agent skill installed on your machine — across every
agent (Claude Code, Codex, Cursor, opencode, GitHub Copilot), every scope (global or
project), and every origin (plugin, repo install, hand-written) — and lets you reorganize
them.

Today, nothing surfaces this. `npx skills list` can't see plugin-provided skills, nothing
shows project-scoped skills across projects, and nothing reports when two copies of the same
skill have drifted apart. Lumi is an inventory browser, not a security or auditing tool.

> **Status:** early development. No app functionality yet — see [`docs/SPEC-v1.md`](docs/SPEC-v1.md)
> for the V1 scope and build plan. Screenshots coming once there's a UI worth showing.

## Installing

```bash
brew install --cask aadhavanpl/tap/lumi
```

Updates land with `brew upgrade --cask lumi`. Builds are Developer ID–signed and notarized —
see [`docs/RELEASING.md`](docs/RELEASING.md) for how releases are cut.

## Requirements

- macOS 26+
- Xcode 26+ (to build from source)

## Building

```bash
git clone https://github.com/aadhavanpl/Lumi.git
cd Lumi
open Lumi.xcodeproj
```

Build and run the `Lumi` scheme. [SwiftLint](https://github.com/realm/SwiftLint) runs as a
build phase; install it with `brew install swiftlint` to lint locally (CI enforces it either
way).

## Contributing

This project follows an issue → branch → PR workflow — see [`CLAUDE.md`](CLAUDE.md) for code
style and how work is organized. Design decisions are recorded as ADRs in
[`docs/adr/`](docs/adr); read the relevant one before proposing a change to how Lumi works.

## License

[Apache License 2.0](LICENSE)
