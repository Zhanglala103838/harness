# R-example · Legacy allowlist with dated marker (staged migration)

> **Status**: active (example — rename + tailor to your project)
> **Severity**: error
> **Added**: <YYYY-MM-DD>
> **Check script**: `.harness/checks/check-legacy-allowlist-staged-migration.sh`

---

## Why

This is the worked example for **how to install a new rule against a codebase that already violates it 5+ times**. The naive paths both fail:

- **Big-bang block**: land the rule blocking globally → pre-commit fails on every PR touching unrelated files → team learns `--no-verify` → rule becomes decorative.
- **No rule**: skip the rule until "all consumers are migrated" → migration never happens → contract drifts forever.

This rule is the disciplined middle path: **land the rule with a pilot consumer + a dated legacy allowlist + a marker enforcement that prevents the allowlist from becoming permanent debt.**

Cite ≥ 2 real incidents on your project where this pattern bit you (or where the absence of staging caused a `--no-verify` cascade). If you can't cite two yet, hold this in `draft` until it bites.

- <YYYY-MM-DD> · <commit SHA> · 5+ existing consumers of <permission resolver / format registry / scope query>; one PR migrating all = high blast radius
- <YYYY-MM-DD> · <commit SHA> · prior rule landed without staging → `--no-verify` ratchet, rule never enforced

## The boundary

> _Forbidden: hand-rolled `<contract>` (e.g. row-scope SQL, format dispatch, permission lookup) inside `<scope-glob>` UNLESS the file is in `LEGACY_ALLOWLIST` AND carries exactly one `@<rule-id>-legacy until=YYYY-MM-DD` marker that has not expired._

Two enforcement axes:

1. **New code** must use the contract (`<single source of truth>`).
2. **Allowlisted legacy code** must carry exactly one dated marker. **Missing, duplicate, or expired markers fail the check** — that's what stops the allowlist from silently becoming permanent.

## Three-tier strategy (which path applies?)

| Existing violations | Strategy | Rule rollout |
|---|---|---|
| 0 (greenfield) | Land contract + rule blocking immediately | Same PR |
| 1–2 (small) | Land contract + migrate every consumer + rule blocking | Same PR |
| **5+ (legacy)** | **Land contract + 1 pilot migration + rule + LEGACY_ALLOWLIST + dated marker** | **Staged across 2–3 PRs** |

If you're in the 5+ row, this rule and its check are how you do it without the team revolting.

## How to apply

1. Are you adding/editing code inside `<scope-glob>`?
2. Does it hand-roll the contract (forbidden pattern listed in `Why`)?
3. Is the file in `LEGACY_ALLOWLIST`?
   - **No** → violation. Use the contract API.
   - **Yes** → check the file header has exactly one `@<rule-id>-legacy until=YYYY-MM-DD` marker that hasn't expired. Missing / duplicate / expired all fail.

## Example — violation (new file)

```ts
// ❌ src/app/api/reports/foo/route.ts
// New file, not in legacy allowlist, hand-rolls scope SQL — fails the check.
const where = `o.created_by = ?`;
```

## Example — violation (legacy file without marker)

```ts
// ❌ src/app/api/dashboards/stats/route.ts
// File IS in LEGACY_ALLOWLIST but has no @<rule-id>-legacy until= marker.
// Check fails: "in allowlist but has no @<rule-id>-legacy until=YYYY-MM-DD marker"
const where = `o.dataScope === 'self' ? ...`;
```

## Example — correct (new code uses the contract)

```ts
// ✅ src/app/api/customers/route.ts
import { buildScopeQuery } from '@/engine/permission-resolver';

const scope = buildScopeQuery({ resource: 'orders', user, tableAlias: 'o' });
sql += scope.where.length ? ` AND ${scope.where.join(' AND ')}` : '';
params.push(...scope.params);
```

## Example — correct (legacy file with valid dated marker)

```ts
/**
 * GET /api/dashboards/stats
 *
 * @<rule-id>-legacy until=2026-05-15
 * PR <closing-pr> must migrate this route to <contract>().
 */
```

The marker lives **in the source file**, not in a YAML config. Removing it (or letting the date pass) makes the check fail. Extending the date is a code commit visible in `git log` — it leaves an audit trail. No silent renewals.

YYYY-MM-DD strings sort lexicographically the same way they sort temporally, so plain bash `<` works.

## Allowlist (this is the rule's whole point)

Files that hand-roll the contract today and can't yet be migrated. **Each entry must have exactly one dated marker in the file source.** When the allowlist is empty, the rule is fully active and you can delete this section.

- `src/app/api/dashboards/stats/route.ts` — marker expires `<YYYY-MM-DD>` — tracking: PR <closing-pr>
- `src/app/api/dashboards/widget-data/route.ts` — marker expires `<YYYY-MM-DD>` — tracking: PR <closing-pr>

## Migration path (mandatory section)

Name the closing PR. Without this section, "temporary" allowlist becomes forever.

- **PR N**: introduce `<contract>`, migrate ONE pilot consumer, install this rule + LEGACY_ALLOWLIST + dated markers.
- **PR N+1**: migrate the rest of the allowlisted consumers, shrink `LEGACY_ALLOWLIST=()`, retire this rule's allowlist section.
- **Final**: delete this rule (the architecture now enforces the boundary structurally).

If PR N+1 slips, **bump the marker date in the source file** (visible commit) and update this section's expected date. Don't extend silently.

## Pilot consumer requirements

The pilot consumer landed in the same PR as this rule must:

1. Demonstrate the contract works in production-equivalent code path.
2. Be the smallest-diff consumer (low review surface).
3. Carry a `@<rule-id>-consumer` annotation pointing at this rule.
4. Have integration / real-data verification (don't rely on mocks alone — see meta-rule `example-real-verification-over-mocks.md`).

The pilot is what proves the contract is correct **before** you commit to migrating 4–10 more consumers in PR N+1.

## Retirement criteria

- `LEGACY_ALLOWLIST=()` is empty in the check script.
- No violations for 12 weeks after PR N+1 ships.
- Architecture / type system enforces the boundary structurally (e.g. the contract function is the only export of the engine module, callers can't bypass it).

When all three hold, retire the rule.

## Counter-example — when this pattern is wrong

If the rule is a **security invariant** (auth check, secret scrubbing, token redaction), legacy-allowing files to skip is unsafe. In that case fix everything in one PR even if blast radius is high. The legacy allowlist is for **architectural discipline**, not for security boundaries.

## Related

- Doc: `docs/writing-checks.md` § "Legacy allowlist with dated marker"
- Doc: `docs/evolution.md` § "Installing rules retroactively"
- Meta-rule: `example-real-verification-over-mocks.md` — pilot must have real-data verification, not just mocked tests
- Rule: `example-no-parallel-source-of-truth.md` — typical contract this pattern protects (single resolver instead of N hand-rolled copies)
