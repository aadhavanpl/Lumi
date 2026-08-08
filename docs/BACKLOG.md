# Backlog — deferred, with reasoning intact

Ideas cut from V1 on purpose. Each entry keeps the evidence so the decision can be revisited
without redoing the research.

---

## Live inventory updates via FSEvents

**Status:** Deferred from V1 (2026-08-07). V1 scans on launch with manual refresh (ADR 0012).

### The design when picked up

Watch **precisely** what matters, never a registered root. Measured on the reference machine,
naive watching of `~/Developer` covers **14,359 directories** including 1.9 GB of
`node_modules`; the precise set is **10 directories**.

- FSEvents on each known skill directory, plus its **parent** (`.claude/`, `.agents/`) so
  that creating a new `skills/` folder registers.
- FSEvents on the state files: `installed_plugins.json`, `settings.json`,
  `.skill-lock.json`, marketplace clones.
- A bounded rescan on **app activation** to catch newly created project locations.

### Known gap in that design

A brand-new project skill directory does not appear until the app is activated. Accepted
trade — the alternative is watching 14,000 directories to catch an event the user sees within
a second of looking at the window.

---

## Organisation / team tier

**Status:** Deferred. Raised at project inception as an explicit V2 idea; not yet designed
or grilled.

### The original idea

A central company repository where an organisation's skills are curated, and members select
which ones to install to their own machines.

### Notes for when it is taken up

- This is the first feature requiring a **backend**, which changes the economics settled in
  ADR 0009 and ADR 0010: server cost, uptime obligation, authentication, and a plausible
  subscription SKU.
- It would reuse the *Source*/origin model in the GLOSSARY — an org registry is another
  source type, and "install the company source" is one action rather than fifty.
- Interacts with ADR 0006: a company with Windows engineers makes the deferred Windows port
  urgent, and that port is not cosmetic (see ADR 0006 on symlink privileges).
- Should not be designed until V1 has validated that the local inventory problem is one
  people actually care about.

---

## Browsable skill catalog / discovery

**Status:** Deferred from V1 (2026-08-07). V1 ships no catalog backend.

### The blocking constraint

**The skills.sh API cannot be used by a native app.** Verified 2026-08-07:

```
GET https://skills.sh/api/v1/skills/search?q=react&limit=2
→ HTTP 401
  {"error":"authentication_required",
   "message":"Pass a Vercel OIDC token (Authorization: Bearer <VERCEL_OIDC_TOKEN>)"}
```

Authentication requires a Vercel OIDC token, issued to projects deployed on Vercel. Rate
limits are scoped per (team, project). A native Mac app has no path to this.

### Options if revisited

| Option | Gets you | Costs |
| --- | --- | --- |
| Proxy skills.sh via own Vercel deployment | their leaderboard, 1.1M install counts, semantic search | building a commercial product on a competitor's API through an auth path not intended for resale; kill switch in Vercel's hands; Vercel is the party most likely to ship this GUI themselves |
| Own index (crawl GitHub for `SKILL.md` / `marketplace.json`) | ownership; doubles as org-registry infrastructure | backend + crawler + ranking + moderation |
| Curated static JSON on own CDN | cheap, no server | hand-maintained, small |

### The free catalog already on disk

Registered marketplaces are local clones with full metadata.
`~/.claude/plugins/marketplaces/claude-plugins-official/.claude-plugin/marketplace.json`
lists **37 plugins** with `name`, `description`, `category`, and `source`. Browsing
marketplaces the user has already registered is a real catalog requiring zero backend —
the cheapest possible version of this feature whenever it is picked up.

### Accepted trade

**Discovery is conceded to skills.sh.** No install counts, no trending, no semantic search.
Someone asking "what React skills exist" is better served by their site. This is consistent
with ADR 0001: compete on managing what is installed, not on finding new things.

---

## Orphan / cleanup detection

**Status:** Deferred from V1 (2026-08-07) to keep V1 lean. Revisit for V2.

### The original idea

Surface stale or unused skill data on disk and offer to reclaim it — "this much can be
cleaned up from your machine."

### Why it is not a disk-space feature

The framing was tested against the reference machine and it does not survive. What looked
like 443 MB of garbage in `~/.codex/.tmp`:

| Path | Size | Actual status |
| --- | --- | --- |
| `.tmp/bundled-marketplaces` | 366 MB | synced 2026-08-05 — **live** |
| `.tmp/plugins` | 77 MB | **live git clone**, HEAD `11c74d6`, synced 2026-07-27 |
| `.tmp/legacy-primary-runtime-skills` | 176 KB | 2026-05-18, name says legacy — probably orphaned |

`~/.codex/.tmp` is not a temp directory; it is where Codex keeps its marketplace clones.
**Of "443 MB of garbage," roughly 176 KB is genuinely reclaimable.** Determining that
required running `git rev-parse` against the directory.

An app shipping the naive assumption would have offered to delete 366 MB of live cache and
broken Codex for every user.

### Constraints for any future implementation

1. **Reframe from "reclaim disk space" to "find skills nothing will ever load."** The real
   payoff is correctness — orphans, stale forks, skills in directories no agent reads,
   skills shadowed by another copy. Disk space is a rounding error and is what free
   utilities do.
2. **Every removal goes to Trash via `NSFileManager.trashItem`. Never `unlink`, never
   `rm -rf`.** With undo.
3. **One-click removal only for a small verified allowlist** of paths whose semantics have
   been personally confirmed per agent. The allowlist starts nearly empty and grows only
   with evidence.
4. **Everything else is report-only** — show the evidence, explain the reasoning, offer
   "Show in Finder," let the user decide.
5. Agents change their cache layouts without notice. Any heuristic here has a permanent
   maintenance tail, and being wrong once in a *paid* tool is a trust event that does not
   recover.
