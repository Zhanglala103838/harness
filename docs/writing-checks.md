# Writing checks

A harness check is a small bash script that exits 0 (pass) or 1 (fail). Keep them boring — complexity makes checks themselves a maintenance tax.

## The anatomy

Every check script has:

1. **Header comment** — rule ID, rule name, link back to the rule doc.
2. **CONFIG block** — scope glob, file extensions, forbidden pattern, allowlist, hint text.
3. **Scan loop** — iterate matching files, grep for the pattern, count violations.
4. **Summary** — print PASS / FAIL / SKIP with colors, exit appropriately.

Use `_TEMPLATE.sh` as the starting point. If your check doesn't fit that shape, think twice — most harness checks really are "grep for a pattern inside a scope, with an allowlist." Bigger logic belongs in the linter or a proper test.

## Conventions

- **Filename**: `check-<rule-slug>.sh`. The slug should match the rule doc's filename.
- **Shebang**: `#!/usr/bin/env bash`
- **Strict mode**: `set -uo pipefail` (don't use `-e` — you want to handle non-zero inside the loop).
- **Executable**: `chmod +x` it after creation.
- **Exit codes**: 0 = pass, 1 = fail. Use warnings (exit 0 with yellow output) for advisories that shouldn't block.
- **Colors**: use the provided `R G Y B N` ANSI codes. Skip colors if you write to a file (`NO_COLOR` is a bonus feature).
- **Absolute root**: compute `ROOT` from the script's directory, then `cd "$ROOT"`. Checks must work whether run from the repo root or from CI.

## Scan scope

Every check declares its scope:

```bash
SCAN_ROOT="src"
SCOPE_EXTS=("ts" "tsx")
```

If `SCAN_ROOT` doesn't exist (different project layout, first install): exit 0 with a yellow SKIP message. Don't fail.

## Allowlist

Every check that can conflict with existing code has an `ALLOWLIST` array. Entries are absolute-from-repo-root paths:

```bash
ALLOWLIST=(
  "src/legacy/old-thing.ts"
)
```

Keep the allowlist short. Cross-check it with `violations-triage.md` entries — an allowlist file without a triage entry is a silent permanent exemption, which defeats the harness.

## Output format

A user (or AI) reading the output should be able to:

1. See which rule is being checked (`[harness] R-<id> · <name>`)
2. See the exact file:line of each violation
3. See the one-line actionable fix hint
4. See the rule doc path
5. See how to request an exemption

See `check-no-parallel-source-of-truth.sh` for the reference shape.

## What NOT to do in a check

- **Don't parse code with regex beyond grep's grammar.** Grep's regex is enough for "does this pattern appear". If you need AST awareness, use the language's proper tooling (eslint rule / ast-grep / semgrep) and invoke it from the check.
- **Don't make network calls.** Checks run in CI, on dev laptops, on flaky WiFi. Keep them deterministic and local.
- **Don't require secrets.** If you need secrets, it's not a harness check — it's a smoke test.
- **Don't shell out to `rg` or other tools not guaranteed to be installed.** `grep` / `find` / `sed` / `awk` are portable. If you must use something else, fail gracefully with a clear message.
- **Don't write multi-hundred-line scripts.** If you're past ~150 lines, extract shared helpers into `.harness/checks/_lib.sh` or move logic into a proper test.

## Testing a check

Before committing a check:

1. Run against current codebase: `bash .harness/checks/check-<slug>.sh`. Note the violation count.
2. Introduce a known violation in a throwaway file. Re-run. Count should go up by 1.
3. Remove the violation. Re-run. Back to baseline.
4. Break the script (rename a variable). Re-run. It should fail loudly, not silently pass.

## Performance

Harness checks should be fast enough to run on every commit. Typical budget: < 2 seconds per check on a 100k-line codebase. If a check runs slower:

- Scope it more narrowly (`SCAN_ROOT="src/services"` instead of `src/`)
- Short-circuit early (skip if `SCAN_ROOT` doesn't exist, skip subdirectories with `.gitignore`-like exclusions)
- Cache `git ls-files` output once at the top if you iterate many times

## When a check is wrong

If a check has a false positive your allowlist can't cover cleanly:

1. First, try to narrow the `FORBIDDEN_PATTERN`. Often a longer regex fixes it.
2. If the rule itself is too broad, revise the rule doc (`Why`, `How to apply`) and tighten both the doc and the check together.
3. If the false positive reveals the rule doesn't match reality, consider retirement (§ `evolve.md` Model B).

Don't just add `|| true` to silence it. That's the start of a dead check.
