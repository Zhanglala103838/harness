# MR-<id> · Mocks pass ≠ runtime works

> **Status**: active (seeded example — delete or adapt once you've authored real rules)
> **Severity**: review-only
> **Added**: 2026-04-21
> **Check script**: `null` (cognitive rule — enforced in session-start + PR review)

---

## Why

The failure mode this rule guards against: an AI fixes a bug in a DB query / resolver / migration / auth path, runs the existing unit tests (which mock the DB / HTTP / whatever external boundary), announces "**All X tests pass**", and marks the task done. The tests _were_ green. The fix _did not_ work in production.

This happens because:

1. The mock was written to match the _previous_ (broken) behavior, not the real system's behavior.
2. The mock elides the exact failure mode the fix was supposed to address (e.g., NULL handling, locale collation, timezone, index selection, connection pooling).
3. "All tests pass" is a powerful-sounding phrase that short-circuits the reviewer's instinct to run the real check.

Incidents that typically motivate this rule (fill in with yours):

- `<YYYY-MM-DD>` · resolver fix for field-cascade bug — unit tests mocked `db.query` to return synthetic rows; prod DB had rows with NULL parent_key that the mock never produced.
- `<YYYY-MM-DD>` · migration said "tested, backfills 100% of rows" — tested against seed fixture of 12 rows; real table had rows with encoded JSON the migration couldn't parse.

Two of these within 30 days → promote to an active rule.

## The boundary

> _A claim that a DB / resolver / migration / integration fix "works" must be backed by a **real-data verification**, not only unit/mock tests. "X tests pass" alone is not acceptable completion evidence._

## How to apply

Before claiming a fix is done, ask: _which class of change is this?_

| Change class | Sufficient evidence |
|---|---|
| Pure logic (sort, format, parse, reducer) | Unit tests with good coverage of edge cases |
| DB query / resolver / ORM code | Real DB run against representative data (a staging dump or prod-shape fixture) |
| Migration / backfill | Dry-run on staging dump of current prod; count before/after; sample inspect of transformed rows |
| Auth / permission / scoping | Real session as each affected role; real tokens; verify both the allow and deny paths |
| External API integration | Real sandbox call; captured request/response; error cases exercised |

If the change touches a row below the top one, and the evidence provided is only unit tests, the task is not done.

## Example — violation

```
AI: "Fixed the cascade resolver. Ran the test suite. All 247 tests pass. ✅"
```

No real-DB verification. The cascade resolver reads from a table with thousands of rows of production data; the tests use a fixture of 12. The fix is unverified.

## Example — correct

```
AI: "Fixed the cascade resolver. Unit tests pass (247/247).
      Ran `npm run verify:field-ssot` against staging dump: 0 orphan cascades (was 21).
      Spot-checked 3 affected reports in the admin UI: dropdowns populate correctly.
      Task ready for review."
```

The AI names both the mock layer verification and the real-data verification. A reviewer can reproduce either.

## Allowlist

None in the template.

## Retirement criteria

This meta-rule retires if:

- The project adopts integration-test infrastructure that makes real-data runs the _default_ for every PR, such that the failure mode disappears structurally.
- All code touching DB / external systems goes through a typed adapter that ships its own contract tests against a live (or high-fidelity recorded) backend.

## Related

- `example-schema-before-ui-patch.md` — schema fixes need real-data verification too; this rule is the general form.
