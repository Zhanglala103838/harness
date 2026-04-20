# Evolution

> The one-page version lives in `template/.harness/evolve.md` (what ships into your repo). This doc is the longer commentary — the reasoning behind the cadence.

## Why harness needs to evolve

A rule written once and frozen is a rule that will be wrong within six months. Your architecture changes. Your database constraints tighten. A class of bug gets fixed at the root. When that happens, the rule is no longer load-bearing — it's dead weight, and every contributor who still has to read it is paying a tax for a benefit that no longer exists.

The alternative is equally bad: not writing rules at all, because "maintaining them is too much work." Then every regression you already paid for in human time gets paid again, because no boundary refused it.

Harness threads the needle with a **lifecycle**. Rules are born from incidents, graduate to checks when they prove their worth, and retire when architecture makes them redundant. The cadence is small — individual reviews happen at commit time, weekly health check, quarterly exemption pass — but it's consistent.

## The lifecycle

```
  draft → active → stable → legacy → retired → deleted
```

Each transition has a trigger:

- **draft → active** when the first automated check is added, or when PR review alone catches it consistently.
- **active → stable** when the rule has caught ≥ 1 real violation in 3 consecutive months. It's now load-bearing.
- **stable → legacy** when the architectural root cause starts to disappear (new DB constraint, type system change, engine refactor). The rule will soon be redundant.
- **legacy → retired** when the rule hasn't caught a violation in 12 weeks AND the architectural fix is confirmed landed.
- **retired → deleted** six months after retirement. The delay is deliberate — if the architecture regressed and the rule becomes relevant again, you want to un-retire, not rewrite.

## What makes harness grow

Three legitimate triggers:

1. **A new class of bug hit twice within 30 days.** Two occurrences in a month is strong signal. One is noise.
2. **A single PR routed around a missing boundary in ≥ 3 files.** That's a symptom of the absence of a rule — someone felt compelled to repeat a workaround.
3. **An allowlist expired.** You either retire the legacy code or renew the exemption with a fresh commitment — both force attention.

What does NOT justify growth:

- "I think this is a best practice."
- "Someone on Twitter said…"
- "We'll need this eventually."
- "The framework docs recommend…"

## What makes harness shrink

- **Zero hits for 12 weeks** — candidate for retirement.
- **Architecture made it redundant** — a DB constraint / type definition now enforces what the rule was guarding. Retire.
- **Rule is tripping too often on false positives** — either narrow the pattern (edit the check) or the rule doesn't match reality (retire).

Shrinkage is as important as growth. A harness that only grows turns into a second linter nobody reads.

## The meta-insight

The pattern that makes harness different from a linter:

> **The harness is a version-controlled record of your team's recurring pain.**

When a new engineer joins, the fastest onboarding is: _"Read `.harness/rules/`. Each file is a bug this team has paid for. Don't make us pay again."_

When an AI coding agent joins (same session, next session, different tool), the same document serves the same purpose. The session-start ritual ensures the agent reads it.

## Avoid two anti-patterns

### "Rule theater"

Symptom: you have 25 rules, 3 of them catch 90% of actual violations, 22 of them exist because someone wanted to look thorough on a PR.

Fix: quarterly review. Any rule with zero hits in 12 weeks moves to legacy. If it stays legacy without architectural justification for another 12 weeks, retire it.

### "Permanent exemption"

Symptom: `violations-triage.md` has entries from 18 months ago with expiry dates that have been renewed four times.

Fix: extensions must come with escalating scrutiny. First extension: fine. Second: demand a completion timeline from the owner. Third: escalate to the rule owner — the architecture probably needs to change, or the rule needs to soften.

## The single observable signal

If you remember one thing: **`check-harness-health.sh` must stay green.** When it goes yellow or red, the harness itself has drifted — a dead reference, an expired allowlist, a version skew between config and changelog. Fix these with the same urgency as a failing test.

A healthy harness has a healthy self-health check. A rotting harness accumulates yellows that nobody chases.
