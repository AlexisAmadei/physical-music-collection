---
name: release
description: Cut a new app release - update CHANGELOG, bump version, tag, push, create GitHub release (CI then attaches the APK). Use when user says "release", "cut a release", "ship vX".
argument-hint: "[major|minor|patch|X.Y.Z] (default patch)"
disable-model-invocation: true
---

1. **Changelog.** Read `git log $(git describe --tags --abbrev=0)..HEAD --no-merges` and bring `## Unreleased` in `CHANGELOG.md` up to date: one bullet per user-visible change, written in the user's terms (see `GLOSSARY.md`), grouped under `### Added` / `### Changed` / `### Fixed`. Skip docs, CI and refactor commits. Done when every user-visible commit since the tag maps to a bullet. Commit the file as `Update changelog`.
2. Run `scripts/release.sh $ARGUMENTS` from repo root. It refuses on a dirty tree, a non-main branch, or an empty Unreleased section; it renames Unreleased to the new version and uses its body as the GitHub release notes.

Report the new version and the release URL it prints. If it fails, show the error; do not retry with workarounds.
