# R-<id> · <one-line rule name>

> **Status**: draft | active | stable | legacy | retired
> **Severity**: error | warn
> **Added**: <YYYY-MM-DD>
> **Check script**: `.harness/checks/check-<slug>.sh` (or `null` if review-only)

---

## Why

Cite ≥ 2 real incidents that motivated this rule. Link commits / issues / post-mortems. If you cannot cite two, the rule is premature — convert to a soft advisory first.

- <YYYY-MM-DD> · <commit SHA or issue> · <what went wrong>
- <YYYY-MM-DD> · <commit SHA or issue> · <what went wrong>

## The boundary

One sentence. What's forbidden, and where. Be concrete about **what code shapes** violate it.

> _Forbidden: `<pattern>` inside `<path-glob>`._

## How to apply

The decision tree a reader (human or AI) uses to tell if they're violating this rule.

1. Am I editing/adding code inside `<scope>`?
2. Does my change introduce `<pattern>`?
3. If yes to both → violation.

## Example — violation

```ts
// ❌ forbidden — reason
<smallest reproducing snippet>
```

## Example — correct

```ts
// ✅ allowed — reason
<the compliant form>
```

## Allowlist (temporary, to-be-migrated)

Files/symbols that violate this rule today but can't be fixed immediately. Every entry needs an expiry and a tracking link.

- `<path>` — expires `<YYYY-MM-DD>` — tracking: `<issue / spec>`

When the allowlist is empty, delete this section.

## Retirement criteria

What would make this rule redundant?

- If `<architectural change / DB constraint / type definition>` lands, this rule is enforced by the schema itself and can be retired.
- Retire when: `<concrete signal — e.g., "all call sites migrated to new API and old API is deleted">`

## Related

- Rule(s): `R-<id>` · <why related>
- Spec / ADR: `<doc path>`
