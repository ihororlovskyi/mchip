#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:?usage: update-cask.sh <version> <sha256> <cask-path>}"
SHA="${2:?usage: update-cask.sh <version> <sha256> <cask-path>}"
CASK="${3:?usage: update-cask.sh <version> <sha256> <cask-path>}"

# macOS sed needs -i ''
sed -i '' -E "s/^[[:space:]]*version \".*\"/  version \"$VERSION\"/" "$CASK"
sed -i '' -E "s/^[[:space:]]*sha256 \".*\"/  sha256 \"$SHA\"/" "$CASK"

echo "Updated $CASK to version $VERSION (sha256 $SHA)"
grep -E "^[[:space:]]*(version|sha256)" "$CASK"
