# Definition of Done

## A task is done when
- [ ] The code meets every AC assigned to the task
- [ ] Every one of those ACs has at least one automated test named after it (or a recorded manual check)
- [ ] All tests pass locally and in CI; no test skipped, deleted or loosened
- [ ] Changed-lines coverage is at least the threshold in `docs/project.md` (default 80%)
- [ ] Lint and static analysis pass with no new warnings suppressed
- [ ] Reviewer verdict is APPROVE, with no open Blocker or Major findings
- [ ] No new dependency without an accepted ADR
- [ ] No secrets or real personal data anywhere in the change
- [ ] Public behaviour changes are reflected in docs / README where relevant
- [ ] Screens built or changed: fidelity check MATCH and accessibility check PASS (WCAG 2.2 AA), each with its report on the branch
- [ ] PR title is a Conventional Commit and the PR links its issue and spec

## A feature is done when
- [ ] Every task is done, or descoped by the owner with the decision recorded
- [ ] Every AC in the spec traces to a merged PR and a test
- [ ] Security review has no open Critical or High findings
- [ ] DAST (if there is a server or API) has no open Critical or High findings
- [ ] Privacy impact assessment is current; residual privacy risks accepted by the owner at Gate D
- [ ] User, operator and stakeholder docs describe what was merged
- [ ] Performance shows no regression beyond the thresholds below

## Performance thresholds
Compared with `docs/perf/baseline.json`. A breach of any of these is a regression.

| Metric | Max allowed change |
|---|---|
| p95 response / interaction time | +10% |
| Throughput | −10% |
| Error rate | +0.5 percentage points |
| App cold start (mobile) | +10% |
| Peak memory | +15% |

Only the owner promotes a new baseline, by replacing `docs/perf/baseline.json`
through a `governance/*` PR.
