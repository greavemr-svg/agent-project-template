# Agent-built project

This repository is built by a governed team of agents. Project specifics
(product, stack, the exact build/lint/test/coverage commands, version files,
coverage threshold) are in **`docs/project.md`**. Read it first; use exactly the
commands it lists.

If `docs/project.md` says `Status: NOT SET UP`, the project has no code yet and
the next pipeline run is the bootstrap run (see `docs/governance/pipeline.md`).

## Delivery process
All work goes through the governed pipeline: `claude --agent orchestrator`, then
describe the idea. The process, gates and standards in `docs/governance/` are
binding on every agent.

## Rules for every agent and session
- `main` only changes through an owner-approved release PR from `feature/*`.
- Work happens on `task/<run-id>-<n>-<slug>` branches, merged into `feature/<run-id>`.
- Conventional Commits for every commit and PR title, referencing an issue: `feat(rota): add overlap check (#42)`.
- Never use `--no-verify`, force-push, or skip, delete or weaken tests and checks.
- Never edit `.claude/`, `.github/`, `docs/governance/`, `CLAUDE.md` or `CODEOWNERS`. These are owner-only and enforced.
- No new dependency without an ADR in `docs/adr/`.
- No secrets, keys, tokens or real personal data in code, tests, fixtures, logs or commits.
- If unsure, stop and report BLOCKED with a precise question. Never guess at requirements.
