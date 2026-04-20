#!/usr/bin/env bash
# ============================================================
# harness installer
#
# Drops template/.harness/ into the current directory.
# Safe to re-run: refuses to overwrite an existing .harness/ folder.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Zhanglala103838/harness/main/scripts/install.sh | bash
#   # or
#   bash scripts/install.sh
# ============================================================
set -euo pipefail

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; B='\033[0;34m'; N='\033[0m'

REPO_URL="${HARNESS_REPO:-https://github.com/Zhanglala103838/harness.git}"
REF="${HARNESS_REF:-main}"

# Detect invocation mode
if [[ -d "template/.harness" ]]; then
  # Running from inside a clone
  SRC="template/.harness"
  MODE="local"
else
  # Running via curl | bash — need to fetch
  TMP=$(mktemp -d)
  trap "rm -rf $TMP" EXIT
  printf "${B}[harness]${N} fetching %s @ %s\n" "$REPO_URL" "$REF"
  git clone --depth 1 --branch "$REF" "$REPO_URL" "$TMP/harness" > /dev/null 2>&1 || {
    printf "${R}[harness] failed to clone %s${N}\n" "$REPO_URL"
    printf "         check HARNESS_REPO / HARNESS_REF env vars\n"
    exit 1
  }
  SRC="$TMP/harness/template/.harness"
  MODE="remote"
fi

TARGET=".harness"

if [[ -d "$TARGET" ]]; then
  printf "${Y}[harness]${N} %s already exists — not overwriting\n" "$TARGET"
  printf "         (rename or remove it if you want a fresh install)\n"
  exit 1
fi

printf "${B}[harness]${N} installing into %s/\n" "$TARGET"
cp -R "$SRC" "$TARGET"

# Ensure check scripts are executable
chmod +x "$TARGET"/checks/*.sh

# Personalize the activation date
today=$(date +%Y-%m-%d)
for f in "$TARGET/config.yaml" "$TARGET/CHANGELOG.md"; do
  # macOS sed uses -i '' (empty-string backup); Linux uses -i alone.
  if sed --version >/dev/null 2>&1; then
    sed -i "s/<YYYY-MM-DD>/$today/g" "$f"
  else
    sed -i '' "s/<YYYY-MM-DD>/$today/g" "$f"
  fi
done

printf "${G}[harness]${N} installed\n"
echo ""
echo "Next steps:"
echo "  1. Open $TARGET/config.yaml — set 'project:' and 'layers:'."
echo "  2. Open $TARGET/rules/_TEMPLATE.md — author your first rule from a real incident."
echo "  3. Wire up the check runner in your package.json / Makefile (see docs/getting-started.md)."
echo "  4. Run: bash $TARGET/checks/check-harness-health.sh"
echo ""
printf "${B}[harness]${N} welcome\n"
