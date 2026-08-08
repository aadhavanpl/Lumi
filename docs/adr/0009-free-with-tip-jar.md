# ADR 0009 — V1 ships free, with a tip jar

**Status:** Accepted · 2026-08-07

## Context

The stated goal is *"an actual product I can add to my resume, not just a GitHub project."*
That sets the bar at **shipped, notarised, real users** — not at maximising revenue — which
argues for the simplest legitimate model rather than the most lucrative one.

Options considered: free V1 monetise V2; paid one-time for the whole app; freemium split at
the read-only/write seam (ADR 0007's shape A vs B) via StoreKit non-consumable IAP;
subscription from day one.

Subscription was rejected outright: there is no server, no ongoing cost, and nothing
delivered monthly. Subscriptions without ongoing value delivery produce churn and resentment.

## Decision

**V1 is free. A tip jar is the only monetisation.** No paid tier, no feature gating.

## Consequences

- No paywall logic, no entitlement checks, no receipt validation in V1. Meaningful
  complexity avoided on a first Mac app.
- Free positioning is hard to reverse. If V2's server-backed features are to be paid, they
  should be a **separate SKU**, not a retroactive lock on anything V1 gave away.
- **Do not sell "lifetime access."** It was floated and is a trap here specifically: a hosted
  org registry in V2 carries ongoing server cost, and lifetime buyers would reasonably expect
  it included forever.
- The freemium seam (free shape A / paid shape B) remains available later — it was derived
  independently on technical grounds, which suggests it is a real product boundary.

## Open — tip jar mechanics

Mechanism depends on the distribution decision and needs verification against current App
Review Guidelines before implementing:

- **Mac App Store:** the standard path is a consumable IAP tip jar. Allowed and common;
  Apple takes a commission (15% under the Small Business Program).
- **Direct distribution:** GitHub Sponsors, Ko-fi, or Stripe with no commission.
- Linking out from a MAS app to an external donation page has historically been restricted by
  anti-steering rules. This shifted in the US following the 2025 Epic injunction, but the
  specifics remain volatile — **verify current guidelines rather than relying on this note.**

## Realistic expectations, recorded deliberately

A niche Mac utility for developers running multiple AI coding agents is a small market. Even
paid, this is plausibly hundreds to low thousands of buyers. As a free app with a tip jar,
tip revenue will be marginal. The portfolio artifact — a shipped, notarised, well-engineered
Mac app solving a real problem — is the return being optimised for.
