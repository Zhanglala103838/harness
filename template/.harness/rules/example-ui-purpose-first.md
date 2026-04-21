# MR-<id> · Answer "why show this" before rendering a field

> **Status**: active (seeded example — delete or adapt once you've authored real rules)
> **Severity**: review-only
> **Added**: 2026-04-21
> **Check script**: `null` (cognitive rule — enforced in session-start + PR review)

---

## Why

The pattern this rule catches: UIs that quietly accumulate fields. A new view starts focused; each feature cycle adds one more badge / one more column / one more timestamp because "might as well show it." Six months later the screen is a wall of data that users scan past, the original task flow is buried, and removing any one field requires a meeting because somebody might rely on it.

For AI-generated diffs this is especially common: the AI sees a schema with 30 columns, the ticket says "build a detail page", and the path-of-least-resistance is to render all 30. None of them are _wrong_; none of them are _justified_ either.

Recurring incidents that typically motivate this rule:

- `<YYYY-MM-DD>` · user challenges: "why are you showing this field here? what does the user do with it?" — the AI has no answer.
- `<YYYY-MM-DD>` · a column that was added for completeness becomes load-bearing for a workflow six months later; nobody documented the intent; deprecating it is blocked.

## The boundary

> _Before rendering any field in a UI, the author (human or AI) must be able to answer three questions. If any answer is missing, don't render the field._

## How to apply — the three questions

1. **What does the user _do_ on this screen?** (the primary task, stated in one verb)
2. **What information does this specific field contribute to that task?** (a one-line justification)
3. **What happens if the field is missing?** (does the user fail the task, or just mildly notice?)

All three must have an answer. "For completeness" / "the data is available" / "the designer put it there" are not answers.

Apply this gate:

- Before adding a new field to an existing table / card / detail view
- Before building a new UI that enumerates model fields
- Before accepting an AI-generated diff that exposes a new column

## Example — violation

```tsx
// ❌ the schema has 12 columns; let's render all 12
<DetailPanel>
  {columns.map(col => <Row key={col.key} label={col.title} value={record[col.key]} />)}
</DetailPanel>
```

No filter, no justification, no thought about which field helps the user on _this_ screen. Result: a wall of data that buries the 2 fields that actually matter here.

## Example — correct

```tsx
// ✅ curated for the task: "confirm the order details before submitting for approval"
<DetailPanel>
  <Row label="Customer" value={order.customerName} />           {/* identifies the order */}
  <Row label="Amount" value={formatCurrency(order.amount)} />   {/* drives the approval threshold */}
  <Row label="Due date" value={formatDate(order.dueDate)} />    {/* affects urgency */}
  {/* intentionally omitting: created_at, updated_at, tags, notes — none inform this decision */}
</DetailPanel>
```

The author left a comment naming the task and justifying each field. A future reviewer can tell whether a new field _belongs_ or not.

## Allowlist

None in the template.

## Retirement criteria

This meta-rule retires if:

- The design system enforces a "purpose-driven field selection" step (e.g., schema-to-UI generation requires each field to carry a `purpose` annotation scoped to the view).
- The project adopts a UX review gate that rejects PRs with unjustified fields, making this rule redundant with review.

## Related

- `example-schema-before-ui-patch.md` — you'll often find, when answering "why show this", that the field doesn't actually exist cleanly in the model. That's a signal to fix the model, not to patch the UI.
