#!/usr/bin/env bash
# Increments CURRENT_PROJECT_VERSION in project.yml by 1.
# Run before each TestFlight / App Store upload — Apple requires every
# uploaded binary to have a unique build number for the current
# marketing version.
#
# Usage:
#   tools/bump-build.sh           # bumps CURRENT_PROJECT_VERSION by 1
#   tools/bump-build.sh --marketing 1.1.0   # also sets MARKETING_VERSION

set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT=project.yml
[[ -f "$PROJECT" ]] || { echo "project.yml not found"; exit 1; }

current=$(grep -E '^[[:space:]]+CURRENT_PROJECT_VERSION:' "$PROJECT" | head -1 | awk '{print $2}')
next=$((current + 1))

# In-place edit (BSD sed compatible)
sed -i '' "s/^\([[:space:]]*CURRENT_PROJECT_VERSION:\)[[:space:]].*/\1 $next/" "$PROJECT"
echo "CURRENT_PROJECT_VERSION: $current → $next"

if [[ "${1:-}" == "--marketing" && -n "${2:-}" ]]; then
  sed -i '' "s/^\([[:space:]]*MARKETING_VERSION:\)[[:space:]].*/\1 \"$2\"/" "$PROJECT"
  echo "MARKETING_VERSION set to \"$2\""
fi

echo "Re-generating Xcode project…"
xcodegen generate
