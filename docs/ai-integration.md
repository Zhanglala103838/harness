# AI integration

Harness is AI-agnostic. The contract is the same regardless of which tool you use:

> **Before writing any code, the AI states: _"Read `.harness/session-start.md` · task type = `<X>` · rules in scope = `<R-a, R-b, …>`."_**

This section walks through how to wire that up for several common tool shapes. Tooling names are deliberately omitted — the patterns work with any assistant that supports them.

---

## Pattern 1 — project-root instructions file

Many AI tools look for a markdown file at the repo root and inject it into every session's system prompt. File names vary by tool (`CLAUDE.md`, `GEMINI.md`, `AGENTS.md`, `.cursorrules`, `.aider.conf.yml`, `.github/copilot-instructions.md`, etc.). The content is the same:

```markdown
# Project instructions

Before writing code, you MUST:

1. Read `.harness/session-start.md` and execute its actions.
2. State which task type from `.harness/config.yaml` applies.
3. List the rules from `rules_must_check` for that task type.
4. If you find a rule conflict — stop and report. Do not route around.

Run `npm run harness:check` (or the project's equivalent) before claiming the change is done.
```

Most tools pick this up automatically. If yours requires explicit wiring, point it at the file.

---

## Pattern 2 — session-start hook

Some tools support a "session start" hook that runs a shell command or injects context automatically. This is the most robust integration because the user doesn't have to remember. Typical shape:

```bash
# Pseudo-hook — adapt to your tool's hook syntax
on_session_start() {
  cat .harness/session-start.md
  echo ""
  echo "--- active rules (from config.yaml) ---"
  grep -E "^  [a-z_-]+:" .harness/config.yaml | head -20
}
```

If your tool supports this, use it. The AI gets the harness context without relying on the user remembering to prompt for it.

---

## Pattern 3 — explicit per-prompt reminder

For tools without auto-injection: put a one-line reminder at the top of your prompts.

```
[Harness active] Before writing code, read .harness/session-start.md and state task type + rules in scope.

<actual task>
```

Less reliable, but works with any chat-style interface.

---

## Pattern 4 — CI gate

Even if the AI ignores everything, the CI gate still catches violations. Add a step that runs `harness:check` on every pull request and fails the build on any violation.

This is the last line of defense. Don't rely on it as the first — catching violations before code is written is always cheaper than catching them after.

---

## What the AI should actually do

The session-start actions in order:

1. **Declare layer** — "this touches `<engine>` and `<service>`"
2. **Classify task** — "task type = `<feature_change>`"
3. **Read rules** — "applicable: `R-3`, `R-7`" (skim their Why and How-to-apply)
4. **Report intent** — one sentence: goal + layer + task type + rules + no conflicts
5. **Implement**
6. **Self-check** — run `harness:check`, fix any failure before claiming done
7. **Self-review** — answer the four blind-spot questions from `session-start.md` Action 6

A session opening without steps 1–4 is not compliant. Reject the PR in review.

---

## When the AI violates

Typical failure mode: the AI writes a diff that passes tests and compiles but routes around a rule. The violation shows up in `harness:check`.

Two responses:

1. **If the violation is real** — the AI should revise the diff. It's allowed to ask "should I request an exemption instead?" but the default is fix.
2. **If the rule is wrong** — the AI should propose a rule change via `evolve.md` Model A, with citations. Not silently edit the rule file; that's a separate PR.

If the same AI session silently modifies both code and rule in a way that weakens the harness, that's a red flag. The reviewer should look extra carefully.

---

## Rule templates, AI-specific

Some rules are specifically about AI behavior (meta-rules). A few patterns worth seeding:

- **"Ground diagnoses in config, not key names"** — before the AI claims `"field X must be…"`, it must have queried the authoritative source (schema, DB, spec), not guessed from a JSON key name.
- **"Don't outsource investigation legwork"** — before asking a human to run an SQL / curl / screenshot, the AI tries with its own tools.
- **"Don't touch running processes"** — the AI's `pkill`/`killall` patterns must not match the user's dev server. Use explicit PIDs captured from children the AI spawned itself.

These don't have grep-able checks. They live in `session-start.md` and PR review, and they're enforced by observed behavior over time.

---

## One final note

The AI integration is easier to maintain if you don't over-customize per tool. Keep `session-start.md` generic; let each AI tool adapt via its own system-prompt mechanism. When you switch tools (you will), the harness transfers without rewrites.
