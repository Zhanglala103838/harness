# AI Session Start — Pre-flight ritual

> Every session that touches this repo, an AI coding agent MUST run these actions before writing any code. Keep this file ≤ 200 lines. Prefer short over empty.

---

## Action 1 · Declare layer

State which layer of the architecture this change touches. The layers are defined in `config.yaml` under `layers:`. If the change crosses layers, say so explicitly — don't pretend it's a single-layer change.

> Example: _"This change touches the `engine` layer (adding a new FieldHandler) and the `service` layer (one consumer switches to the new handler). No `meta` / `infra` changes."_

## Action 2 · Classify task type

Look up `config.yaml` → `task_types:`. Name the task type that matches your change. Report which rules (`rules_must_check`) apply.

If no task type matches your change cleanly: stop and propose a new task type via `evolve.md` model A _before_ writing code. A change with no task type is a change with no guardrails.

## Action 3 · Read relevant sections

- `.harness/rules/*.md` — each rule listed under your task type. Skim Why + How-to-apply + Example.
- Your project's design docs / ADRs — relevant sections only, not the whole thing.
- If this is a bug fix: any debug/runbook doc in your project (if present).

## Action 4 · Report intent

Before writing code, post a one-sentence intent:

> _"Goal: `<one line>` · Layer: `<layer>` · Task type: `<type>` · Rules in scope: `R-a, R-b, R-c` · No conflicts found."_

If you find a rule conflict: **stop and report**. Do not route around rules to "finish the task." The right answer is almost always to change the rule, or change the plan.

## Action 5 · Implement and self-check

After implementing, _before_ claiming done:

1. Run the aggregate check: `npm run harness:check` (or whatever your project uses).
2. If any check fails — read the output carefully. Either fix, or request an exemption via `violations-triage.md` (with a real expiry date).
3. Re-read your diff once with rules/ in mind. Is there anything you silently skipped?

## Action 6 · Proactive self-review — find blind spots before the user does

Before committing, answer 4 questions honestly:

1. Did I "just assume" something and take a shortcut?
2. Did I route around / bypass / guess / silently degrade?
3. Did I use compliance-sounding language to wrap suspicious reasoning?
4. If a reviewer notices, which rule would it fall under?

Any "yes" → **immediately** propose a harness upgrade per `evolve.md` model A. Do not wait to be caught.

## Action 7 · Don't outsource diagnostic legwork

Before asking a human teammate to run an SQL query / open devtools / curl an endpoint / copy JSON, ask yourself:

> _"Can I do this myself with the tools I have?"_

- ✅ Yes → do it yourself. The human only confirms conclusions.
- ❌ No (you lack access / it requires visual judgment / it requires tribal knowledge) → ask, but be specific about why you can't.

Two consecutive human-side investigations in one session → stop and reflect. You may be asking wrong questions.

---

## Forbidden patterns

- Editing code without reading the relevant `rules/*.md` first
- "Minimum change to ship" as justification for bypassing a rule
- Silent fallbacks / catch-and-ignore / default-value covers for missing data
- Re-implementing a rule's domain inside a service (e.g. permission checks inside a page component, metadata interpretation inside a service)
- Hardcoding a business rule next to a DB config that already stores it

## When blocked

If an engine/library/framework genuinely can't do what the task requires without violating a rule:

1. Stop writing code.
2. State the blocker clearly: _"Rule R-X forbids Y, but the task requires Y because Z. I see two paths: (a) extend the engine to support Y natively; (b) narrow the task to skip Y. I can't decide this unilaterally."_
3. Wait for the human to decide.

**Do not bypass the harness to finish a task.** A merged PR that violated a harness rule is, by contract, a bug — even if it compiles.
