# Release checklist

Copied into every release PR body by the release agent. Every box must be
ticked, with evidence, before G5 can pass. CI rejects a release PR with any
unticked box.

- [ ] All tasks in the run are done or descoped by the owner (link: state.json)
- [ ] Every acceptance criterion traces to a merged PR and a test (link: audit.md)
- [ ] CI green on the release PR
- [ ] Security review: no open Critical/High findings (link: epic comment)
- [ ] Every security requirement (SR) implemented and verified (link: threat model, security report)
- [ ] Threat model current for what this release changes; residual risks accepted at Gate D
- [ ] Release build config: debuggable off, minify on, cleartext off, sensitive data excluded from backup
- [ ] Screens match the UX design, including error/empty/offline states and accessibility
- [ ] Performance: PASS or NOT_APPLICABLE (link: docs/perf/<run-id>/)
- [ ] Version bumped per SemVer: `vX.Y.Z`
- [ ] CHANGELOG.md updated
- [ ] Release notes written: docs/releases/vX.Y.Z.md
- [ ] Rollback plan stated in the release notes (revert PR / previous build / data migration reversal)
- [ ] Data or schema migrations, if any, are tested and reversible
- [ ] Audit complete: docs/runs/<run-id>/audit.md, flags listed below
- [ ] Manual checks, if the spec has any, done and recorded

## Audit flags for the owner
<List each flag from audit.md, or "None">
