# ADR 0010 — Direct distribution (Developer ID + notarisation), plus a Homebrew cask

**Status:** Accepted · 2026-08-07

## Context

Going free (ADR 0009) removed the strongest argument for the Mac App Store, reopening the
distribution question.

The deciding factor is the **App Sandbox**, which is mandatory on MAS. The app's core job is
reading many arbitrary directories across the user's home — `~/.claude`, `~/.agents`,
`~/.codex`, `~/.config/opencode`, plus every registered project root. That is exactly the
workload the sandbox exists to obstruct: `~` redirects to the app container, and each real
path requires a user-granted **security-scoped bookmark** that must be persisted, checked for
staleness, re-resolved, and wrapped in `startAccessingSecurityScopedResource` /
`stopAccessingSecurityScopedResource` at every access. For a scanner walking dozens of
directories, that is a meaningful fraction of V1 spent on plumbing.

## Decision

**Direct distribution:** Developer ID signing plus notarisation, shipped as a DMG, with
Sparkle for in-app updates. **Additionally published as a Homebrew cask** — the natural
install path for a developer-tool audience.

Mac App Store is not pursued for V1.

## Consequences

- Plain `FileManager` access, no bookmark plumbing. No review latency on releases.
- Tips can go through GitHub Sponsors or similar with no commission.
- Full-disk scanning (rejected in ADR 0003) remains *possible* later without a rewrite,
  though hybrid discovery stays the default for UX reasons regardless.
- **Given up:** App Store search as a distribution channel, and free auto-update
  infrastructure. Release hygiene becomes our responsibility.
- Users hit a Gatekeeper prompt on first launch. Acceptable for this audience.

## Homebrew specifics to plan for

- Casks require a **notarised** artifact at a stable, versioned URL with a published
  `sha256`.
- `homebrew-cask` enforces a **notability threshold** for new submissions (historically
  expressed as minimum GitHub stars/forks/watchers). Verify the current requirement before
  submitting — this is a real gate, and the app may need an audience *before* it can be
  accepted, making the cask a fast-follow rather than a launch-day item.
- An app that self-updates via Sparkle will drift from the version Homebrew tracks. Set
  `auto_updates true` in the cask so `brew upgrade` behaves correctly.
- Self-hosting a tap is the fallback if the notability gate blocks the main repo.
