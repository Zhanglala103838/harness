# R-example · No parallel source of truth

> **Status**: active (example — rename + tailor to your project)
> **Severity**: error
> **Added**: <YYYY-MM-DD>
> **Check script**: `.harness/checks/check-no-parallel-source-of-truth.sh`

---

## Why

This is a worked example of the most common harness rule shape. Replace the contents with a real incident from your project; keep the structure.

Typical motivating pattern: the same fact (an enum list, a label map, a role-to-permission table) is maintained in two or more places. One day someone updates only one copy, silently.

- `<YYYY-MM-DD>` · `<commit SHA>` · a new status value was added to the DB enum but the frontend's parallel `STATUS_LABELS` map wasn't updated; users saw raw enum values for 3 days before anyone noticed
- `<YYYY-MM-DD>` · `<commit SHA>` · permissions added to the backend `roles` table but a frontend `CAN_EDIT_FIELDS` constant wasn't — the UI hid the button the backend was ready to authorize

## The boundary

> _Forbidden: exporting any of the listed "parallel-truth" constant names from `src/**` outside the named allowlist files._

Forbidden exports in this starter (edit for your project):

- `STATUS_LABELS`
- `ROLE_LABELS`
- `FIELD_ALIAS`
- `PERMISSION_MAP`

These are placeholders. Replace with the actual names your codebase has accumulated, then point the allowlist at the files that currently hold them (which will be migrated to DB / generated later).

## How to apply

1. Are you adding an exported `const <UPPER_SNAKE>` in `src/**/*.ts` / `src/**/*.tsx`?
2. Does the value duplicate something already in the database or a generated types file?
3. If yes → violation. Derive from the authoritative source at runtime instead.

## Example — violation

```ts
// ❌ src/lib/status.ts
// Parallel to the DB `orders.status` enum. Will drift.
export const STATUS_LABELS: Record<string, string> = {
  pending: 'Pending',
  approved: 'Approved',
  rejected: 'Rejected',
};
```

## Example — correct

```ts
// ✅ src/lib/status.ts
// Derived at runtime from the same source the backend uses.
import { getStatusOptions } from '@/server/status-resolver';

export async function resolveStatusLabel(value: string): Promise<string> {
  const options = await getStatusOptions();
  return options.find(o => o.value === value)?.label ?? value;
}
```

## Allowlist (temporary)

Files that hold such constants today and can't yet be removed. Each needs an expiry.

- `src/legacy/status-labels.ts` — expires `<YYYY-MM-DD>` — tracking: `<migration task>`

Delete this section when empty.

## Retirement criteria

- When all listed forbidden constants are derived from DB/generated types at runtime, retire.
- Signal: allowlist empty + no violations for 12 weeks + the authoritative source has a stable API.

## Related

- R-<id>: <related rule if you add one for "config tables must have admin UI">
