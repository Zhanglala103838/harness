# External review: two-AI collaboration for high-stakes diffs

Harness rules catch known failure modes. An external reviewer — a different AI, or a different model of the same AI — catches the ones you haven't written a rule for yet. This doc describes a protocol for folding a second AI in as a reviewer without letting the second-opinion workflow devolve into "let's ask both and pick whichever we like."

The shape we've seen work: the **primary AI does the work**; an **external reviewer AI** is invoked at fixed trigger points; disagreements default to the reviewer being correct, with the human as final arbiter.

---

## 1 · Why two AIs instead of one

One AI alone falls into two traps:

1. **Confirmation drift.** Once the AI has committed to a diagnosis, its subsequent messages rationalize that diagnosis. Small contradictions get absorbed. A fresh reviewer sees the contradiction as a contradiction.
2. **Style overlap.** If the primary AI has a blind spot (e.g., "I never double-check migrations against live state"), it keeps that blind spot across 10 sessions. A different AI or different model has different blind spots, and the overlap is narrower than either one's full set.

This is the same reason human teams require a reviewer who wasn't the author. The cost is latency. The benefit is fewer diffs that "pass" the rules but violate reality.

---

## 2 · Fixed trigger points

Don't ask a reviewer for every change — you'd destroy the AI's velocity and drown the reviewer's signal in noise. Invoke the external reviewer at these trigger points:

| Trigger | Invocation |
|---|---|
| Session has accumulated ≥ N commits since last review | `<reviewer-tool> review --base <start-sha>` |
| About to land an architecture decision (ADR, new rule, new task type) | `<reviewer-tool> adversarial-review --challenge "<decision>"` |
| Same bug cycled ≥ 3 times with different diagnoses | `<reviewer-tool> rescue --investigate "<symptom>"` |
| User is about to declare a task "done" / merge the PR | `<reviewer-tool> review --base main` |
| New harness rule proposed with its first enforcement commit | `<reviewer-tool> adversarial-review --challenge-rule <R-id>` |

Tune N and the trigger list for your project's cadence. The right cadence is the one where the reviewer catches something real in ~1 of 5 invocations — more frequent than that and you're overusing, less frequent and you're underusing.

---

## 3 · The report format

Whatever tool drives the reviewer, the AI summarizing its output to the user should always use the same shape:

```
[<reviewer-tool> <command>] status=<done|failed|running>
findings:
  - <point 1>
  - <point 2>
  - <up to ~5 points, most critical first>
primary AI's judgment: <accept | disagree | defer-to-human>
next action: <fix immediately | open ticket | no action>
```

Fixed format matters because the human reviewing the summary needs to skim 5 of these quickly and form a decision. Free-form prose here reliably drowns the decision.

---

## 4 · Default to the reviewer on conflict

When the primary AI and the reviewer disagree:

1. **Default position**: the reviewer is correct.
2. **If the primary AI disagrees**: write a short dissent. Let the human arbitrate.
3. **Never silently ignore a reviewer finding** and claim "done."

The default-to-reviewer rule is important because the primary AI has an incentive to close the task; the reviewer has no such incentive. Asymmetric incentives + asymmetric reliability: bet on the reviewer.

A task is not "done" until **both** the primary AI and the reviewer agree there are no outstanding issues. Partial acceptance is still WIP.

---

## 5 · Polling background reviewers

When the reviewer runs in the background (long-running review tools often take several minutes), the primary AI must own the polling loop. Do **not** dispatch and forget.

The shape that works:

1. Dispatch the reviewer in background mode.
2. Continue with other unrelated work.
3. Periodically poll the reviewer's status. Use whatever scheduling primitive your AI tool gives you (most support "wake me up in N seconds").
4. When the reviewer finishes, produce the report-format summary for the user.
5. Only after the summary does the AI declare the work touched by the review as complete.

Users should **only** see the final verdict. They shouldn't have to ask "is it done yet?" They also shouldn't see intermediate "still running" messages unless the review has failed or been running unreasonably long.

---

## 6 · Scope: which artifacts go through review

Not only code. The execute ↔ review split applies to:

- **Specs / design docs** — reviewer challenges the decision framing
- **Implementation plans** — reviewer finds unconsidered edge cases before any code is written
- **Code diffs** — reviewer finds bugs / rule violations / missed tests
- **Bug fixes** — reviewer confirms the fix addresses the real root cause, not just the symptom

Reviewing plans _before_ coding is the highest-leverage use. Most expensive bugs are architectural decisions made under confirmation drift; catching them pre-code is 100× cheaper than catching them in PR.

---

## 7 · What this is NOT

- **Not a democracy.** Two AIs voting is not signal; one AI critiquing another is.
- **Not a replacement for human review.** The human still owns the merge button.
- **Not a universal speedup.** External review adds latency per reviewed artifact. Its value is fewer defects shipped, not faster cycle time.
- **Not a license to skip `harness:check`.** The aggregate check still runs. External review is orthogonal.

---

## 8 · Writing this up as a harness rule

Most teams that adopt external review formalize it as a rule:

```markdown
## R-<id> · External review at trigger points

**Why**: <cite incidents where solo-AI work shipped a defect caught in retro>

**How to apply**: at each trigger point in the table above, invoke the reviewer.
The task is not done until both AIs agree.

**Auto-check**: manual — the AI self-reports invoking. Lapses show up as
retrospective items: "did we review before declaring done?"
```

Register the rule in `config.yaml` with `auto_check: ai-self-discipline`. This rule will never have a grep-able check; its enforcement is in the session-start ritual and in retro.
