# Coding standards

Project-specific rules in `docs/project.md` and `CLAUDE.md` take precedence over these defaults.

## General
- Small, focused changes. One task, one PR. No drive-by refactors.
- Names say what things are. No abbreviations beyond common ones (id, url, ui).
- Functions do one thing. If a function needs a comment explaining its sections, split it.
- No dead code, commented-out code or debugging output left behind.
- Comments explain *why*, not *what*.
- Fail loudly and early: validate inputs at boundaries, never swallow exceptions silently.
- No magic numbers or strings; use named constants.
- Keep business logic out of UI code so it can be unit tested.

## Errors and logging
- Every error path either recovers deliberately or surfaces a clear message to the user or caller.
- Log enough to diagnose; never log personal data, tokens or credentials.

## Tests
- Unit tests for all business logic; tests are deterministic (no real clock, network or randomness without injection).
- Test names describe behaviour and reference the AC: `AC3_rejects_overlapping_shifts`.
- Arrange / Act / Assert structure. One behaviour per test.
- Never weaken an assertion to make a test pass.

## Dependencies
- Prefer the platform and existing dependencies. A new library needs an ADR covering why, alternatives, licence and maintenance status.
- Pin versions. No snapshot or unversioned dependencies.

## Git
- Conventional Commits: `type(scope): summary (#issue)`. Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert.
- `!` after the type, or a `BREAKING CHANGE:` footer, for breaking changes.
- Branches: `feature/<run-id>`, `task/<run-id>-<n>-<slug>`, `governance/<slug>`, `hotfix/<slug>`.

## Android / Kotlin (when applicable)
- Kotlin official style, enforced by ktlint. Coroutines for async; no `GlobalScope`.
- ViewModels hold UI state; repositories own data access; no Android framework types in domain code.
- Strings in resources, never hard-coded in UI. Support dark mode and font scaling.
- Accessibility: content descriptions on interactive images, touch targets ≥ 48dp.
