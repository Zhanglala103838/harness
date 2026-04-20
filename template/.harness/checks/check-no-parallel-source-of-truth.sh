#!/usr/bin/env bash
# ============================================================
# .harness/checks/check-no-parallel-source-of-truth.sh
#
# Rule:    R-example · No parallel source of truth
# Source:  .harness/rules/example-no-parallel-source-of-truth.md
#
# Edit FORBIDDEN_NAMES + ALLOWLIST for your project. The shipped list is
# only a starting point.
# ============================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

RULE_ID="R-example"
RULE_NAME="No parallel source of truth"

# Names that duplicate authoritative data and should not be re-exported.
# Tailor this to your codebase (e.g., STATUS_LABELS, ROLE_LABELS, FIELD_ALIAS).
FORBIDDEN_NAMES=(
  "STATUS_LABELS"
  "ROLE_LABELS"
  "FIELD_ALIAS"
  "PERMISSION_MAP"
)

# Files allowed to hold these today (in-flight migration). Each should have
# an expiry tracked in violations-triage.md.
ALLOWLIST=(
  # "src/legacy/status-labels.ts"
)

SCAN_ROOT="src"
DOC_PATH=".harness/rules/example-no-parallel-source-of-truth.md"

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; N='\033[0m'

# If scan root doesn't exist, PASS silently (first-time install / different layout)
if [[ ! -d "$SCAN_ROOT" ]]; then
  printf "${Y}[harness] %s · SKIP${N} · scan root '%s' not found (edit check script for your layout)\n" "$RULE_ID" "$SCAN_ROOT"
  exit 0
fi

# Build the alternation for grep
joined=$(IFS='|'; echo "${FORBIDDEN_NAMES[*]}")
pattern="^export[[:space:]]+const[[:space:]]+(${joined})\\b"

echo "[harness] $RULE_ID · $RULE_NAME"
echo "         scope: $SCAN_ROOT/**/*.{ts,tsx}"
echo "         forbidden exports: ${FORBIDDEN_NAMES[*]}"

violations=0

while IFS= read -r file; do
  is_allowed=0
  for allowed in "${ALLOWLIST[@]}"; do
    [[ "$file" == "$allowed" ]] && is_allowed=1 && break
  done
  [[ $is_allowed -eq 1 ]] && continue

  matches=$(grep -nE "$pattern" "$file" 2>/dev/null || true)
  if [[ -n "$matches" ]]; then
    while IFS= read -r line; do
      printf "${R}  VIOLATION${N} · %s:%s\n" "$file" "$line"
      violations=$((violations + 1))
    done <<< "$matches"
  fi
done < <(find "$SCAN_ROOT" -type f \( -name "*.ts" -o -name "*.tsx" \) -not -path "*/node_modules/*" 2>/dev/null)

if [[ $violations -eq 0 ]]; then
  printf "${G}[harness] %s · PASS${N}\n" "$RULE_ID"
  if [[ ${#ALLOWLIST[@]} -gt 0 ]]; then
    printf "         allowlist (to migrate):\n"
    for f in "${ALLOWLIST[@]}"; do printf "           - %s\n" "$f"; done
  fi
  exit 0
else
  printf "${R}[harness] %s · FAIL · %d violation(s)${N}\n" "$RULE_ID" "$violations"
  printf "${Y}         fix:${N}\n"
  printf "           1. Don't re-export parallel constants — derive from the authoritative source at runtime.\n"
  printf "           2. If this is legacy and migration is in flight → add to ALLOWLIST in this check + violations-triage.md with an expiry.\n"
  printf "         docs: %s\n" "$DOC_PATH"
  exit 1
fi
