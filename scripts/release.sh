#!/usr/bin/env bash
# Compute the next semver tag from the latest vX.Y.Z tag, then create and push
# it — which triggers the Release workflow (GoReleaser). No version math by hand.
#
# Usage: scripts/release.sh <major|minor|patch>
set -euo pipefail

bump="${1:-}"
case "$bump" in
  major | minor | patch) ;;
  *)
    echo "usage: $0 <major|minor|patch>" >&2
    exit 2
    ;;
esac

if [ -n "$(git status --porcelain)" ]; then
  echo "error: working tree is dirty — commit or stash first" >&2
  exit 1
fi

git fetch --tags --quiet

latest=$(git tag -l 'v[0-9]*' --sort=-v:refname | head -n1)
latest=${latest:-v0.0.0}
core=${latest#v}
core=${core%%-*} # strip any prerelease suffix
IFS=. read -r major minor patch <<<"$core"
major=${major:-0}
minor=${minor:-0}
patch=${patch:-0}

case "$bump" in
  major)
    major=$((major + 1))
    minor=0
    patch=0
    ;;
  minor)
    minor=$((minor + 1))
    patch=0
    ;;
  patch) patch=$((patch + 1)) ;;
esac

next="v${major}.${minor}.${patch}"

if git rev-parse "$next" >/dev/null 2>&1; then
  echo "error: tag $next already exists" >&2
  exit 1
fi

echo "Release: $latest -> $next ($bump) on $(git rev-parse --short HEAD)"
read -r -p "Create and push tag $next? [y/N] " ans
case "$ans" in
  y | Y) ;;
  *)
    echo "aborted"
    exit 1
    ;;
esac

git tag -a "$next" -m "$next"
git push origin "$next"
echo "Pushed $next — the Release workflow will build and publish it."
