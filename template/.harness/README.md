# `.harness/` — your project's guardrail system

> **Harness is not a linter. It's how this codebase refuses to repeat past mistakes.**
> Rules below are the boundaries _this project_ has already been burned by. They're enforced by automated checks and re-read at the start of every AI coding session.

---

## 30-second tour

- **Not**: style guide, lint config, generic "best practices"
- **Is**: boundaries this repo has actually broken, captured as grep-able checks + human-readable rules
- **For humans**: read `rules/` before you refactor; run `npm run harness:check` (or the equivalent) before you commit
- **For AI agents**: read `session-start.md` before writing any code; classify the task; list which rules apply; stop and ask if a rule conflicts

## Directory map

```
.harness/
├── README.md               ← this file
├── config.yaml             ← machine-readable rule ↔ check mapping
├── session-start.md        ← mandatory AI pre-flight ritual
├── evolve.md               ← how rules are born, grow, and retire
├── violations-triage.md    ← tracked exemptions with expiry dates
├── CHANGELOG.md            ← every rule change, versioned
├── rules/                  ← one markdown per hard boundary
└── checks/                 ← bash scripts that enforce rules
```

## Three layers

| Layer | Where | Who uses it |
|---|---|---|
| **Spec** — the "why" | Your existing `docs/` / ADRs / post-mortems | Humans in design review |
| **Rules** — the "what" | `.harness/rules/*.md` | Humans + AI on every change |
| **Checks** — the "enforce" | `.harness/checks/check-*.sh` | CI + humans at commit time |

Decisions flow downward: spec → rule → check. A decision that stays only in the spec will be forgotten.

## How to use this

### Human contributor

1. Before a non-trivial change, skim `rules/` for anything that sounds adjacent to your diff.
2. Before commit, run `npm run harness:check`.
3. If it fails and you genuinely can't fix it right now: add an entry to `violations-triage.md` with an expiry date _within this quarter_. No indefinite exemptions.
4. If you find a new recurring failure mode: propose a rule via `evolve.md` protocol.

### AI coding agent

1. Read `session-start.md` at the start of every session. State "read" and classify the task type.
2. List the rules from `config.yaml` that apply to your task type.
3. If any rule conflicts with what you're about to do, **stop and report**. Do not route around it.
4. After the change, run `npm run harness:check` yourself before claiming done.

### Reviewer

1. First thing on a PR: is `harness:check` green?
2. If the PR touches `.harness/` itself: is there a corresponding `CHANGELOG.md` entry? Did the rule come from ≥ 2 real incidents?
3. If a rule exemption is requested in the PR description: is the expiry date realistic? Add it to `violations-triage.md`.

## Exemptions

Tactical exemption format (in PR description):

```
harness-exempt: R-<id> · <one-line reason> · expires <YYYY-MM-DD>
```

The reviewer mirrors this into `violations-triage.md`. `check-harness-health.sh` warns 14 days before expiry and fails after.

## Retirement

If a rule hasn't caught a violation in 12 consecutive weeks, check whether the architecture has made it redundant (DB constraint, type system, etc.). If yes, mark `@retired on YYYY-MM-DD` in the rule file and delete the check 6 months later. Never silently delete a rule.

---

**Activated**: `<YYYY-MM-DD>` (edit this when you install)
**Version**: see `config.yaml` `harness_version` and `CHANGELOG.md` top entry
