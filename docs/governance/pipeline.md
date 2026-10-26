# Delivery pipeline and gates

This document is binding. Agents follow it; only the owner changes it, through
a `governance/*` branch PR.

## Roles

| Agent | Owns | Can write | Can never |
|---|---|---|---|
| orchestrator | Routing, run state, human gates | `docs/runs/` | Design, code, test, review, merge |
| planner | Spec | `docs/specs/` | Design the solution |
| ux-designer | User flows, screen specs, design system (from Figma when supplied) | `docs/ux/` | Change requirements, override Figma |
| architect | Design, ADRs, task breakdown | `docs/design/`, `docs/adr/`, `docs/project.md` | Change requirements, write code |
| threat-modeler | Threat model, security profile, security requirements | `docs/security/` | Accept risk, weaken the profile |
| privacy-assessor | Privacy impact assessment, residual privacy risks, DPO questions | `docs/privacy/` | Accept risk, claim legal compliance |
| look-ahead | Upcoming decisions, prerequisites, readiness for the next stage | `docs/lookahead/` | Make decisions |
| developer | Implementation, PR | Application code + unit tests | Merge, approve, touch governance |
| maintenance | Dependency / SDK / tool survey and upgrades (maintenance runs) | Like developer; survey writes `docs/maintenance/` | Upgrade outside the approved plan, accept excluded licences |
| tester | Acceptance and edge-case tests | Test files only | Change application code |
| ux-fidelity | Built screens vs UX design and Figma | `docs/ux/fidelity/` | Change code or design |
| accessibility-tester | WCAG 2.2 AA checks, accessibility tests | `docs/a11y/`, accessibility test files | Change application code |
| devops | Toolchain, build-script and environment fixes; CI changes drafted for the owner | Build scripts, toolchain config, `docs/devops/` | Edit `.github/`, weaken checks, install system software |
| reviewer | Code review verdict | Nothing (read-only) | Change code, approve on GitHub |
| gatekeeper | Gate decisions G1-G5 | Nothing (read-only) | Waive a criterion |
| security | Feature security review | Nothing (read-only) | Fix findings |
| security-tester | Dynamic testing (DAST) of the local server/API | `docs/security/dast/` | Test anything but local or owner-named test targets |
| performance | Benchmarks vs baseline | `docs/perf/<run-id>/` | Overwrite the baseline |
| tech-writer | README, user / operator guides, stakeholder summary | `README.md`, `docs/guides/`, `docs/stakeholder/` | Document unmerged behaviour |
| release | Merges, versioning, release | Changelog, release notes, version files | Merge to main without owner approval |
| auditor | Audit trail | `docs/runs/<run-id>/audit.md` | Soften flags |
| retrospective | Run metrics and improvement proposals | `docs/runs/<run-id>/retro.md`, `docs/metrics/` | Change rules (proposes only) |
| **owner (you)** | Gate A, Gate B, governance | Everything | — |

Separation of duties: no agent reviews, tests or gates its own work; only the
owner approves what reaches `main`.

## Flow

```
idea → planner → G1 → look-ahead(start) → GATE A (owner: spec)
     → ux-designer → architect → threat-modeler (↺ architect) → privacy-assessor (↺ threat-modeler / architect)
     → G2 → GATE D (owner: design + residual security and privacy risk)
     → per task: developer → tester → [ux-fidelity → accessibility-tester, if screens] → reviewer → G3 → merge into feature/<run>
     → security + security-tester (DAST, if a server) + performance → G4
     → tech-writer → release(prepare) → look-ahead(end) → auditor → retrospective → G5 → GATE B (owner, on GitHub)
     → release(ship): merge to main, tag, GitHub release
devops: on any environment failure.  maintenance: replaces the developer in maintenance runs.
```

New projects: the first run is a **bootstrap run** (when `docs/project.md`
says `NOT SET UP`). Its Gate D also covers the stack, and its
first task is a walking skeleton. See the orchestrator's bootstrap section.

Retries: max 3 attempts per task, then the owner decides. Max 8 tasks and 160
agent invocations per run (or the owner's recorded `counters.invocation_limit`).
Environment failures handled by devops don't count as task attempts.

**Maintenance runs** (`"mode": "maintenance"`) keep dependencies, SDKs and
tools current: the maintenance agent's survey feeds the planner, and the
maintenance agent replaces the developer. All gates apply; G2.7, G2.8 and G2.12
may be marked "not applicable: maintenance run" when no screens or personal
data handling change.

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
- G1.8 "Design sources" is filled in: Figma links, exports, or "none".
- G1.7 No TBD / TODO / open questions remain.
- See also `definition-of-ready.md`.

### Gate A — owner approves the spec (human)
- Owner approval recorded verbatim with UTC timestamp in `state.json`.

### G2 — Design ready (UX, architecture, threat model)
- G2.1 `docs/design/<run-id>.md` exists and follows `docs/design/_template.md`.
- G2.2 Every AC maps to at least one task; no task without an AC.
- G2.3 Every task has: ACs, likely files, dependencies, size S or M.
- G2.4 Task count is 1-8.
- G2.5 Every new dependency, data-model change or hard-to-reverse decision has an ADR with status `Accepted`.
- G2.6 Test strategy and security considerations sections are filled in.
- G2.7 `docs/ux/<run-id>.md` exists; every AC has a flow and screen; every screen defines loading, empty, error and offline states (and permission-denied where relevant) and meets the accessibility rules; Figma discrepancies are resolved by the owner.
- G2.8 Every UX screen is assigned to a task.
- G2.9 `docs/security/<run-id>-threat-model.md` exists, follows the template, and states the security profile with a reason.
- G2.10 Every threat rated Medium or above has at least one testable SR, mapped to a MASVS/ASVS control ID, a task and a verification method.
- G2.11 No Critical threat is left as a residual risk; the principles check has no open finding.
- G2.12 `docs/privacy/<run-id>-pia.md` exists: either a screening result showing no personal data, or a full PIA in which every personal data item has a purpose, basis (marked for DPO confirmation), storage locations and a retention period or trigger.
- G2.13 Every privacy control that needs software maps to an SR in the threat model; residual privacy risks and DPO questions are listed for Gate D.

### Bootstrap runs
- `docs/adr/0001-technology-stack.md` accepted and `docs/project.md` complete, approved by the owner at Gate D and recorded in `state.json`.
- Task 1 is the walking skeleton and merges before any other task starts.

### Gate D — owner approves the design and accepts residual risk (human)
- Owner's approval of the screens, tasks and security profile, and explicit acceptance of each listed residual security and privacy risk, recorded verbatim with UTC timestamp in `state.json`.
- The owner's answer on DPO consultation (done, or proceeding while pending), recorded verbatim.
- On bootstrap runs this is also the stack approval.

### G3 — Task done (per PR)
- G3.1 PR targets `feature/<run-id>` from `task/<run-id>-<n>-<slug>`.
- G3.2 PR title is a Conventional Commit; body has `Closes #<task issue>` and the spec path; template sections filled in.
- G3.3 All CI checks on the PR passed (`gh pr checks`).
- G3.4 Tester report: all tests pass; every AC for this task has a named test; changed-lines coverage ≥ threshold in `docs/project.md`.
- G3.5 Latest reviewer verdict is `VERDICT: APPROVE`, newer than the last commit, with no unresolved Blocker or Major.
- G3.6 No files changed outside the task's scope without a stated reason; no unapproved dependency; no test skipped, deleted or weakened.
- G3.7 Every SR assigned to the task is implemented and has a named `SR<n>_…` test, or a recorded review/tool check.
- G3.8 Screens built in this task match the UX design, including all states.
- G3.9 Tasks that build or change screens: the latest ux-fidelity comment on the PR is `FIDELITY: MATCH`, newer than the last application-code commit, with `docs/ux/fidelity/<run-id>/T<n>.md` on the branch. Tasks without screens: "no screens" recorded in state.json.
- G3.10 Tasks that build or change screens: the latest accessibility comment is `A11Y: PASS`, newer than the last application-code commit, with `docs/a11y/<run-id>/T<n>.md` on the branch and no open Blocker or Major. Manual checks it lists are in `owner_actions_pending`.

### G4 — Feature done
- G4.1 Every task is `done`, or `descoped` with the owner's recorded decision.
- G4.2 CI is green on the head of `feature/<run-id>`.
- G4.3 Security: zero open Critical or High findings.
- G4.6 Security agent reports every SR verified and the threat model current.
- G4.4 Performance: `PASS` or `NOT_APPLICABLE`; `NO_BASELINE` only with the proposed baseline recorded.
- G4.7 DAST: `docs/security/dast/<run-id>.md` shows `PASS` with zero open Critical or High findings, or `NOT_APPLICABLE` because the project has no server or API. `BLOCKED` fails this criterion.
- G4.5 Every AC in the spec traces to a merged PR and a test, or to a recorded descope.

### G5 — Release ready
- G5.1 Release PR goes from `feature/<run-id>` to `main`.
- G5.2 Version bumped per SemVer from the commits; `CHANGELOG.md` and `docs/releases/v<version>.md` updated.
- G5.3 Every item in `release-checklist.md` is ticked in the PR body, with no `- [ ]` left.
- G5.4 `docs/runs/<run-id>/audit.md` exists; every flag is either resolved or listed in the PR body for the owner.
- G5.5 CI is green on the release PR.
- G5.6 User and stakeholder docs updated for this run (`docs/stakeholder/<run-id>.md` exists; README and guides changed where behaviour changed), or the tech-writer's GAPS are listed in the PR body.
- G5.7 `docs/lookahead/<run-id>-end.md` and `docs/runs/<run-id>/retro.md` are on the release branch.

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
