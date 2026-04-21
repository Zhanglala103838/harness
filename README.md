# Harness

📖 中文文档: [README.zh-CN.md](./README.zh-CN.md) · **Latest: v0.3.0** ([CHANGELOG](./CHANGELOG.md))

> **Harness is not a linter. Harness is how your codebase stops repeating the same architectural mistake.**

`.harness/` is a drop-in folder for your repository that turns past incidents into guardrails — rules your code and your AI coding agents can't silently route around.

- **Not a lint replacement.** ESLint, Prettier, `tsc`, `pylint` already handle code style. Harness handles the boundaries _those_ tools can't see: layer leaks, parallel sources of truth, drift between config and code, metadata interpreted in the wrong layer.
- **Built for AI-era codebases.** When AI coding agents produce most of the diff, the only lasting leverage is hard boundaries they must read before touching code. Harness encodes those boundaries as three synced layers: **spec → rules → checks**.
- **Two rule families.** **Architecture rules** (R-*) encode _what the code looks like_ — grep-able. **Meta-rules** (MR-*) encode _how the AI reasons_ before it writes the code — review-only. [Read more →](./docs/meta-rules.md)
- **Self-evolving.** Rules are born, graduate to stable, and retire. The harness checks its own health so dead rules don't rot.

---

## What's new in 0.3.0

- **[Meta-rules family](./docs/meta-rules.md)** (MR-*) — cognitive rules that catch _reasoning_ failures the way structural rules catch _code_ failures.
- **[Hook integration](./docs/hook-integration.md)** — `SessionStart` + `PreToolUse` hooks that make the harness unavoidable, not opt-in.
- **[External-review protocol](./docs/external-review.md)** — two-AI collaboration: primary does the work, reviewer AI invoked at fixed triggers; defaults to reviewer on conflict.
- **Three new seeded meta-rule examples** — schema-before-ui-patch, real-verification-over-mocks, ui-purpose-first.
- **`config.yaml` schema extended** with six optional fields: `trigger_phrases`, `hard_stop`, `composition`, `decision_tree`, `consumers`, `meta_rules_must_check`.
- **Session-start ritual** grew from 5 to 9 actions (still ≤ 300 lines): optional bilingual split, verify-template per step, simplicity+surgical gate, ground-diagnoses-in-config, don't-disturb-running-environment.

Full notes: [`CHANGELOG.md`](./CHANGELOG.md).

---

## What you get

```
.harness/
├── README.md                    ← 5-minute on-ramp for your team
├── config.yaml                  ← rules ↔ checks mapping (machine-readable · now with
│                                    trigger_phrases, hard_stop, composition, consumers)
├── session-start.md             ← AI session-start ritual (mandatory read · 9 actions)
├── evolve.md                    ← self-upgrade / self-retire / composition protocol
├── violations-triage.md         ← exemption tracker with expiry dates
├── CHANGELOG.md                 ← versioned rule history
├── rules/
│   ├── _TEMPLATE.md                              ← copy this to author a new rule
│   ├── example-no-parallel-source-of-truth.md    ← architecture rule (R-*)
│   ├── example-read-vendor-source-before-patching.md
│   ├── example-three-strikes-same-file.md
│   ├── example-schema-before-ui-patch.md         ← meta-rule (MR-*)
│   ├── example-real-verification-over-mocks.md   ← meta-rule (MR-*)
│   └── example-ui-purpose-first.md               ← meta-rule (MR-*)
└── checks/
    ├── _TEMPLATE.sh             ← copy this to author a new check
    ├── check-harness-health.sh  ← harness self-health (ships with kit)
    └── <your-check>.sh          ← grep/diff/size enforcement scripts
```

## Three layers, synced

| Layer | Content | Who reads it |
|---|---|---|
| **Spec** (outside `.harness/`, in your repo's `docs/` or `adr/`) | The long-form "why" — architecture decisions, ADRs, post-mortems | Humans + AI during design |
| **Rules** (`.harness/rules/`) | The "what" — one markdown per hard boundary, with Why + How-to-apply + Example | Humans + AI on every code change |
| **Checks** (`.harness/checks/`) | The "enforce" — short bash scripts that grep/diff/count and block PRs | CI + humans before commit |

**Relationship**: Spec decides → downstream to Rule → downstream to Check. A decision that lives only in the spec rots. A check without a rule is a mystery. A rule without a check is a wish.

## Why this exists

In a typical codebase, three kinds of failure keep recurring:

1. **Parallel sources of truth.** The same field / permission / config lives in 3 places, drift silently.
2. **Boundary erosion.** Business logic leaks into the presentation layer; metadata interpretation leaks into services.
3. **Config-driven systems with hardcoded escape hatches.** Someone "just this once" hardcodes a rule that should live in the DB, and it stays forever.

Generic linters can't detect these. They're project-specific patterns your team has _already been burned by_. Harness captures them once, then refuses to let them back in.

## Installation

```bash
# Option A: curl one-liner
curl -fsSL https://raw.githubusercontent.com/Zhanglala103838/harness/main/scripts/install.sh | bash

# Option B: clone + copy
git clone https://github.com/Zhanglala103838/harness.git /tmp/harness
cp -r /tmp/harness/template/.harness ./.harness

# Option C: manual
# Download template/.harness/ and drop into your repo root
```

Then open `.harness/README.md` and edit the placeholders for your project.

## Quick start (5 minutes)

1. **Install** (above).
2. **Edit `.harness/config.yaml`** — set `project:` and list your layers under `layers:`.
3. **Seed 1 rule** — copy `rules/_TEMPLATE.md` to `rules/<your-first-rule>.md`. Pick a real incident you've had twice.
4. **Seed 1 check** — copy `checks/_TEMPLATE.sh` to `checks/check-<your-first-rule>.sh`. Make it grep for the violation.
5. **Wire it up** — add to `package.json` (or Makefile): `"harness:check": "bash .harness/checks/*.sh"`.
6. **Run it** — `npm run harness:check` (or `make harness`). Green = clean. Red = you have debt to pay.
7. **Commit** — from now on, every PR runs this before merge.

Full walkthrough: [`docs/getting-started.md`](./docs/getting-started.md).

## AI integration

Harness is AI-agnostic. It works with:

- Any AI coding agent that can read a markdown file at session start
- IDE-integrated assistants (via their system-prompt / rules-file features)
- CLI-based agents (via an explicit "read `.harness/session-start.md` first" instruction)
- Headless CI agents (via session-start checks)
- **Hook-capable agents** — use `SessionStart` / `PreToolUse` hooks to make the harness unavoidable instead of opt-in. See [`docs/hook-integration.md`](./docs/hook-integration.md).
- **Teams that run two AIs** — primary + reviewer protocol. See [`docs/external-review.md`](./docs/external-review.md).

See [`docs/ai-integration.md`](./docs/ai-integration.md) for concrete wiring patterns across several popular tools.

**The core contract**: the AI must state _"I have read .harness/session-start.md · my task type is X · rules R-a, R-b apply · meta-rules MR-x, MR-y apply"_ before writing code. If it doesn't, reject the PR.

## Bonus patterns (opt-in)

Not required by harness, but often adopted alongside it:

- **[Meta-rules (cognitive family)](./docs/meta-rules.md)** — the MR-* family of rules that encode _how the AI reasons_ before it writes code, alongside the R-* rules that encode _what the code looks like_.
- **[Hook integration](./docs/hook-integration.md)** — SessionStart and PreToolUse hooks make the harness context unavoidable rather than opt-in.
- **[External review](./docs/external-review.md)** — second-opinion protocol: primary AI does the work, a reviewer AI is invoked at fixed trigger points, disagreements default to the reviewer.
- **[Three-pass review pipeline](./docs/review-pipeline.md)** — split code review into bug-finder / security-quality / refactor passes to keep each pass's signal sharp.
- **[Commit convention](./docs/commit-convention.md)** — `<type>(<scope>): <subject>` pairing with harness's per-project CHANGELOG.
- **[Vendor-source-before-patching](./template/.harness/rules/example-read-vendor-source-before-patching.md)** — seeded rule for bugs rooted in third-party component defaults.
- **[Three-strikes rule](./template/.harness/rules/example-three-strikes-same-file.md)** — when the same file gets three bugfix rounds with different diagnoses, stop iterating and escalate for root-cause analysis.
- **[Schema-before-UI-patch](./template/.harness/rules/example-schema-before-ui-patch.md)** — meta-rule: fix the data model; don't paper over missing fields in the view layer.
- **[Real verification over mocks](./template/.harness/rules/example-real-verification-over-mocks.md)** — meta-rule: "tests pass" is not runtime proof for DB / resolver / migration fixes.
- **[UI purpose-first](./template/.harness/rules/example-ui-purpose-first.md)** — meta-rule: before rendering a field, answer "what does the user do on this screen, what does this field contribute, what happens if it's missing."

## Philosophy

Read [`docs/evolution.md`](./docs/evolution.md) for the full story. In one paragraph:

> Rules are born when a failure repeats. They're written down as human-readable markdown. If the failure is grep-able, they graduate to an automated check. If the failure mode disappears (because the architecture removed its root cause), the rule retires. Harness itself checks that this lifecycle doesn't stall — no forgotten exemptions, no dead checks, no rules without documentation. Drift detected in the harness _is itself a signal_.

## What this is NOT

- ❌ A replacement for your linter / type checker / test suite
- ❌ A generic "best practices" rulebook (you'd ignore it)
- ❌ A framework lock-in (it's bash + markdown + YAML)
- ❌ A pre-commit hook kit (Harness doesn't care how you run it — add `husky` / `lefthook` / CI job yourself)
- ❌ An AI jailbreak (humans get just as much value)

## License

MIT — see [`LICENSE`](./LICENSE).

## Contributing

This is early. If you adopt it, file an issue telling us which rules became your most-tripped check within the first 30 days — that's the best signal for what to ship in `examples/`.
