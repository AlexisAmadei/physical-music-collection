#!/usr/bin/env bash
# Usage: scripts/release.sh [major|minor|patch|X.Y.Z]  (default patch)
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
F=app/build.gradle.kts
[ -z "$(git status --porcelain)" ] || { echo "Dirty tree. Commit first."; exit 1; }
[ "$(git branch --show-current)" = main ] || { echo "Not on main."; exit 1; }

cur=$(sed -nE 's/.*versionName = "([0-9.]+)".*/\1/p' $F)
IFS=. read -r ma mi pa _ <<<"$cur.0.0"
case "${1:-patch}" in
  major) new="$((ma+1)).0.0" ;;
  minor) new="$ma.$((mi+1)).0" ;;
  patch) new="$ma.$mi.$((pa+1))" ;;
  [0-9]*) new="$1" ;;
  *) echo "Bad arg: $1"; exit 1 ;;
esac
code=$(( $(sed -nE 's/.*versionCode = ([0-9]+).*/\1/p' $F) + 1 ))

sed -i.bak -E "s/versionName = \"[0-9.]+\"/versionName = \"$new\"/; s/versionCode = [0-9]+/versionCode = $code/" $F && rm $F.bak
git commit -qam "Release v$new"
git tag "v$new"
git push -q origin main "v$new"
gh release create "v$new" --generate-notes --title "v$new"
echo "Released v$new (code $code). CI builds APK."
