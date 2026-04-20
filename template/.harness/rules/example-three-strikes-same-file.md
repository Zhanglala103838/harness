# R-three-strikes · Three strikes on the same file → escalate, don't iterate

> **Status**: active (example — keep or tailor)
> **Severity**: warn (enforced via PR review + git-log heuristic)
> **Added**: <YYYY-MM-DD>
> **Check script**: `null` (review-only — optional `check-three-strikes.sh` scans git log)

---

## Why

A file that has received three consecutive bugfix commits with three different diagnoses is, by revealed preference, not being debugged — it's being guessed at. Each round ships a plausible-sounding shim, tests pass in isolation, and the underlying root cause remains untouched. The fourth round finally surfaces the real mechanism, but only after the file has accumulated three layers of defensive code that now also have to be unwound.

- Symptom pattern: same file, same feature, three different PR titles over a short window, each claiming to fix a "different" bug
- Cost: team time × 4, plus the cleanup debt of rolling back the first three "fixes"
- Root cause in most incidents traced to one missed piece of context — a vendor default, an undocumented lifecycle, a concurrent write, a caching layer

## The boundary

When a single file (or tightly-coupled cluster — one component + its controller) has had ≥ 3 bugfix commits **with distinct diagnoses** over a rolling window (default: 14 days), further fixes are paused. A root-cause re-analysis is commissioned before any additional patching.

The re-analysis must:

1. Read all three prior diffs in order
2. Read relevant third-party / vendor source (see `R-vendor-read`)
3. Produce a single document with the **actual** root cause, citing evidence
4. Propose one fix that addresses the root cause, often removing code added in the previous three rounds

## How to apply

1. Before starting a bugfix, run `git log --oneline -n 10 -- <path/to/file>`
2. Count bugfix commits (by message type: `fix:` / `hotfix:` / `bug:`) in the last 14 days
3. If ≥ 3 with differing diagnoses → stop. Escalate for root-cause re-analysis.

A git-log based check is possible (see below).

## Example — violation

```
git log --oneline -- src/components/dialog.tsx
a1b2c3d fix: dialog flicker on iOS (set timeout)
b2c3d4e fix: dialog flicker on iOS (use nextTick)
c3d4e5f fix: dialog flicker on iOS (toggle v-if)
# PR #4 proposes: fix: dialog flicker (try requestAnimationFrame)
```

Four diagnoses, same symptom, no shared root cause identified. Stop. Escalate.

## Example — correct

```
# Three strikes observed → pause patching, author a root-cause doc
docs/rca/2026-04-dialog-flicker.md:
  Root cause: vendor-ui/dialog/index.js:64 — default scale transition.
  All three prior fixes were symptom patches, not root-cause fixes.

PR #4: fix: set vendor dialog transition="none"; revert shims from PRs #1-3
```

## Retirement criteria

Retire if your team converges on always performing root-cause analysis before the first fix (prevention rather than catching it at strike three). Most teams keep this as a safety net.

## Optional automated check

A weak signal check that greps `git log` for ≥ 3 `fix:` commits on the same path within 14 days:

```bash
# .harness/checks/check-three-strikes.sh (optional, opt-in)
git log --since="14 days ago" --pretty="%H %s" --name-only \
  | awk '/^(fix|hotfix|bug)/ {msg=$0; next} NF {print $0}' \
  | sort | uniq -c | awk '$1 >= 3 {print}'
```

Output is advisory — lists files with high fix-churn so reviewers can check before approving more patches.

## Related rules

- `R-vendor-read` — Read vendor source before patching; most third-strike cases are vendor-behavior gaps.
