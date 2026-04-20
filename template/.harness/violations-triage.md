# Violations triage

> Every tactical exemption from a harness rule is logged here with an expiry date. `check-harness-health.sh` warns 14 days before expiry and fails after.
>
> **If you can't name an expiry, you can't have an exemption.** "Forever" is not a valid exemption — it's an admission that the rule is wrong. Fix the rule instead.

---

## Active exemptions

<!-- Entries use this shape. Example kept commented out; delete once you have real entries. -->

<!--
### EX-001 · `src/legacy/thing.ts` · R-<id>

- **Rule violated**: R-<id> — <rule name>
- **Why we can't fix today**: <one sentence — what unfinished work blocks the fix>
- **Tracking**: <issue / PR / spec section / epic link that will finish it>
- **Granted**: 2026-04-20
- **Expires**: 2026-07-20  <!-- hard date, will be picked up by check-harness-health.sh -->
- **Owner**: <who is accountable>
- **Extension history**: none
-->

_(No active exemptions — edit this file when you grant the first one.)_

---

## Retired exemptions

<!-- Move entries here once resolved. Don't delete — they're the receipts for what got fixed. -->

_(empty)_

---

## Quarterly review

Every quarter, walk the Active list:

- Expired → author must either resolve (remove the violating code) or request an extension via `evolve.md` model C with a new justification.
- Granted > 2 quarters ago, still active, no progress → the underlying task is stalled. Escalate before re-granting.
- Resolved → move the entry to Retired with the resolving commit SHA.

Silent expiry (entry in Active list, date in past, nothing done) = harness fail. `check-harness-health.sh` enforces this.
