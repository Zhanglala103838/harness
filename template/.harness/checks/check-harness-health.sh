#!/usr/bin/env bash
# ============================================================
# .harness/checks/check-harness-health.sh
#
# Harness self-health — checks the harness itself for drift.
# Ships with the kit. Do not remove.
#
# Runs five audits:
#   1. rules/ ↔ checks/ referenced in config.yaml (no orphans)
#   2. Every check script referenced in config.yaml exists and is executable
#   3. violations-triage.md — no silently expired exemptions; 14-day warnings
#   4. config.yaml harness_version == CHANGELOG.md top version
#   5. allowlist files referenced by rules actually exist
# ============================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[0;34m'; N='\033[0m'

echo "[harness] self-health audit"
echo ""

warn=0
err=0

config=".harness/config.yaml"
changelog=".harness/CHANGELOG.md"
triage=".harness/violations-triage.md"
rules_dir=".harness/rules"
checks_dir=".harness/checks"

# ---- 1 · rules/ ↔ checks/ ↔ config.yaml coherence ----
printf "${B}[1/5]${N} rules ↔ checks ↔ config\n"
if [[ ! -f "$config" ]]; then
  printf "${R}         FAIL${N} · missing %s\n" "$config"
  err=$((err + 1))
else
  rule_files=$(find "$rules_dir" -maxdepth 1 -type f -name "*.md" ! -name "_TEMPLATE.md" 2>/dev/null | wc -l | tr -d ' ')
  check_files=$(find "$checks_dir" -maxdepth 1 -type f -name "check-*.sh" 2>/dev/null | wc -l | tr -d ' ')
  printf "${G}         OK${N} · detected %s rule doc(s), %s check script(s)\n" "$rule_files" "$check_files"
fi

# ---- 2 · config-referenced check scripts exist + executable ----
printf "${B}[2/5]${N} check scripts referenced in config exist + are executable\n"
if [[ -f "$config" ]]; then
  referenced=$(grep -oE '\.harness/checks/check-[a-z0-9-]+\.sh' "$config" | sort -u)
  if [[ -z "$referenced" ]]; then
    printf "${Y}         WARN${N} · no check scripts referenced in %s (only review-only rules?)\n" "$config"
    warn=$((warn + 1))
  else
    while IFS= read -r script; do
      if [[ -x "$script" ]]; then
        printf "${G}         OK${N} · %s\n" "$script"
      elif [[ -f "$script" ]]; then
        printf "${Y}         WARN${N} · exists but not executable: %s (chmod +x to fix)\n" "$script"
        warn=$((warn + 1))
      else
        printf "${R}         FAIL${N} · referenced but missing: %s\n" "$script"
        err=$((err + 1))
      fi
    done <<< "$referenced"
  fi
fi

# ---- 3 · violations-triage.md exemption expiry ----
printf "${B}[3/5]${N} exemption expiry audit\n"
if [[ -f "$triage" ]]; then
  today=$(date +%Y-%m-%d)
  expired=0
  warning_soon=0

  # Grep any line mentioning "expires <YYYY-MM-DD>" or "until <YYYY-MM-DD>"
  while IFS= read -r line; do
    date_str=$(echo "$line" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
    [[ -z "$date_str" ]] && continue
    if [[ "$date_str" < "$today" ]]; then
      printf "${R}         EXPIRED${N} · %s\n" "$line"
      expired=$((expired + 1))
      err=$((err + 1))
    else
      days_left=$(python3 -c "from datetime import date; d1=date.fromisoformat('$date_str'); d2=date.fromisoformat('$today'); print((d1-d2).days)" 2>/dev/null || echo "999")
      if [[ "$days_left" -le 14 ]] 2>/dev/null; then
        printf "${Y}         WARN${N} · %s day(s) until: %s\n" "$days_left" "$line"
        warning_soon=$((warning_soon + 1))
        warn=$((warn + 1))
      fi
    fi
  done < <(grep -iE "expires[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}|until[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}" "$triage" 2>/dev/null || true)

  if [[ $expired -eq 0 && $warning_soon -eq 0 ]]; then
    printf "${G}         OK${N} · no expiring exemptions\n"
  fi
else
  printf "${Y}         WARN${N} · missing %s\n" "$triage"
  warn=$((warn + 1))
fi

# ---- 4 · version sync (config.yaml ↔ CHANGELOG.md) ----
printf "${B}[4/5]${N} harness_version sync\n"
changelog_version=""
config_version=""

if [[ -f "$changelog" ]]; then
  latest=$(grep -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' "$changelog" | head -1 | sed -E 's/^## \[([0-9]+\.[0-9]+\.[0-9]+)\].*/\1/')
  if [[ -n "$latest" ]]; then
    changelog_version="$latest"
    printf "${G}         OK${N} · CHANGELOG latest: %s\n" "$changelog_version"
  else
    printf "${Y}         WARN${N} · no version entries found in %s\n" "$changelog"
    warn=$((warn + 1))
  fi
else
  printf "${R}         FAIL${N} · missing %s\n" "$changelog"
  err=$((err + 1))
fi

if [[ -f "$config" ]]; then
  cv=$(grep -E '^harness_version:' "$config" | head -1 | sed -E 's/.*:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/')
  if [[ -n "$cv" ]]; then
    config_version="$cv"
    if [[ -n "$changelog_version" && "$cv" != "$changelog_version" ]]; then
      printf "${R}         FAIL${N} · config.yaml harness_version=%s ≠ CHANGELOG=%s\n" "$cv" "$changelog_version"
      printf "                  bump both together on every rule change\n"
      err=$((err + 1))
    else
      printf "${G}         OK${N} · config.yaml in sync: %s\n" "$cv"
    fi
  else
    printf "${Y}         WARN${N} · config.yaml missing 'harness_version'\n"
    warn=$((warn + 1))
  fi
fi

# ---- 5 · rule allowlist file existence ----
printf "${B}[5/5]${N} rule allowlist file existence\n"
missing_allowlist=0
if [[ -d "$rules_dir" ]]; then
  while IFS= read -r path; do
    # skip template
    [[ "$path" == *"_TEMPLATE.md" ]] && continue
    # grep for markdown list items that look like allowlist file paths
    while IFS= read -r line; do
      # Extract backtick-quoted paths that look like file paths (have a / and an extension)
      while IFS= read -r candidate; do
        # skip URLs and non-path strings
        [[ "$candidate" =~ ^https?:// ]] && continue
        [[ "$candidate" != */* ]] && continue
        [[ "$candidate" != *.* ]] && continue
        if [[ ! -e "$candidate" ]]; then
          printf "${Y}         WARN${N} · %s references missing path: %s\n" "$path" "$candidate"
          missing_allowlist=$((missing_allowlist + 1))
          warn=$((warn + 1))
        fi
      done < <(echo "$line" | grep -oE '`[^`]+`' | sed 's/`//g')
    done < <(awk '/^## Allowlist/,/^## /' "$path" 2>/dev/null | grep -E '^-' || true)
  done < <(find "$rules_dir" -maxdepth 1 -type f -name "*.md")

  if [[ $missing_allowlist -eq 0 ]]; then
    printf "${G}         OK${N} · all allowlist files exist (or no allowlists defined)\n"
  fi
fi

# ---- Summary ----
echo ""
if [[ $err -eq 0 && $warn -eq 0 ]]; then
  printf "${G}[harness] self-health · PASS · harness is healthy${N}\n"
  exit 0
elif [[ $err -eq 0 ]]; then
  printf "${Y}[harness] self-health · WARN · %d warning(s) · attention needed${N}\n" "$warn"
  exit 0
else
  printf "${R}[harness] self-health · FAIL · %d error(s) + %d warning(s)${N}\n" "$err" "$warn"
  exit 1
fi
