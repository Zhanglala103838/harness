# Review pipeline — three concerns, three passes

> Bonus pattern, not required by harness, but useful when pairing harness with AI-assisted code review. Keeps review signal high by separating concerns that collapse into mush if mixed.

## The problem with one-shot reviews

A single "please review this PR" prompt collapses three orthogonal concerns:

1. **Bug hunting** — logic errors, edge cases, race conditions, boundary overflow, missing null checks
2. **Quality / security / performance** — OWASP class issues, query performance, memory leaks, unsafe patterns
3. **Structure / refactor** — duplication, SRP violations, overgrown files, premature abstraction

A reviewer (human or AI) trying to cover all three at once produces diffuse output — a few of each, none thoroughly. Splitting them into three passes produces sharper, actionable findings.

## The three passes

Run each as an independent review, ideally in parallel if you have AI agents available. Each has a different mandate, different red flags, different vocabulary.

### Pass 1 · Bug finder

Mandate: find logic errors and edge-case gaps.

Checklist:

- Boundary conditions (zero, empty, negative, max-int, empty string, null, undefined)
- Off-by-one errors in loops / slicing / paging
- Concurrency — shared state, race windows, lost updates, incorrect lock scope
- Error handling — swallowed exceptions, wrong error type, misleading re-throws
- Branch coverage — every branch of every conditional handled?
- External input validation — is anything trusted that crosses a boundary?

Output shape: list of `file:line · what could go wrong · minimal reproducing input`.

### Pass 2 · Quality, security, performance

Mandate: find issues the first pass wasn't looking for.

Checklist:

- OWASP top 10 — SQL injection, XSS, CSRF, auth bypass, SSRF, insecure deserialization
- Secrets — hardcoded keys, tokens, URLs with credentials
- Query performance — N+1, missing indexes, cartesian joins, unbounded result sets
- Memory — leaks, unbounded growth, retained references
- Resource lifecycle — connections, file handles, event listeners, timers (opened, not closed)
- Input sanitization — assumed trust between layers

Output shape: list of `file:line · risk category · severity · concrete exploit or cost`.

### Pass 3 · Structure / refactor

Mandate: now that we know it works and is safe, should the shape change?

Checklist:

- Single responsibility — does this function/class do one thing?
- Duplication — repeated logic that should be extracted? repeated literals that should be constants?
- Abstraction — premature abstractions without ≥ 3 concrete consumers? too-generic names hiding intent?
- File size — exceeds the soft limit in `config.yaml` `advisory.max_file_lines_soft_warn`?
- Naming — does the name tell the reader what the thing does?
- Tests — are the critical paths covered? any brittle mocks?

Output shape: list of `file:line · suggestion · optional: diff sketch`.

## How to run the passes

The easiest implementation with modern AI agents:

1. Dispatch three agents in parallel, each with one of the checklists above.
2. Collect outputs.
3. De-duplicate overlapping findings (rare but possible).
4. Prioritize by severity, not by pass.

Without agents, a single human reviewer can still run three passes mentally — just do them in order, finishing one before starting the next. Don't try to track all three at once.

## What this is NOT

- Not a replacement for tests, type checks, or the harness itself. Those run first.
- Not a substitute for architectural review — major design decisions belong in a spec / ADR before code is written.
- Not "pile on more reviewers." Each pass should still take ≤ 10 minutes on a typical PR.

## When to skip

- Trivial changes (typo, dependency bump, generated file update)
- Documentation-only PRs
- Revert commits

## When a pass can fail the PR

Default: only the bug-finder pass blocks merge. Quality and structure passes produce follow-up work that can land in a subsequent PR. Customize based on your team's tolerance for follow-ups.

## Relationship to harness

Harness catches recurring-pattern violations before review. The review pipeline catches novel issues. You need both — harness prevents yesterday's bugs from recurring, review prevents tomorrow's from shipping.
