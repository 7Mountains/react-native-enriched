#!/usr/bin/env sh
set -e

VERSION=$(node -p "require('./package.json').version")

if [ -z "$VERSION" ]; then
  echo "Usage: ./scripts/release.sh <version>"
  exit 1
fi

echo "→ build (prepare)"
yarn prepare

echo "→ commit lib"
git add lib -f
git commit -m "chore: build lib for v$VERSION" || echo "nothing to commit"

echo "→ create tag v$VERSION"
git tag "v$VERSION"

echo "✓ done"
