# Harness changelog (this project)

> Every rule addition / modification / retirement gets an entry here. Bump `harness_version` in `config.yaml` at the same time.

The format follows [Keep a Changelog](https://keepachangelog.com/).

## [0.3.0] — <YYYY-MM-DD>

### Added

- Three seeded meta-rule examples covering common cognitive failure modes:
  - `example-schema-before-ui-patch.md` — fix the data model, don't coerce in the UI
  - `example-real-verification-over-mocks.md` — "tests pass" is not runtime proof
  - `example-ui-purpose-first.md` — answer "why show this" before rendering
- `config.yaml` gained optional schema fields: `trigger_phrases`, `hard_stop`, `composition`, `decision_tree`, `consumers`, `meta_rules_must_check`.
- `session-start.md` extended: optional Action 0 (language split), Action 4 verify-template, simplicity+surgical gate, Action 8 (ground diagnoses in config), Action 9 (don't disturb the user's running environment).

## [0.1.0] — <YYYY-MM-DD>

### Added

- Installed harness kit at version 0.1.0.
- Seeded `rules/example-no-parallel-source-of-truth.md` + enforcing check.
- Seeded self-health check (`checks/check-harness-health.sh`).

<!--
Future entry template — copy this when you bump:

## [0.2.0] — YYYY-MM-DD

### Added
- R-<id> (`<slug>`): <one-line description>. Triggered by <incident refs>. Check: <script path>.

### Changed
- R-<id>: tightened allowlist — removed `<path>` (architecture migration complete).

### Deprecated
- R-<id>: marked @legacy — zero hits for 12 weeks, replaced by <DB constraint / type>.

### Removed
- R-<id>: deleted file + check after 6-month retirement hold.

### Fixed
- `check-<slug>.sh`: false positive when <condition> (thanks <contributor>).
-->
