# ADR 0011 — Sidebar navigation, with the full inventory as the front door

**Status:** Accepted · 2026-08-07

## Context

Roughly 50 skills must be presented, each carrying name, description, origin, scope, agent
set, version (plugins only), and status — where status may be *fine*, *drifted locally*,
*stale versus upstream*, *shadowed by another copy*, or *untracked*.

Layouts considered: flat list with filters; sidebar mirroring the filesystem; smart-view
sidebar; dashboard-first.

A sidebar was chosen. A three-column `NavigationSplitView` — sidebar, skill list, detail
inspector — is the native macOS idiom and the cheapest structure to build well in SwiftUI.

## Decision

**Sidebar navigation, defaulting to the complete skill listing.**

Sidebar entries: **All Skills** (default), By Scope, By Agent, Plugins, and Needs Attention.

Status is surfaced **inline as chips on rows** within All Skills, so problems are
discoverable while browsing without requiring a separate destination. Needs Attention exists
as a dedicated view for users who want to focus on it — it is not the front door.

The detail pane holds the activation matrix (ADR 0008), the drift diff, and the real
filesystem paths.

## Rationale — and a rejected recommendation

An earlier recommendation landed the app on **Needs Attention** whenever it was non-empty,
on the argument that surfacing problems is where the unique value lies.

**This was rejected, correctly.** The app's purpose is listing every skill on the machine.
Opening on a problem list makes it read as a security or auditing tool, which is a different
product. Diagnostics are a capability the app offers, not its identity — providing them is
good; leading with them is a deviation from the aim.

## Consequences

- Default launch is the full inventory, in a healthy state or otherwise. No alarmism, no
  nagging on repeat launches.
- Status chips must be legible but visually quiet — informative at a glance, not shouting.
- Needs Attention may carry a badge count, since a badge invites rather than interrupts.
- Any future feature framed around auditing, security, or scanning must be checked against
  this ADR before it reshapes the app's identity.
