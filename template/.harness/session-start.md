# AI Session Start — Pre-flight ritual

> Every session that touches this repo, an AI coding agent MUST run these actions before writing any code. Keep this file ≤ 300 lines. Prefer short over empty.

---

## Action 0 · Language split (optional, for multilingual teams)

If your team communicates in a language other than English but the codebase is English: declare the split up-front so the AI doesn't mix them.

| Layer | Language |
|---|---|
| Internal reasoning · plans · diagnosis · self-review | **English** (more training data, less ambiguity) |
| Source code · SQL · identifiers · comments | **English** |
| `.harness/*` rules / configs | **English** |
| Commit type(scope) | **English** |
| User-facing replies / PR narrative / issue bodies | **user's language** |
| Business domain terms in diagrams | user's language (retained) |

**Self-check before every response**:
1. Was my internal reasoning in English? (yes → continue · no → re-think)
2. Is my user-facing output in the user's language? (yes → send · no → translate)
3. Are my code / comment / harness edits in English? (yes → write · no → fix)

Delete this section if your team works in English only.

---

## Action 1 · Declare layer

State which layer of the architecture this change touches. The layers are defined in `config.yaml` under `layers:`. If the change crosses layers, say so explicitly — don't pretend it's a single-layer change.

> Example: _"This change touches the `engine` layer (adding a new FieldHandler) and the `service` layer (one consumer switches to the new handler). No `meta` / `infra` changes."_

## Action 2 · Classify task type

Look up `config.yaml` → `task_types:`. Name the task type that matches your change. Report which rules (`rules_must_check`) and meta-rules (`meta_rules_must_check`) apply.

If your project uses `trigger_phrases:` (verbatim user phrase → task type mapping), check whether the current request matches any listed phrase. Verbatim phrase matching catches task classification drift that path-based matching misses.

If no task type matches your change cleanly: stop and propose a new task type via `evolve.md` model A _before_ writing code. A change with no task type is a change with no guardrails.

**Composition check** (when two task types overlap on the same artifact): if `config.yaml` declares a `composition:` section resolving the overlap, follow it. Otherwise, declare the composition unresolved and escalate before writing code. See `evolve.md` §6.

**Hard-stop gates** (if your project's task type declares one): re-read it before writing code. Mid-task, if you discover you've crossed into a neighboring task type's territory, **stop** and report — do not silently extend the current task's remit.

## Action 3 · Read relevant sections

- `.harness/rules/*.md` — each rule listed under your task type. Skim Why + How-to-apply + Example.
- Your project's design docs / ADRs — relevant sections only, not the whole thing.
- If this is a bug fix: any debug/runbook doc in your project (if present).

## Action 4 · Report verifiable intent

Before writing code, post a one-sentence intent plus a per-step verify plan.

**Intent line**:
> _"Goal: `<one line>` · Layer: `<layer>` · Task type: `<type>` · Rules in scope: `R-a, R-b` · Meta-rules: `MR-x, MR-y` · No conflicts found."_

**Verify template** (required for any multi-step task):
```
1. <step> → verify: <exact command / SQL / UI state / log line>
2. <step> → verify: <…>
3. <step> → verify: <…>
```

"Make it work" / "fix it" alone is not a verifiable goal. Each step must name a runnable check or an observable state. If you can't name the verify, you don't yet understand the step well enough to write it.

**Simplicity + surgical self-check** (before writing code):
- Would a senior engineer call this diff overcomplicated? (simplicity)
- Does every changed line trace back to this task? (surgical)
- Any "no" → revise the plan before you write.

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

## Action 8 · Ground diagnoses in config, not names (data-driven systems only)

Skip this action if your project has no config-driven layer.

Before diagnosing any bug that involves a configurable field / rule / permission / flag, run the authoritative query before you speak:

```bash
# Example — replace with your project's actual config source
SELECT key, type, semantics, owner FROM <config_table>
 WHERE scope = <current_scope>
   AND (key IN (<candidate_keys>) OR label LIKE '<keyword>%')
```

Never infer semantics from variable names alone. JSON key names, camelCase identifiers, and hard-coded label maps drift from the truth; the config is the truth. If your reasoning cites a key name without citing the underlying row, you're guessing.

## Action 9 · Don't disturb the user's running environment

Dev servers, long-running processes, browser sessions, IDE daemons — these belong to the user. The AI **must not** disturb them.

- ❌ **Forbidden**: fuzzy kills like `pkill -f "next dev"` / `pkill -f "vue-cli-service"` / `killall node` — they match and kill the user's own processes.
- ✅ If the AI needs its own smoke run: capture PID at start (`DEV_PID=$!`), only `kill $DEV_PID`, and use a non-default port.
- ✅ **Port already in use** → assume the user is running it. Skip the smoke, rely on typecheck / unit tests.
- ✅ The user's hot-reload is their normal state; the AI must not create anomalies.

---

## Forbidden patterns

- Editing code without reading the relevant `rules/*.md` first
- "Minimum change to ship" as justification for bypassing a rule
- Silent fallbacks / catch-and-ignore / default-value covers for missing data
- Re-implementing a rule's domain inside a service (e.g. permission checks inside a page component, metadata interpretation inside a service)
- Hardcoding a business rule next to a DB config that already stores it
- Claiming "tests pass" as proof of a runtime / DB / resolver fix — mocks are not evidence for behavior that runs against real state. See `example-real-verification-over-mocks.md`.

## When blocked

If an engine/library/framework genuinely can't do what the task requires without violating a rule:

1. Stop writing code.
2. State the blocker clearly: _"Rule R-X forbids Y, but the task requires Y because Z. I see two paths: (a) extend the engine to support Y natively; (b) narrow the task to skip Y. I can't decide this unilaterally."_
3. Wait for the human to decide.

**Do not bypass the harness to finish a task.** A merged PR that violated a harness rule is, by contract, a bug — even if it compiles.
