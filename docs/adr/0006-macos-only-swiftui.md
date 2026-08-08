# ADR 0006 — macOS-only, native SwiftUI

**Status:** Accepted · 2026-08-07

## Context

Options: native SwiftUI (macOS only), Tauri (Rust + web, cross-platform), or Electron.

The deciding evidence was the developer's existing environment, not abstract trade-offs.
Three shipped Swift/Xcode projects (`SimpleHabits`, `WhatsMyCut`, `dial`), Swift 6.3.3,
Xcode 26.6, `swift-lsp` enabled, a `swiftui-expert-skill` installed, and an existing Apple
Developer account. The stated "I've never built a Mac app" is true but misleading — this is
an iOS developer, so macOS is a platform delta, not a new discipline.

The app is also ~80% filesystem work, which Swift handles well and which gains little from
a web frontend.

## Decision

Native SwiftUI, macOS only, for V1.

## Why Windows is deferred — and it is not a port

**Windows breaks the install model, not just the UI layer.** The canonical-store +
symlink-farm pattern (real directory in `.agents/skills`, symlinks from each agent's
folder) depends on symlinks. On Windows, creating symbolic links requires Developer Mode or
Administrator rights for non-admin users. Directory junctions or plain copies would be
needed instead — which means **different install semantics, different move semantics, and
different drift behaviour**. That is a second product's worth of edge cases.

The target user — running multiple agents with enough sprawl to need this — also skews
heavily Mac.

## Consequences

- Addressable market is capped at Mac developers.
- If the org/team tier lands at a company with Windows engineers, the port arrives under
  deadline pressure rather than on our own schedule. Accepted knowingly.
- Tauri's Windows payoff would have cost learning Rust plus a new signing/notarisation
  pipeline before shipping anything. Electron would ship a ~150 MB runtime to manage a few
  hundred KB of markdown.
