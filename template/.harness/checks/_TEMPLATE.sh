#!/usr/bin/env bash
# ============================================================
# .harness/checks/check-<slug>.sh — template for a new check
#
# Rule:    R-<id> — <one-line>
# Source:  .harness/rules/<slug>.md
#
# Copy this file, rename, edit the CONFIG block, and wire it into
# config.yaml aggregate.all_checks.
# ============================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# ------------------------------------------------------------
# CONFIG — edit these for your rule
# ------------------------------------------------------------
RULE_ID="R-<id>"
RULE_NAME="<one-line rule name>"
SCOPE_GLOB="src"                                   # directory to scan
SCOPE_EXTS=("ts" "tsx")                            # file extensions to check
ALLOWLIST=(                                        # files exempt from the check
  # "src/legacy/allowed-thing.ts"
)
FORBIDDEN_PATTERN='<PCRE regex>'                   # the grep pattern that indicates violation
HINT_HOW_TO_FIX="<short actionable hint for the developer>"
DOC_PATH=".harness/rules/<slug>.md"

# ------------------------------------------------------------
# Implementation — usually no changes needed below
# ------------------------------------------------------------
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; N='\033[0m'

echo "[harness] $RULE_ID · $RULE_NAME"
echo "         scope: $SCOPE_GLOB/**/*.{$(IFS=,; echo "${SCOPE_EXTS[*]}")}"

violations=0

# Build the find predicate for the configured extensions
find_args=()
for ext in "${SCOPE_EXTS[@]}"; do
  find_args+=(-o -name "*.$ext")
done
# drop leading -o
find_args=("${find_args[@]:1}")

while IFS= read -r file; do
  is_allowed=0
  for allowed in "${ALLOWLIST[@]}"; do
    [[ "$file" == "$allowed" ]] && is_allowed=1 && break
  done
  [[ $is_allowed -eq 1 ]] && continue

  matches=$(grep -nE "$FORBIDDEN_PATTERN" "$file" 2>/dev/null || true)
  if [[ -n "$matches" ]]; then
    while IFS= read -r line; do
      printf "${R}  VIOLATION${N} · %s:%s\n" "$file" "$line"
      violations=$((violations + 1))
    done <<< "$matches"
  fi
done < <(find "$SCOPE_GLOB" -type f \( "${find_args[@]}" \) -not -path "*/node_modules/*" 2>/dev/null)

if [[ $violations -eq 0 ]]; then
  printf "${G}[harness] %s · PASS${N}\n" "$RULE_ID"
  exit 0
else
  printf "${R}[harness] %s · FAIL · %d violation(s)${N}\n" "$RULE_ID" "$violations"
  printf "${Y}         fix:${N} %s\n" "$HINT_HOW_TO_FIX"
  printf "         docs: %s\n" "$DOC_PATH"
  printf "         to exempt: add 'harness-exempt: %s · <reason> · expires <YYYY-MM-DD>' to PR and log it in .harness/violations-triage.md\n" "$RULE_ID"
  exit 1
fi
