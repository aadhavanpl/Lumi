# Lumi

A native macOS app that inventories every agent skill installed on the machine. Full context
lives in [`docs/SPEC-v1.md`](docs/SPEC-v1.md) and [`docs/adr/`](docs/adr) — read those before
making design decisions. Don't re-litigate a decision that already has an ADR.

## Code style

- Lean and simple. Prefer the straightforward solution over the clever one. No abstractions,
  protocols, or config knobs for a single use site.
- Follow current SwiftUI best practices for macOS 26 (Liquid Glass, `@Observable`, native
  `NavigationSplitView`/`Table`). Minimum deployment target is macOS 26.0 — no `#available`
  gating needed.
- Liquid Glass is used deliberately, not everywhere — see SPEC §7. Don't coat every view in
  `.glassEffect()`.
- No comments unless they explain a non-obvious *why* (a workaround, a hidden constraint).
  Don't explain what the code already says.
- SwiftLint runs as an Xcode build phase and in CI (`--strict`). Keep it green.

## Workflow

This project follows GitHub issue → branch → PR → review → merge. No direct pushes to `main`.

- One issue + branch + PR per build-order stage from SPEC §8 (agent registry, scanner,
  parsers, hash engine, detection, UI, write engine, matrix UI, packaging).
- Branch names: `feat/<stage-name>`, `fix/<thing>`, `chore/<thing>`.
- The user reviews and merges every PR — this is their first macOS app and they want to see
  and understand each step, not receive a finished feature.
- Write tests alongside implementation (`LumiTests`), especially for the hash engine — verify
  against the fixtures in SPEC §8.

## Before writing code

Check `docs/BACKLOG.md` before adding anything — deferred features are deferred on purpose.
