---
name: release
description: Cut a new app release - bump version, tag, push, create GitHub release (CI then attaches the APK). Use when user says "release", "cut a release", "ship vX".
argument-hint: "[major|minor|patch|X.Y.Z] (default patch)"
disable-model-invocation: true
---

Run `scripts/release.sh $ARGUMENTS` from repo root. It refuses on a dirty tree or non-main branch.

Report the new version and the release URL it prints. If it fails, show the error; do not retry with workarounds.
