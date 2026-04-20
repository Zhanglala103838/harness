# `evolve.md` — how the harness grows and shrinks

> Harness is not a rulebook written once and frozen. It's a **learning system** that adapts as the codebase evolves. This file defines how.

---

## 1 · Self-bootstrapping

**Definition**: an AI agent entering a fresh session enters harness constraints with no external prompting.

### 1.1 · Activation paths (redundant by design)

| Layer | Mechanism |
|---|---|
| **Human entry** | Your repo's top-level `README.md` or AI-tool instructions file points at `.harness/session-start.md` |
| **Project entry** | `.harness/session-start.md` itself, ≤ 200 lines, read first every session |
| **Build entry** | `npm run harness:check` (or equivalent) — humans and CI run it at commit time |

Hard contract: any session opening MUST begin with _"Read `.harness/session-start.md` · task type = X · rules in scope = …"_. If the AI skips this, the PR is not valid and should be rejected on review.

### 1.2 · If the AI forgets

The reviewer can cite this section and reject the PR. Not punitive — it's the single observable signal that the session actually honored the harness.

---

## 2 · Self-upgrading

**Definition**: when a new failure mode is discovered, harness learns it. You don't wait for a quarterly architecture review.

### 2.1 · Upgrade triggers (when to propose a new rule)

| Trigger | Action |
|---|---|
| Same class of bug occurs ≥ 2 times within 30 days | Promote to a rule; write grep check if grep-able |
| One PR touches ≥ 3 files doing the same kind of workaround | Architectural leak — write a rule |
| An allowlist expires | Either retire the allowlist (architecture has caught up), or extend with fresh justification and a new expiry |
| A rule has zero hits for 12 consecutive weeks | Candidate for retirement — check if architecture made it redundant |

### 2.2 · Upgrade protocol (AI or human)

When any trigger fires, use **Model A** below. The PR title format: `harness(rules): R-<id> · <one-line description>`.

### 2.3 · Human review for upgrade PRs

On a rule-upgrade PR, ask:

1. Does this come from ≥ 2 real incidents (cite commits / issues / incident IDs), or is the author over-generalizing from one bad day?
2. Is the violation grep-able? If yes, the PR must include a check script. If no, the rule is documented as `auto_check: manual`.
3. What's the blast radius? Run `harness:check` with the new check on the current codebase. If 50+ files fail immediately, you have an allowlist to manage or the rule is too aggressive.

---

## 3 · Self-growing

**Definition**: rules have a lifecycle. Harness tracks whether it's still load-bearing or rotting.

### 3.1 · Rule lifecycle

```
  birth            growth           retirement
    │                 │                  │
    ▼                 ▼                  ▼
  draft ──→ active ──→ stable ──→ legacy ──→ retired ──→ deleted
    │         │          │          │           │
    │         │          │          │           └─ 6 months after retirement, delete files
    │         │          │          └─ Architecture has made it redundant (DB constraint / type system)
    │         │          └─ Has caught ≥ 1 violation in 3 consecutive months
    │         └─ Has an automated check + live in harness:check
    └─ Proposed, only in rules/*.md, no check yet
```

### 3.2 · Growth cadence

| Cadence | Action | Output |
|---|---|---|
| Every PR | AI self-asks if this change triggers §2.1 | Possibly a new rule proposal |
| Weekly | Run `check-harness-health.sh` | Health snapshot |
| Monthly | Review `violations-triage.md` expired exemptions | Triage update |
| Quarterly | Review hit rate of every rule | Retirement candidates |
| Every 6 months | Delete files of rules retired > 6 months ago | Harness stays lean |

### 3.3 · Health signals

`check-harness-health.sh` (ships with the kit) audits:

- Every rule in `rules/` is referenced in `config.yaml`, and vice versa (no orphans)
- Every check script in `checks/` is referenced in `config.yaml`
- Every allowlist file still exists
- `violations-triage.md` has no silently expired entries
- `CHANGELOG.md` top version == `config.yaml` `harness_version`

Run: `bash .harness/checks/check-harness-health.sh` or add it to your aggregate.

### 3.4 · Healthy vs bloated

**Healthy**:
- 8–15 active rules
- Each rule cites ≥ 2 real incidents in its Why
- All check scripts total < 500 lines

**Bloated** (start trimming):
- > 15 active rules — merge similar ones or retire low-frequency ones
- Any check with zero hits for 12+ weeks — retirement candidate
- `CHANGELOG.md` all additions, no retirements — you're accumulating dead weight

---

## 4 · Proposal templates

### Model A · propose a new rule

At the end of a PR that uncovered a new failure mode, output:

```
harness-evolve: propose R-<next-id>
  context: <commit SHA / issue ID / incident that triggered this>
  rule: <one sentence — what the boundary is>
  why: <≥ 2 real recurrences, cite commits>
  how-to-apply: <how a reader decides if they're violating it>
  auto-check: <✅ grep-able / ⚠️ partial / ❌ manual-only>
  example-violation: <smallest reproducing code snippet>
  example-correct: <the compliant form>
```

On approval: author creates `rules/R-<id>-<slug>.md`, optionally `checks/check-<slug>.sh`, updates `config.yaml`, appends to `CHANGELOG.md`.

### Model B · retire a rule

At a quarterly review:

```
harness-retire: R-<id> · <name>
  reason: <why it's no longer needed — architecture / DB constraint / type system caught up>
  evidence: <zero hits for N weeks / replaced by DB column X / etc.>
  plan:
    - Today: add @retired 2026-MM-DD to the rule file's front matter
    - +6 months: delete rule file + check script
  changelog: v<X.Y> · retired R-<id>
```

### Model C · extend an exemption / allowlist

2 weeks before an exemption expires:

```
harness-exempt-extend: <file-path> · R-<id>
  original-until: <YYYY-MM-DD>
  new-until: <YYYY-MM-DD>
  reason: <why it can't be removed on schedule — which unfinished task blocks it>
  tracking: <link to the task / spec section that will finish the migration>
```

---

## 5 · Meta note

This file itself is subject to the same discipline. When the harness protocol changes (new trigger, new cadence, new template), update this file and reference the change in `CHANGELOG.md`. Don't let `evolve.md` rot.
