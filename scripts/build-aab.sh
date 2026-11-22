#!/usr/bin/env bash
# Usage: scripts/build-aab.sh   Builds a signed release AAB using .env.signing.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
[ -f .env.signing ] || { echo "Missing .env.signing (see .env.signing.example)."; exit 1; }
set -a; . ./.env.signing; set +a
for v in SIGNING_STORE_FILE SIGNING_STORE_PASSWORD SIGNING_KEY_ALIAS SIGNING_KEY_PASSWORD; do
  [ -n "${!v:-}" ] || { echo "$v is empty in .env.signing."; exit 1; }
done
case "$SIGNING_STORE_FILE" in /*) ;; *) SIGNING_STORE_FILE="$PWD/$SIGNING_STORE_FILE" ;; esac
[ -f "$SIGNING_STORE_FILE" ] || { echo "Keystore not found: $SIGNING_STORE_FILE"; exit 1; }
export SIGNING_STORE_FILE
(cd android && ./gradlew bundleRelease)
aab=android/app/build/outputs/bundle/release/app-release.aab
jarsigner -verify "$aab" >/dev/null && echo "Signed AAB: $aab"
