# Contributing to anyclaw-termux

## Process (PR-flow discipline)

- Work happens on feature branches; **no direct pushes to master**.
- Open a **draft PR** -> get checks green -> the owner merges. Contributors do not merge.
- Each PR adds a CHANGELOG entry under `## [Unreleased]`. This repo keeps no
  version file, so there is no version to bump.
- Merge commits reference the PR number.

## Checks for script changes

- `bash -n scripts/<name>.sh` must pass for every changed script.
- New scripts ship with a usage line (`usage: ...`) and the license header.

## Build history

Significant build/port/decision events go in `docs/BUILD_HISTORY.md` as dated
entries (append; never rewrite history).
