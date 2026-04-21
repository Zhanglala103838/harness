# Changelog

All notable changes to the Harness kit itself (not your per-project `.harness/CHANGELOG.md`).

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] — 2026-04-21

### Added

- **Meta-rules family** — new family of cognitive rules (MR-*) alongside the existing structural rules (R-*). New doc: `docs/meta-rules.md`.
- **Three seeded meta-rule examples** distilled from real incidents on a mature harness deployment:
  - `example-schema-before-ui-patch.md` — fix the data model, don't coerce in the UI layer.
  - `example-real-verification-over-mocks.md` — "tests pass" is not runtime proof for DB / resolver / migration fixes.
  - `example-ui-purpose-first.md` — answer "what does the user do, what does this field contribute, what happens if it's missing" before rendering.
- **Hook integration doc** (`docs/hook-integration.md`) — SessionStart and PreToolUse hook patterns for Claude Code and generic shell-hook tooling. Covers consumer-registry pattern for file-level audits.
- **External review doc** (`docs/external-review.md`) — two-AI collaboration protocol: primary AI does the work, reviewer AI invoked at fixed trigger points, defaults to reviewer on conflict, "done = both AIs + human agree."
- **Session-start expansion** (`template/.harness/session-start.md` grew from 5 to 9 actions, still ≤ 300 lines):
  - Optional **Action 0** — bilingual language-split discipline for multilingual teams.
  - **Action 2** — `trigger_phrases`, hard-stop gates, composition checks.
  - **Action 4** — verify-template (each step names a runnable check or observable state), simplicity+surgical self-check.
  - **Action 8** — ground diagnoses in config, not names (for config-driven projects).
  - **Action 9** — don't disturb the user's running environment (no fuzzy `pkill`).
- **config.yaml schema** gained six optional fields:
  - `trigger_phrases` — verbatim user-phrase-to-task-type mapping (any language).
  - `hard_stop` — mid-task condition that forces re-classification.
  - `composition` — explicit resolution when two task types overlap on the same artifact.
  - `decision_tree` — named sub-paths inside one task type.
  - `consumers` — file-level rule-consumer registry (pairs with PreToolUse hooks).
  - `meta_rules_must_check` — cognitive rules separate from architectural rules.
- **evolve.md** gained §5 (meta-rules family) and §6 (task-type composition).

### Changed

- README bonus-patterns list expanded with the three new meta-rule examples and three new docs.
- `template/.harness/config.yaml` bumped to `harness_version: 0.3.0` with inline schema documentation for the new fields.

## [0.2.0] — 2026-04-20

### Added

- New seeded rule: `example-read-vendor-source-before-patching.md` — requires citing vendor source before patching third-party component behavior.
- New seeded rule: `example-three-strikes-same-file.md` — three bugfix rounds with differing diagnoses on the same file pause further patching and require root-cause re-analysis.
- New doc: `docs/review-pipeline.md` — three-pass review pattern (bug-finder / security-quality / refactor).
- New doc: `docs/commit-convention.md` — Conventional-Commits-based commit format.

### Changed

- README cross-links to bonus patterns (review pipeline, commit convention, vendor-read rule, three-strikes rule).

## [0.1.0] — 2026-04-20

### Added

- First public release.
- Template `.harness/` folder with skeleton `config.yaml`, `session-start.md`, `evolve.md`, `violations-triage.md`, per-project `CHANGELOG.md`, and `README.md`.
- One worked example rule (`example-no-parallel-source-of-truth.md`) plus its enforcing check (`check-no-parallel-source-of-truth.sh`).
- Self-health check (`check-harness-health.sh`) that audits rule/check pairing, allowlist file existence, exemption expiry, and version sync.
- Authoring templates (`rules/_TEMPLATE.md`, `checks/_TEMPLATE.sh`).
- `scripts/install.sh` one-shot installer.
- Docs: getting-started, writing-rules, writing-checks, evolution, ai-integration.

### Philosophy baked in

- Three-layer model (spec → rules → checks).
- Rule lifecycle (draft → active → stable → legacy → retired → deleted).
- Self-bootstrapping AI session-start ritual.
- Self-upgrade triggers (incident ≥ 2× in 30 days → new rule).
- Self-retirement triggers (rule hits zero for 12 weeks → downgrade).
- Quarterly exemption review.
