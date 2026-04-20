# Commit convention (optional)

> Harness does not require any commit convention. But most teams benefit from one, and a consistent type vocabulary pairs well with harness's versioned CHANGELOG.

## Format

```
<type>(<scope>): <subject>

<body, optional>

<footer, optional>
```

Based on [Conventional Commits](https://www.conventionalcommits.org/) — the popular and well-tooled standard.

## Types

Minimum set every project should use:

| Type | Meaning |
|---|---|
| `feat` | New user-facing feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Change that neither adds a feature nor fixes a bug |
| `test` | Adding or updating tests |
| `chore` | Tooling, dependencies, build, housekeeping |

Expanded set worth adopting as your team grows:

| Type | Meaning |
|---|---|
| `perf` | Performance improvement without behavior change |
| `style` | Whitespace / formatting / semicolons (not visual style) |
| `ci` | CI config changes |
| `build` | Build system / compiler / bundler changes |
| `security` | Security fix (may overlap with `fix` — use `security` when CVE-worthy) |
| `breaking` | Breaking change (often also flagged with `!` and a BREAKING CHANGE footer) |

## Scopes

Pick scopes that match your architecture, not your file layout. Good scopes name the **subsystem** a reader would think in, not the directory.

Examples (adapt to your project):

- Web app: `api`, `ui`, `db`, `auth`, `billing`
- Monolith: bounded contexts — `orders`, `catalog`, `inventory`, `shipping`
- Monorepo: package names — `core`, `cli`, `web`, `docs`

Harness-specific scope: `harness` — every change to `.harness/` itself.

## Examples

```
feat(billing): add prorated refund calculation
fix(auth): reject expired refresh tokens instead of silently renewing
refactor(orders): extract fulfillment policy into dedicated module
docs(harness): add vendor-source-before-patching rule
perf(db): index orders.created_at for admin dashboard
security(api): patch SSRF in webhook-delivery endpoint
chore(deps): bump typescript 5.3 → 5.4
harness(rules): R-4 · require vendor source citation on third-party patches
```

## Body

The body explains **why**, not what. The diff already shows what. Two or three sentences tying the change to the motivating incident, ticket, or decision is usually enough.

Longer bodies are fine for architectural changes — paste the relevant part of the design doc rather than rewrite it.

## Footer

Common footers:

```
BREAKING CHANGE: <description of what breaks and how to migrate>
Refs: <issue / ticket / spec doc>
Co-authored-by: <name> <email>
```

## Enforcing the format

If you want hard enforcement, add a `commitlint` (or equivalent) hook. But consider soft enforcement first:

- PR title must follow the format (CI check)
- Squash-and-merge uses the PR title as the commit message
- Rejecting style violations in review for a week is usually enough to set the habit

## Why this matters for harness

Harness's per-project `CHANGELOG.md` is most useful when every rule-changing commit has a consistent, machine-parseable form. If you enforce `harness(rules): …` for any `.harness/` edit, generating release notes becomes trivial.
