#!/usr/bin/env bash
# ============================================================
# .harness/checks/check-legacy-allowlist-staged-migration.sh
#
# Rule:    R-example · Legacy allowlist with dated marker
# Source:  .harness/rules/example-legacy-allowlist-staged-migration.md
#
# Pattern: install a new rule against a codebase with 5+ existing violations.
# Files in LEGACY_ALLOWLIST may carry the forbidden pattern, but only if they
# also carry exactly one `@<rule-id>-legacy until=YYYY-MM-DD` marker that has
# not expired. Missing / duplicate / expired markers FAIL the check.
#
# Edit RULE_ID, MARKER_TAG, FORBIDDEN_PATTERN, SCOPE_DIRS, and LEGACY_ALLOWLIST
# for your project.
# ============================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# ------------------------------------------------------------
# CONFIG — edit these for your rule
# ------------------------------------------------------------
RULE_ID="R-example"
RULE_NAME="Legacy allowlist with dated marker"

# Tag used in source-file markers. Keep it short and unique. Convention:
# `@<rule-id-lowercase>-legacy`. Example: R29 → `@r29-legacy`.
MARKER_TAG="@r-example-legacy"

# Directories to scan. Bash 3.x portable — no globstar.
SCOPE_DIRS=(
  # "src/app/api/dashboards"
  # "src/app/api/customers"
  # "src/app/api/orders"
  # "src/app/api/reports"
)

# File extensions inside SCOPE_DIRS to audit.
SCOPE_EXTS=("ts" "tsx")

# The forbidden hand-rolled pattern. Tighten or relax for your project.
# Example: "data_scope[[:space:]]*={2,3}[[:space:]]*['\"]self['\"]"
FORBIDDEN_PATTERN='<edit-me-PCRE-regex>'

# Companion pattern that proves the consumer used the contract API.
# If the file contains BOTH the forbidden pattern AND this pattern, the
# contract is being used and the forbidden pattern is incidental — pass.
# Example: "buildScopeQuery[[:space:]]*\("
CONTRACT_CALL_PATTERN='<edit-me-contract-call>'

# Files allowed to retain the forbidden pattern during migration.
# Each must carry exactly one `<MARKER_TAG> until=YYYY-MM-DD` in its source.
LEGACY_ALLOWLIST=(
  # "src/app/api/dashboards/stats/route.ts"
  # "src/app/api/dashboards/widget-data/route.ts"
)

DOC_PATH=".harness/rules/example-legacy-allowlist-staged-migration.md"
HINT_HOW_TO_FIX="Use the contract API instead of hand-rolling. Legacy files must carry exactly one '${MARKER_TAG} until=YYYY-MM-DD' header marker."

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; N='\033[0m'

echo "[harness] $RULE_ID · $RULE_NAME"

# ------------------------------------------------------------
# Skip when scope is empty (first install / different layout)
# ------------------------------------------------------------
if [[ ${#SCOPE_DIRS[@]} -eq 0 ]]; then
  printf "${Y}[harness] %s · SKIP${N} · SCOPE_DIRS empty (edit check script for your layout)\n" "$RULE_ID"
  exit 0
fi

# Build find predicate for extensions
ext_args=()
for ext in "${SCOPE_EXTS[@]}"; do
  ext_args+=(-o -name "*.$ext")
done
ext_args=("${ext_args[@]:1}")

# Collect files
FILES=()
for dir in "${SCOPE_DIRS[@]}"; do
  [[ ! -d "$dir" ]] && continue
  while IFS= read -r -d '' f; do
    FILES+=("$f")
  done < <(find "$dir" -type f \( "${ext_args[@]}" \) -not -path "*/node_modules/*" -print0 2>/dev/null)
done

if [[ ${#FILES[@]} -eq 0 ]]; then
  printf "${Y}[harness] %s · SKIP${N} · no files in scope\n" "$RULE_ID"
  exit 0
fi

# ------------------------------------------------------------
# Strip /* */ block comments and // line comments before forbidden-pattern grep.
# Bash 3.x portable. Pure awk; no node, no python.
# ------------------------------------------------------------
strip_comments() {
  awk '
    BEGIN { in_block = 0 }
    {
      line = $0
      if (in_block) {
        if (match(line, /\*\//)) { in_block = 0; line = substr(line, RSTART + 2) }
        else { print ""; next }
      }
      while (match(line, /\/\*/)) {
        pre = substr(line, 1, RSTART - 1)
        rest = substr(line, RSTART + 2)
        if (match(rest, /\*\//)) {
          line = pre substr(rest, RSTART + 2)
        } else {
          line = pre
          in_block = 1
          break
        }
      }
      sub(/\/\/.*/, "", line)
      print line
    }
  ' "$1"
}

is_legacy_allowed() {
  local path="$1"
  local allowed
  for allowed in "${LEGACY_ALLOWLIST[@]}"; do
    [[ "$path" == "$allowed" ]] && return 0
  done
  return 1
}

# Returns one marker per line (so we can count + extract the date).
legacy_markers() {
  local path="$1"
  grep -Eo "${MARKER_TAG}[[:space:]]+until=[0-9]{4}-[0-9]{2}-[0-9]{2}" "$path" || true
}

violations=0
audited=0
legacy=0
today="$(date +%F)"

for file in "${FILES[@]}"; do
  [[ ! -f "$file" ]] && continue
  audited=$((audited + 1))

  if is_legacy_allowed "$file"; then
    markers="$(legacy_markers "$file")"
    marker_count="$(printf "%s\n" "$markers" | sed '/^$/d' | wc -l | tr -d '[:space:]')"
    until_date="$(printf "%s\n" "$markers" | sed -n '1s/.*until=//p')"

    if [[ "$marker_count" -eq 0 ]]; then
      printf "${R}  VIOLATION${N} · %s is in LEGACY_ALLOWLIST but has no %s until=YYYY-MM-DD marker\n" "$file" "$MARKER_TAG"
      violations=$((violations + 1))
    elif [[ "$marker_count" -gt 1 ]]; then
      printf "${R}  VIOLATION${N} · %s has %s %s markers; keep exactly one dated marker\n" "$file" "$marker_count" "$MARKER_TAG"
      violations=$((violations + 1))
    elif [[ "$until_date" < "$today" ]]; then
      printf "${R}  VIOLATION${N} · %s legacy marker expired on %s\n" "$file" "$until_date"
      violations=$((violations + 1))
    fi
    legacy=$((legacy + 1))
    continue
  fi

  stripped="$(strip_comments "$file")"

  # Forbidden pattern present?
  forbidden=$(echo "$stripped" | grep -nE "$FORBIDDEN_PATTERN" || true)
  [[ -z "$forbidden" ]] && continue

  # Forbidden present, but contract API also used → file already migrated.
  if echo "$stripped" | grep -qE "$CONTRACT_CALL_PATTERN"; then
    continue
  fi

  printf "${R}  VIOLATION${N} · %s hand-rolls forbidden pattern without using the contract API\n" "$file"
  while IFS= read -r hit; do
    printf "              %s\n" "$hit"
  done <<< "$forbidden"
  violations=$((violations + 1))
done

echo
if [[ $violations -eq 0 ]]; then
  printf "${G}[harness] %s · PASS${N} · %d file(s) audited · %d legacy file(s) deferred\n" "$RULE_ID" "$audited" "$legacy"
  exit 0
else
  printf "${R}[harness] %s · FAIL · %d violation(s)${N}\n" "$RULE_ID" "$violations"
  printf "${Y}         fix:${N} %s\n" "$HINT_HOW_TO_FIX"
  printf "         docs: %s\n" "$DOC_PATH"
  exit 1
fi
