# Delivery pipeline and gates

This document is binding. Agents follow it; only the owner changes it, through
a `governance/*` branch PR.

## Roles

| Agent | Owns | Can write | Can never |
|---|---|---|---|
| orchestrator | Routing, run state, human gates | `docs/runs/` | Design, code, test, review, merge |
| planner | Spec | `docs/specs/` | Design the solution |
| architect | Design, ADRs, task breakdown | `docs/design/`, `docs/adr/` | Change requirements, write code |
| developer | Implementation, PR | Application code + unit tests | Merge, approve, touch governance |
| tester | Acceptance and edge-case tests | Test files only | Change application code |
| reviewer | Code review verdict | Nothing (read-only) | Change code, approve on GitHub |
| gatekeeper | Gate decisions G1-G5 | Nothing (read-only) | Waive a criterion |
| security | Feature security review | Nothing (read-only) | Fix findings |
| performance | Benchmarks vs baseline | `docs/perf/<run-id>/` | Overwrite the baseline |
| release | Merges, versioning, release | Changelog, release notes, version files | Merge to main without owner approval |
| auditor | Audit trail | `docs/runs/<run-id>/audit.md` | Soften flags |
| **owner (you)** | Gate A, Gate B, governance | Everything | — |

Separation of duties: no agent reviews, tests or gates its own work; only the
owner approves what reaches `main`.

## Flow

```
idea → planner → G1 → GATE A (owner) → architect → G2
     → per task: developer → tester → reviewer → G3 → merge into feature/<run>
     → security + performance → G4
     → release(prepare) → auditor → G5 → GATE B (owner, on GitHub)
     → release(ship): merge to main, tag, GitHub release
```

New projects: the first run is a **bootstrap run** (when `docs/project.md`
says `NOT SET UP`). It adds a stack checkpoint for the owner after G2, and its
first task is a walking skeleton. See the orchestrator's bootstrap section.

Retries: max 3 attempts per task, then the owner decides. Max 8 tasks and 60
agent invocations per run.

## Gate criteria

A criterion is met only with evidence. The gatekeeper fails anything it cannot
evidence.

### G1 — Definition of Ready (spec)
- G1.1 `docs/specs/<run-id>.md` exists and follows `docs/specs/_template.md`.
- G1.2 Problem statement and target user are stated.
- G1.3 Acceptance criteria are numbered (AC1, AC2, …), in Given/When/Then form, and each is independently testable.
- G1.4 Out-of-scope items are listed.
- G1.5 Non-functional requirements are listed, or "none beyond project defaults" is stated.
- G1.6 Data and privacy impact is stated (what personal data, if any, is created, stored or sent).
- G1.7 No TBD / TODO / open questions remain.
- See also `definition-of-ready.md`.

### Gate A — owner approves the spec (human)
- Owner approval recorded verbatim with UTC timestamp in `state.json`.

### G2 — Design ready
- G2.1 `docs/design/<run-id>.md` exists and follows `docs/design/_template.md`.
- G2.2 Every AC maps to at least one task; no task without an AC.
- G2.3 Every task has: ACs, likely files, dependencies, size S or M.
- G2.4 Task count is 1-8.
- G2.5 Every new dependency, data-model change or hard-to-reverse decision has an ADR with status `Accepted`.
- G2.6 Test strategy and security considerations sections are filled in.

### Stack checkpoint — owner approves the stack (human, bootstrap runs only)
- `docs/adr/0001-technology-stack.md` accepted and `docs/project.md` complete, approved by the owner and recorded in `state.json`.
- Task 1 is the walking skeleton and merges before any other task starts.

### G3 — Task done (per PR)
- G3.1 PR targets `feature/<run-id>` from `task/<run-id>-<n>-<slug>`.
- G3.2 PR title is a Conventional Commit; body has `Closes #<task issue>` and the spec path; template sections filled in.
- G3.3 All CI checks on the PR passed (`gh pr checks`).
- G3.4 Tester report: all tests pass; every AC for this task has a named test; changed-lines coverage ≥ threshold in `docs/project.md`.
- G3.5 Latest reviewer verdict is `VERDICT: APPROVE`, newer than the last commit, with no unresolved Blocker or Major.
- G3.6 No files changed outside the task's scope without a stated reason; no unapproved dependency; no test skipped, deleted or weakened.

### G4 — Feature done
- G4.1 Every task is `done`, or `descoped` with the owner's recorded decision.
- G4.2 CI is green on the head of `feature/<run-id>`.
- G4.3 Security: zero open Critical or High findings.
- G4.4 Performance: `PASS` or `NOT_APPLICABLE`; `NO_BASELINE` only with the proposed baseline recorded.
- G4.5 Every AC in the spec traces to a merged PR and a test, or to a recorded descope.

### G5 — Release ready
- G5.1 Release PR goes from `feature/<run-id>` to `main`.
- G5.2 Version bumped per SemVer from the commits; `CHANGELOG.md` and `docs/releases/v<version>.md` updated.
- G5.3 Every item in `release-checklist.md` is ticked in the PR body, with no `- [ ]` left.
- G5.4 `docs/runs/<run-id>/audit.md` exists; every flag is either resolved or listed in the PR body for the owner.
- G5.5 CI is green on the release PR.

### Gate B — owner approves the release (human)
- Owner approves the release PR **on GitHub** after reading the audit summary.
- The merge guard refuses to merge without that approval newer than the last commit.

## How the gates are enforced

| Layer | What it enforces |
|---|---|
| Agent tool lists | Which tools each role has at all (e.g. reviewer cannot edit). |
| Agent hooks (`.claude/hooks/`) | Where each role may write, which commands it may run, and that merges only happen with evidence on GitHub. |
| Global hooks | No force push, no push to main, no `--no-verify`, no agent approvals, governance files owner-only, audit log of every action. |
| GitHub rulesets | `main` needs a PR, passing checks and an owner (code owner) approval. Applies even if everything above fails. |
| CI governance job | PR title, issue link, spec link, release checklist complete, only `feature/*` or `governance/*` into main. |
| Auditor | Cross-checks the record and flags gaps after the fact. |
