# Hook integration: making harness unavoidable

Reading `session-start.md` is the weakest form of enforcement: it depends on the AI actually reading it. Hooks turn the harness into something the AI _cannot route around_, because the runtime injects context whether the AI asked for it or not.

This doc covers two hook shapes:

1. **SessionStart** — context injection at the start of every session
2. **PreToolUse** — context injection right before the AI edits a file that touches a registered convention

The examples use Claude Code's `~/.claude/settings.json` hook syntax because that's the most common configuration shape. The pattern transfers to any tool that supports shell-hook style integration points.

---

## 1 · SessionStart hook — guarantee the pre-flight

Without a hook, the AI reads `session-start.md` only if (a) your project instructions remind it to, (b) the AI remembers, and (c) the user notices if the AI skips. Three ways to silently drift.

With a hook, the harness context is always in the first turn's prompt.

### Claude Code example

In `~/.claude/settings.json` (or the project-scoped `.claude/settings.json`):

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "cat .harness/session-start.md 2>/dev/null || true"
          }
        ]
      }
    ]
  }
}
```

The file's contents appear as a system reminder on every new session.

### Generic shape for other tools

Any tool that supports "run a shell command and inject its stdout into the session":

```bash
#!/usr/bin/env bash
# hook-session-start.sh
if [[ -f .harness/session-start.md ]]; then
  echo "--- HARNESS SESSION START ---"
  cat .harness/session-start.md
  echo "--- END ---"
fi
```

---

## 2 · PreToolUse hook — register convention consumers

Architecture rules often have a small set of **consumer files**: files that implement or depend on a specific convention. When the AI edits any of them, one of two things should happen:

1. The AI audits the sibling consumers to check whether they drift.
2. The AI explicitly decides to edit this one consumer in isolation (valid, but must be stated).

A PreToolUse hook forces this choice. When the AI tries to Edit / MultiEdit / Write a registered consumer file, the hook injects an "AUDIT REQUIRED" block into the AI's next prompt. The AI's next message must respond to that block before it's allowed to write.

### Sketch

`.claude/hooks/preedit-consumer-audit.sh`:

```bash
#!/usr/bin/env bash
# Reads the target file path from $CLAUDE_TOOL_ARGS (or the tool-specific env).
# If the path appears in any rules/*.md `consumers:` section, emit the audit block.
set -uo pipefail

target="${1:-}"
[[ -z "$target" ]] && exit 0

matched_rules=()
for rule in .harness/rules/*.md; do
  [[ -e "$rule" ]] || continue
  if grep -qE "^\s*-\s*\`?$target\`?" "$rule"; then
    matched_rules+=("$rule")
  fi
done

[[ ${#matched_rules[@]} -eq 0 ]] && exit 0

cat <<EOF
━━━ CONSUMER AUDIT REQUIRED ━━━
target file: $target
matched rules: ${matched_rules[*]}

Before writing, you MUST produce an audit block in your next message:

━━━ <rule-id> CONSUMER AUDIT ━━━
target:   <file path>
siblings: <other files registered under the same rule · brief status>
decision: <"edit only target" | "edit target + <sibling list>" | "stop + escalate">
reasoning: <one sentence>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
```

Wire it up in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|MultiEdit|Write",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/preedit-consumer-audit.sh \"$CLAUDE_TOOL_FILE_PATH\"" }
        ]
      }
    ]
  }
}
```

### Registering consumers in rules

In any `rules/<your-rule>.md`, include a `consumers:` section:

```markdown
## Consumers

Files that implement this convention. Editing any of them triggers the audit hook.

- `src/engine/field-renderer.ts`
- `src/engine/filter-builder.ts`
- `src/engine/export-formatter.ts`
```

Mirror the list in `config.yaml` under `consumers:` so the list stays machine-readable:

```yaml
consumers:
  my-rule-id:
    - src/engine/field-renderer.ts
    - src/engine/filter-builder.ts
    - src/engine/export-formatter.ts
```

---

## 3 · Why hooks matter more for AI-heavy teams

A rule that lives only in `rules/*.md` is enforced by three lines of defense, in order of reliability:

1. **The AI reads it** (depends on prompt engineering, memory, tool settings)
2. **The human reviewer catches it** (depends on reviewer having the rule loaded in their head)
3. **The aggregate check fails CI** (only catches grep-able violations after the code is written)

Hooks add a fourth line _before_ the first: the AI can't get to the edit without the context being injected.

For cognitive meta-rules (e.g. "audit consumers before editing"), hooks are essentially the only reliable enforcement. A meta-rule that depends on the AI _remembering_ to audit is a meta-rule that quietly fails half the time. A meta-rule backed by a PreToolUse hook is a meta-rule that actually holds.

---

## 4 · Anti-patterns

- **Don't hook everything.** A PreToolUse hook that fires on every file edit becomes noise the AI filters out. Reserve hooks for files on the short list of convention consumers.
- **Don't use hooks to re-implement linters.** If a hook's output is "you used `var` instead of `const`", move it to ESLint. Hooks earn their cost only for project-specific semantic checks that grep can't see.
- **Don't let hook scripts silently succeed.** If the consumer-audit script has a bug and exits 0, the audit never fires and nobody notices. Add a dry-run test that every registered consumer file does trigger the hook.

---

## 5 · Debugging hooks

Claude Code hook debugging quick-reference:

- Check `~/.claude/logs/` for hook stderr
- Run the hook script manually with the same args: `bash .claude/hooks/preedit-consumer-audit.sh 'src/engine/field-renderer.ts'`
- Confirm `CLAUDE_TOOL_FILE_PATH` is the env var your version actually sets (it changes between Claude Code versions — check your local `claude --help`)
- If the hook injection never reaches the AI: hooks fail silently by design. `echo` to stderr for local debugging.
