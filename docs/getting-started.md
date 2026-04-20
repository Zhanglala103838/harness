# Getting started

A 15-minute walkthrough from empty repo to a harness catching its first violation.

## 1 · Install

Pick one:

```bash
# One-liner (recommended once you trust this kit)
curl -fsSL https://raw.githubusercontent.com/Zhanglala103838/harness/main/scripts/install.sh | bash

# Or clone + copy
git clone https://github.com/Zhanglala103838/harness.git /tmp/harness
cp -r /tmp/harness/template/.harness ./.harness
chmod +x .harness/checks/*.sh
```

Commit it:

```bash
git add .harness
git commit -m "chore: install harness kit"
```

## 2 · Edit the basics

Open `.harness/config.yaml` and fill in:

- `project:` — your repo slug
- `activated:` — today's date
- `layers:` — 3–5 layers that describe your architecture

Open `.harness/README.md` and edit the `Activated` line at the bottom.

Open `.harness/CHANGELOG.md` and replace `<YYYY-MM-DD>` with today's date.

## 3 · Pick your first rule

**Don't** install rules speculatively. Harness only works when each rule comes from real pain.

Find a recent bug that:

- Recurred at least twice
- Would have been caught if a boundary had existed
- Is describable as a grep-able pattern

That's your rule 0.

Copy the template:

```bash
cp .harness/rules/_TEMPLATE.md .harness/rules/my-first-rule.md
```

Fill in Why (≥ 2 incidents), the boundary, the decision tree, the violation + correct examples.

## 4 · Write the check

Copy the check template:

```bash
cp .harness/checks/_TEMPLATE.sh .harness/checks/check-my-first-rule.sh
chmod +x .harness/checks/check-my-first-rule.sh
```

Edit the CONFIG block at the top — set `RULE_ID`, `RULE_NAME`, `SCOPE_GLOB`, `FORBIDDEN_PATTERN`. Keep the rest as-is.

Test it against the current codebase:

```bash
bash .harness/checks/check-my-first-rule.sh
```

If it fires on things you want to keep: add them to `ALLOWLIST`, each with an expiry date in `violations-triage.md`.

## 5 · Wire up the aggregate

Add to your `package.json` (or equivalent):

```json
{
  "scripts": {
    "harness:check": "bash -c 'for f in .harness/checks/check-*.sh; do bash \"$f\" || exit 1; done'",
    "harness:health": "bash .harness/checks/check-harness-health.sh",
    "harness:all": "npm run harness:check && npm run harness:health"
  }
}
```

Or Makefile:

```makefile
harness:
	@for f in .harness/checks/check-*.sh; do bash $$f || exit 1; done

harness-health:
	@bash .harness/checks/check-harness-health.sh

harness-all: harness harness-health
```

## 6 · Wire into your AI tool

Point your AI assistant at `.harness/session-start.md`. Exact mechanism depends on the tool — see [`ai-integration.md`](./ai-integration.md).

At minimum, the AI should be instructed to:

1. Read `.harness/session-start.md` before writing any code.
2. State which task type (from `config.yaml`) applies.
3. State which rules apply.
4. Run `harness:check` before claiming done.

## 7 · Wire into CI (optional, recommended after the first week)

GitHub Actions example:

```yaml
name: harness
on: [pull_request]
jobs:
  harness:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: harness check
        run: |
          chmod +x .harness/checks/*.sh
          bash -c 'for f in .harness/checks/check-*.sh; do bash "$f" || exit 1; done'
      - name: harness self-health
        run: bash .harness/checks/check-harness-health.sh
```

## 8 · Iterate

After a week, ask:

- Did anyone hit this rule by surprise? (Good — it caught real drift.)
- Did anyone hit it by mistake and rage-exempt? (Check the allowlist is realistic.)
- Is there a second pattern you've hit twice since installing? (Time for rule 2.)

Follow the cadence in [`evolution.md`](./evolution.md).

---

## Common first-install pitfalls

**"The check fires 200 times on install."**
That's okay. You've accumulated debt. Either allowlist everything today with a 90-day expiry and migrate over a quarter, or narrow the rule.

**"The AI ignores `session-start.md`."**
Check your AI tool's system-prompt / rules-file wiring. If the tool doesn't support auto-injection, put a one-line reminder at the top of every prompt: _"Read `.harness/session-start.md` first and state which rules apply."_

**"The health check complains `harness_version` doesn't match."**
You changed a rule without bumping `config.yaml` → `harness_version` + adding a `CHANGELOG.md` entry. Do both together — it's how you know the harness isn't rotting.

**"My repo has no `src/`."**
Every example check assumes `src/`. Edit `SCAN_ROOT` / `SCOPE_GLOB` at the top of each check script for your layout.
