# ADR 0014 — Verified agents only, shown when detected, defined by editable data

**Status:** Accepted · 2026-08-07

## Context

Three different numbers were in play: skills.sh supports 75+ agents, the reference machine
has three installed (Claude Code, Codex, opencode), and its lockfile's `lastSelectedAgents`
names 14.

## Decisions

### 1. Coverage — only agents whose layout has been verified

V1 ships path definitions only for agents whose directory layout and skill-resolution order
have actually been confirmed. **No guessed paths.**

Rejected — porting the full skills.sh table. A wrong path in an inventory tool does not
produce a visible error; it produces a **silent omission**. The app confidently displays 40
skills while 12 sit in a directory it never looked at. That failure is invisible to the
developer and fatal to the single promise the product makes.

### 2. Display — detected agents only

The activation matrix shows agents that are actually present. An agent counts as available
when its definition exists **and** either its directory is found on disk **or** the user has
explicitly added it.

Rejected — showing all known agents dimmed. Clutter, and it advertises support that has not
been verified.

### 3. Agent definitions are data, not code

The agent table ships as a plain data file. Adding a new agent or correcting an existing
path must be a data edit, never a code change.

- Bundled defaults ship with the app.
- **Users can add or override agent definitions**, so someone running an agent we have not
  verified can point the app at it themselves rather than waiting for a release.
- Because ADR 0007 permits read-only network GETs, the table can be refreshed from a static
  file (e.g. a raw GitHub URL) without a backend and without shipping a build.

## Consequences

- "Supports 4 agents" reads weaker on a landing page than "supports 75+", and skills.sh wins
  that comparison. Accepted deliberately: being right about 4 beats being wrong about 75.
- User-contributed agent definitions become the natural growth path for the table, and the
  most valuable bug reports the project can receive.
- User-supplied paths are untrusted input. They must be validated before scanning, and must
  never be able to direct destructive operations outside their declared scope.
