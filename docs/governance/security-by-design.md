# Security by design

Binding on every agent. Security is designed in before code exists (threat
model), built in task by task (security requirements), proved by tests, and
re-checked before release. This document sets the principles, the standards
and levels we verify against, the threat-modelling method, and how the
pipeline meets NIST SSDF.

## 1. Principles (every design must meet these)

| # | Principle | What it means here |
|---|---|---|
| P1 | Least privilege | Request only the permissions, scopes and data the feature needs, at the moment it's needed. |
| P2 | Secure by default | Safest settings out of the box: no debug features, cleartext traffic, exported components or verbose logging in release builds. |
| P3 | Defence in depth | No single control is relied on alone; validate at every trust boundary. |
| P4 | Minimise attack surface | Every new entry point (permission, intent, endpoint, file import, deep link) is justified in the design. |
| P5 | Fail securely | Errors deny by default, reveal nothing sensitive and leave data consistent. |
| P6 | Privacy by design | Data minimisation, purpose limitation, on-device by default, user can see and delete their data (UK GDPR). |
| P7 | Don't trust input | All external input (user, network, files, other apps, sensors) is validated for type, length, range and format. |
| P8 | Use proven components | Platform security APIs and maintained libraries; never home-made crypto. |
| P9 | Keep secrets out | No secrets in code, config, tests, logs or the repo; secrets come from secure storage. |
| P10 | Traceable decisions | Every security decision and accepted risk is recorded (threat model, ADR, owner acceptance). |

## 2. Standards and levels (the security profile)

The threat modeller chooses the profile for each run and records why. Only the
owner may lower it, at Gate D.

| Surface | Standard | Default level | Raise to |
|---|---|---|---|
| Android / mobile app | **OWASP MASVS v2** (control groups STORAGE, CRYPTO, AUTH, NETWORK, PLATFORM, CODE, RESILIENCE, PRIVACY) | **MAS-L1** (baseline), plus **MASVS-PRIVACY** whenever personal data is processed | **MAS-L2** when the app holds sensitive personal data (health, employment, pay, precise location history) or authenticates users |
| Backend, API, web front end (if any) | **OWASP ASVS 5.0** | **Level 1** | **Level 2** for anything handling personal data or authentication; Level 3 only by ADR |
| Process | **NIST SSDF (SP 800-218 v1.1)** | All practices in section 5 | — |

Notes:
- MASVS-RESILIENCE (anti-tampering) applies only when the threat model shows a
  real need (e.g. protecting paid content); it is not a default.
- ASVS 5.0 levels are risk-based. Pick the level from the data and threats,
  not from habit.
- Requirement IDs are cited exactly as published (e.g. `MASVS-STORAGE-1`,
  `ASVS v5.0.0-1.2.5`) so they can be looked up.

## 3. Threat-modelling method

1. **Model** the system as a data-flow diagram: external entities, processes,
   data stores, data flows, trust boundaries (device ↔ network, app ↔ other
   apps, app ↔ OS permissions, user ↔ app).
2. **Identify** threats with **STRIDE** for every element touching a trust
   boundary: Spoofing, Tampering, Repudiation, Information disclosure, Denial
   of service, Elevation of privilege. For personal data also consider
   linkability, identifiability, unawareness and non-compliance.
3. **Rate** each threat: likelihood (1 rare – 3 likely) × impact (1 minor –
   3 severe). Score 1–2 Low, 3–4 Medium, 6 High, 9 Critical. Personal-data
   exposure is never below impact 2.
4. **Mitigate**: every Medium, High or Critical threat gets one or more
   testable security requirements (SR), each mapped to a MASVS/ASVS control,
   a task, and a verification method.
5. **Accept**: anything not fully mitigated is a residual risk. Only the owner
   accepts residual risks, explicitly, at Gate D. Critical risks cannot be
   accepted; the design must change.
6. **Maintain**: each run updates the threat model for what it changes. The
   security agent re-checks it against the built feature before release.

## 4. Rules that apply in every run

- Every SR is implemented in a task and has at least one named test or review
  check (`SR3_...` in test names) before G3 passes for that task.
- No release with an open Critical or High finding, or an unimplemented SR.
- New dependencies: licence, maintenance and known-vulnerability check in an ADR (PW.4).
- Release builds: minified, debuggable off, cleartext off, backups excluded
  for sensitive data, signing keys outside the repo.
- Vulnerabilities found after release are fixed through the pipeline as a run
  with a root-cause note (RV.1–RV.3).

## 5. How the pipeline meets NIST SSDF (SP 800-218 v1.1)

| SSDF practice | How this pipeline does it | Evidence |
|---|---|---|
| PO.1 Define security requirements | Security profile + SRs per run; standing rules in this doc and security-standards.md | `docs/security/*-threat-model.md`, `docs/governance/` |
| PO.2 Roles and responsibilities | Separate agents with enforced permissions; owner gates | `docs/governance/pipeline.md`, agent files, hooks |
| PO.3 Supporting toolchains | CI, governance check, Dependabot, secret scanning, CodeQL, audit log | `.github/`, `.claude/hooks/` |
| PO.4 Criteria for security checks | Gates G1–G5 and Gate D, with written criteria | `docs/governance/pipeline.md` |
| PO.5 Secure development environments | Bot identity with least privilege, branch rulesets, no secrets on disk in repo | `scripts/setup-github.sh`, `.gitignore` |
| PS.1 Protect code from tampering | Protected `main`, PR-only changes, no force push, CODEOWNERS | GitHub rulesets, `guard-bash.sh` |
| PS.2 Release integrity | Tagged releases from reviewed, approved PRs; signed builds (owner) | GitHub releases, release notes |
| PS.3 Archive and protect releases | Git tags + GitHub releases + CHANGELOG | Repo history |
| PW.1 Design to meet security requirements | Threat model (this doc, section 3) before build | Threat model |
| PW.2 Review the design | Gatekeeper G2 + owner Gate D on design and residual risk | Gate records in `state.json`, audit |
| PW.4 Reuse well-secured software | Dependency ADRs; Dependabot | `docs/adr/`, Dependabot PRs |
| PW.5 Secure coding practices | Coding + security standards; developer brief | `docs/governance/*-standards.md` |
| PW.6 Secure build configuration | Release build rules (section 4) checked by security agent | Security report |
| PW.7 Review code for vulnerabilities | Reviewer per PR; security agent per feature | PR reviews, epic comment |
| PW.8 Test executable code | Tester: AC and SR tests; CI | Test reports, `SR*` tests |
| PW.9 Secure default settings | Principle P2; checked at G4 | Security report |
| RV.1 Identify vulnerabilities | Dependabot, secret scanning, CodeQL, security agent | Alerts, reports |
| RV.2 Assess and remediate | Fix runs through the pipeline; severity rules | Issues/PRs |
| RV.3 Root-cause analysis | Root-cause note on every security fix; retrospective | Fix PRs, audit |

SSDF v1.2 is in draft (SP 800-218r1 initial public draft, December 2025). It
adds PO.6 (continuous improvement) and PS.4 (robust updates). We already cover
PO.6 through the retrospective/auditor findings feeding template fixes; review
this table when v1.2 is final.
