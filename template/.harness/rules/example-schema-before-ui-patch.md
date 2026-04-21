# MR-<id> · Fix the model before patching the UI

> **Status**: active (seeded example — delete or adapt once you've authored real rules)
> **Severity**: review-only
> **Added**: 2026-04-21
> **Check script**: `null` (cognitive rule — enforced in session-start + PR review)

---

## Why

Meta-rule seeded from a common pattern: when a data model turns out to be missing a capability the UI needs, the tempting patch is to add defaults / coalesce operators / conditional branches in the UI layer. This "works" for the scenario in front of you and makes the immediate diff smaller. It also permanently embeds the missing-model assumption into the presentation layer, where every subsequent feature inherits the workaround and the _real_ fix becomes progressively harder.

Recurring incidents that motivate this rule (fill in with yours):

- `<YYYY-MM-DD>` · user has multiple roles across multiple departments; model assumes one role per user → UI coerces with `?.department ?? '—'`. Six months later, permission bugs trace to the UI-layer coercion hiding an invalid shape.
- `<YYYY-MM-DD>` · UI adds a computed "isOverdue" flag because the schema stores only due dates; three reports later disagree on what counts as overdue.

If you haven't yet seen this pattern twice in your project, treat this rule as a candidate and watch for the second incident before enforcing.

## The boundary

> _When the UI needs a piece of state the data model doesn't provide, **stop and fix the model**. Do not add defaults, computed getters, or conditional shape-coercion in the UI layer._

## How to apply

Before adding any of the following in a UI file, ask: _is the real fix upstream?_

- `value ?? defaultValue` where `defaultValue` encodes business meaning
- `if (!record.X) { synthesize X here }` — synthesizing missing fields in the view
- Computed getters in components that derive a flag multiple components need
- Multiple UI callers all coalescing the same nullable field the same way

If yes → stop. Propose a schema / model change first. If the schema change is too large for this PR, add the UI coercion **temporarily** and register it in `violations-triage.md` with an expiry and a tracking link to the follow-up.

## Example — violation

```tsx
// ❌ UI papering over a missing model field
<Badge>
  {order.settlementStatus
    ?? (order.paidAt ? "settled" : order.cancelledAt ? "cancelled" : "pending")}
</Badge>
```

The ternary encodes business rules about what `settlementStatus` _should_ be. The rule lives in the view, which means every other view that wants the status either re-derives it (drift) or imports a helper from `components/` into a service (layer leak).

## Example — correct

```tsx
// ✅ settlement status is a first-class model field computed server-side
<Badge>{order.settlementStatus}</Badge>
```

… after landing a migration / resolver that computes `settlementStatus` once, server-side, authoritative, consumed everywhere.

## Allowlist

None in the template. Projects adopting this rule should list temporary UI coercions here with expiries.

## Retirement criteria

This meta-rule retires if:

- The architecture enforces "UI reads domain objects verbatim" via strict types / Zod schemas that refuse to fall back — at which point the compiler catches the coercion.
- The team moves to server-driven UI (UI receives pre-computed presentation objects) and there's no place to insert a coercion.

## Related

- `example-no-parallel-source-of-truth.md` — UI-layer coercion is a common source of parallel truth.
- `example-ui-purpose-first.md` — the "why am I displaying this" gate often reveals that a UI coercion is hiding a missing model field.
