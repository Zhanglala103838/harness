# Writing rules

A good harness rule is **specific, motivated, and grep-able**. This guide is the checklist.

## The three tests

Before writing a rule, it must pass all three:

1. **Two incidents test.** Can you cite ≥ 2 real commits / issues / post-mortems where this bit your team? If not, it's too speculative. Hold it as a soft advisory until it bites twice.
2. **Grep-ability test.** Can a bash script with `grep` / `find` decide "violation or not"? If not, the rule can still exist, but mark `auto_check: manual` and be honest that it only survives through human review.
3. **Retirement test.** Can you name a future state where this rule becomes redundant? ("When field X moves to the DB with a NOT NULL constraint, retire.") If a rule has no end, it's probably a permanent architecture choice — put it in an ADR, not harness.

## The rule file shape

Every rule lives in `.harness/rules/<slug>.md`. Use `_TEMPLATE.md` as the starting point. The sections are mandatory:

### Header front-matter

```
> **Status**: draft | active | stable | legacy | retired
> **Severity**: error | warn
> **Added**: YYYY-MM-DD
> **Check script**: path or null
```

### Why (mandatory)

At least two dated citations. If you only have one, write the rule in `draft` status and promote to `active` when it bites again.

### The boundary (mandatory)

One sentence. What's forbidden, where, and in what code shape. Don't say "be careful with X" — say "no exported `const UPPER_SNAKE` in `src/models/**/*.ts`."

### How to apply (mandatory)

A 2–4 step decision tree. A reader in 30 seconds should know whether their diff violates the rule.

### Examples — violation + correct (mandatory)

Smallest possible snippet. Not a whole feature, not pseudocode, not "see the codebase." A 5-line bad example and a 5-line good example.

### Allowlist (optional)

When you install the rule against an existing codebase, some code will violate it today. That's fine — list it with an expiry date. Delete the section when it's empty.

### Retirement criteria (mandatory)

What must happen for this rule to no longer be needed? Name the concrete signal.

### Related (optional)

Link sibling rules, ADRs, spec sections.

## Rule IDs

Use a short scheme you'll remember. Suggestions:

- `R-1`, `R-2` … for code-layer rules
- `MR-1`, `MR-2` … for meta-rules (how humans/AI reason), if you want to separate
- `<slug>-only` if you prefer kebab-case over numeric

Be consistent. Don't rename IDs casually — they're referenced in exemptions and git history.

## Severity

- **error** — the check fails the build / CI / commit. Use for rules that would waste human time in review if silently violated.
- **warn** — the check logs but exits 0. Use for rules that still need human judgment but where false positives are expected.

Start new rules at `warn`. Promote to `error` after two weeks of clean signals.

## Rules versus meta-rules

A **rule** constrains code shape. ("Page components must not call `hasPermission()`.")
A **meta-rule** constrains how humans or AI agents reason. ("Before diagnosing a bug, query the config table to ground the diagnosis in real data rather than the JSON key name.")

Both belong in harness — meta-rules can be among the highest-leverage because they prevent entire classes of bad diagnoses before code is written. But they're almost never grep-able; they live in `session-start.md` and PR-review habits.

## Common mistakes

- **Writing a "best practice" rule.** If every project should do it, it's in the language / framework docs, not your harness.
- **Too broad a scope.** "No class longer than 100 lines" isn't a harness rule — it's a lint rule. Harness is for boundaries your linter can't express.
- **No expiry / no retirement criteria.** Rules without lifecycle rot. Even permanent-sounding rules need a named signal for when they'd become redundant (e.g., "when migration M-42 ships").
- **Mixed motivations.** One rule = one boundary. If you're tempted to add "and also…" split it.

## Once you have a rule, write the check

See [`writing-checks.md`](./writing-checks.md).
