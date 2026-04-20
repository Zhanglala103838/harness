# Changelog

All notable changes to the Harness kit itself (not your per-project `.harness/CHANGELOG.md`).

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
