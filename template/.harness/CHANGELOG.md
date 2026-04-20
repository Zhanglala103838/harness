# Harness changelog (this project)

> Every rule addition / modification / retirement gets an entry here. Bump `harness_version` in `config.yaml` at the same time.

The format follows [Keep a Changelog](https://keepachangelog.com/).

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
