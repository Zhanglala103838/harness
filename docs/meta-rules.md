# Meta-rules: cognitive boundaries alongside architectural ones

Harness started as a way to encode **architectural boundaries** — "field truth lives in one place", "services don't re-interpret metadata", "pages don't redo permission scoping". These are structural rules: you can grep for violations, you can fail a CI build, the code either conforms or doesn't.

Once you've been running the harness for a few months on a codebase heavy with AI-generated diffs, a second family of rules emerges. These are not about _structure_. They're about **how the AI reasons** before it writes the structure. We call them **meta-rules**.

---

## Two families

| Family | Examples | Grep-able? | Enforcement |
|---|---|---|---|
| **Architecture rules** (R-*) | "no parallel source of truth", "page doesn't re-filter by permission", "service doesn't interpret metadata" | usually yes | bash check script in `checks/` |
| **Meta rules** (MR-*) | "ground diagnoses in config before speaking", "mocks ≠ runtime proof", "don't outsource investigation legwork", "state a verify plan before writing multi-step code" | rarely | `session-start.md` action + human PR review |

Meta-rules look like they belong in a style guide or an AI system prompt, not a harness. They belong here because:

1. **They recur.** The same reasoning shortcut burns the team on Monday, a different subsystem, same shape of mistake.
2. **They're project-specific.** "Always query `report_columns` before diagnosing field bugs" is not advice that transfers to a non-data-driven project. Generic linters can't hold it.
3. **They benefit from the same evolve protocol.** A meta-rule that catches zero violations for 12 weeks is ready to retire, exactly like an architecture rule.

---

## How meta-rules feel different from architecture rules

- **Naming**: prefix `MR-<n>` instead of `R-<n>`.
- **auto_check**: almost always `review-only` or `ai-self-discipline`. Grep can't see reasoning.
- **Why section**: cites incidents where the AI's _reasoning_ failed, not incidents where the _structure_ failed. "User said 'why are you showing this field', AI had no answer" → meta-rule candidate.
- **How-to-apply**: usually takes the shape of a question the AI asks itself before writing.
- **Triggered from session-start.md**: the AI runs these as part of the pre-flight, not as a post-hoc check.

---

## Example meta-rule shapes worth considering

These are meta-rules many teams discover independently. Seed what fits:

1. **Ground diagnoses in config, not names.** Before claiming "field X behaves like Y", query the config source. JSON key names lie; the config row doesn't.
2. **Mocks ≠ runtime proof.** A unit test passing against a mocked DB is not evidence that a resolver / migration / query actually works. Every DB-touching fix needs a real-data verification.
3. **Don't outsource investigation legwork.** Before asking a human to run SQL / open devtools / copy JSON — ask _"can I do this myself with the tools I have?"_
4. **State a verify plan before writing multi-step code.** Each step of a multi-step task must name a runnable check or observable state. If you can't name the verify, you don't understand the step.
5. **Simplicity + surgical gate.** Before writing code: would a senior engineer call this overcomplicated? Does every changed line trace to the task? Any "no" → revise.
6. **Fix the model, don't patch the UI.** If the data model is missing a piece the UI needs, adding defaults / coercions in the UI is debt. Fix the model first. (`example-schema-before-ui-patch.md`)
7. **Don't display fields without a purpose.** Before adding a field to a UI: what does the user _do_ on this screen; what does this field contribute; what happens if it's missing? No answer → don't add it. (`example-ui-purpose-first.md`)
8. **Don't disturb the user's running environment.** No fuzzy `pkill` patterns. Dev servers and browser sessions are user state, not AI scratch space.

---

## When to promote a meta-rule

The trigger is the same as for architecture rules: **same failure mode, twice, within 30 days**. The shape of the incident is different:

- Architecture rule incident: "we ended up with the same enum in three files."
- Meta-rule incident: "the AI spent 45 minutes diagnosing a symptom that would have disappeared the moment it queried `SELECT * FROM config WHERE key = …`."

Write it up using the same Model A template from `evolve.md`. In the `how-to-apply` section, the rule usually reads as a _question the AI must answer before writing_, not a _pattern the code must avoid_.

---

## When NOT to promote a meta-rule

If the failure mode is really one of:

- Generic coding hygiene (handled by your linter)
- Documentation drift (handled by review)
- Individual AI-tool quirks (handled by that tool's system prompt)

… don't encode it as a meta-rule. Meta-rules are reserved for failure modes that are **project-specific** and **would survive an AI tool swap**. If switching from AI tool A to AI tool B would make the rule obsolete, it's not a meta-rule; it's a prompt tweak.

---

## Meta-rules and the AI contract

The session-start ritual now asks the AI to list both `rules_must_check` and `meta_rules_must_check` for the task type. A compliant opening statement reads:

> "Layer: engine + service. Task type: feature_change. Rules in scope: R-3, R-7. Meta-rules in scope: MR-1, MR-4. No conflicts."

The meta-rules are not decorative. If the AI skips them in the opening statement, the session is out of contract — same as skipping architecture rules.
