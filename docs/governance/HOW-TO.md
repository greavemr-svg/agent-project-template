# How this project is built

Give the orchestrator an idea and a team of Claude Code agents plans, designs,
builds, tests, reviews, secures and releases it under work-grade governance. You
are needed at three points: approving the spec (Gate A), approving the design
and accepting any residual security risk (Gate D, which also covers the tech
stack on a new project), and approving the release on GitHub (Gate B).

```
idea ─▶ planner ─▶ G1 ─▶ look-ahead ─▶ ★ GATE A: spec (you)
     ─▶ UX designer ─▶ architect ─▶ threat modeller ─▶ privacy assessor ─▶ G2
     ─▶ ★ GATE D: design + residual security and privacy risk (+ stack, first run) (you)
     ─▶ for each task: developer ─▶ tester ─▶ UX fidelity + accessibility (screens only) ─▶ reviewer ─▶ G3 ─▶ merge into feature/<run>
     ─▶ security + DAST (if a server) + performance ─▶ G4
     ─▶ tech writer ─▶ release(prepare) ─▶ look-ahead ─▶ auditor ─▶ retrospective ─▶ G5
     ─▶ ★ GATE B: release PR (you, on GitHub) ─▶ release(ship)
   devops steps in on any environment failure; maintenance runs keep dependencies current.
```

## The team (22 agents)

| Agent | What it does for you |
|---|---|
| orchestrator | Runs the pipeline, keeps the run state, stops at your gates |
| planner | Writes the spec and acceptance criteria |
| look-ahead | Lists decisions and prerequisites before you need them; readiness for the next stage |
| ux-designer | Flows, screens and every state, from Figma when supplied |
| architect | Design, ADRs, task breakdown, project profile |
| threat-modeler | STRIDE threat model, security profile, testable security requirements (SRs) |
| privacy-assessor | Privacy impact assessment, residual privacy risks, questions for the customer's DPO |
| developer | Builds one task, opens the PR |
| maintenance | Surveys and applies dependency, SDK and tool upgrades in maintenance runs |
| tester | Acceptance, edge-case and SR tests |
| ux-fidelity | Runs the app and checks every screen and state against the design |
| accessibility-tester | WCAG 2.2 AA scans, screen-reader scripts, accessibility tests |
| reviewer | Independent code review |
| gatekeeper | Checks G1-G5 against the written criteria |
| devops | Fixes toolchain and build problems; drafts CI changes and machine steps for you |
| security | Static security review and SR verification |
| security-tester | Dynamic testing (OWASP ZAP and auth tests) of the local server, never anything else |
| performance | Benchmarks against the baseline |
| tech-writer | README, user and operator guides, stakeholder summary |
| release | Changelog, version, release PR, merge and tag |
| auditor | Evidence trail and flags |
| retrospective | Run metrics and improvement proposals for you to decide on |

## One-off setup (once, ever)

1. **Tools:** Claude Code, Git for Windows (includes Git Bash), and in PowerShell:
   `winget install GitHub.cli` and `winget install jqlang.jq`. Then `gh auth login` as yourself.
2. **Bot account:** create a second GitHub account, `greavemr-bot`. Signed in as
   the bot, create a **classic** personal access token with the `repo` scope
   (Settings → Developer settings → Tokens (classic)). Classic is needed because
   the bot works on repos you own; one token covers every project.
3. **Template repo:** unzip the kit into an empty folder, then in Git Bash:
   ```bash
   git init -b main && git add . && git commit -m "chore: governed agent project template"
   gh repo create greavemr-svg/agent-project-template --public --source . --push
   gh repo edit greavemr-svg/agent-project-template --template
   ```
   Keep this folder: improvements to the kit go here, and new projects get them.

## Using Figma designs (optional)

1. Once, in PowerShell: `claude plugin install figma@claude-plugins-official`,
   restart Claude Code, type `/plugin`, choose **figma**, sign in to Figma.
   Figma says Full and Dev seats can use it; other seats may be rate-limited.
2. When you give the orchestrator an idea, include the Figma file link and a
   frame link per screen (right-click a frame → Copy link to selection).
3. No Figma connector? Export each frame as PNG into `docs/ux/figma/` and say
   so in the idea. The UX designer reads the images (colours and spacing are
   then estimates).

## Security by design

Every run gets a threat model (STRIDE) before any code is written, with a
security profile from OWASP MASVS (the app) and OWASP ASVS (any backend), and
testable security requirements (SR1, SR2…) assigned to tasks and proved by
tests. The pipeline's mapping to NIST SSDF is in
`docs/governance/security-by-design.md`. At Gate D you explicitly accept any
residual risk; Critical risks can't be accepted.

## Each new project (about 5 minutes)

1. From your template folder, as yourself: `bash scripts/new-project.sh <name>`
   (add `--private` if you have GitHub Pro; branch rules don't work on free private repos).
   This creates the repo from the template, clones it next to the template folder, and sets
   up labels, bot access and branch rules.
2. Accept the repo invitation as the bot (GitHub notifications or the bot's email).
3. In the new project folder, Git Bash:
   ```bash
   export GH_TOKEN=<bot token>
   claude --agent orchestrator
   ```
   Accept the folder trust prompt (agent rules don't run without it). Fix anything
   the preflight message lists.
4. Describe the product. The first run is a **bootstrap run**: the planner asks
   about platform, users and must-haves; you approve the spec for the first
   release (MVP); the architect proposes a stack (ADR 0001 plus
   `docs/project.md`) for you to approve; the first task builds a minimal
   working skeleton; then the MVP features are built.
5. At Gate B, open the release PR on GitHub, read the audit summary, approve it
   there, and tell the orchestrator. It merges, tags and creates the GitHub release.
6. Later features: `claude --agent orchestrator`, describe the next idea.
   If a run stops, start it again and say `resume <run-id>`.
7. Keeping current: `claude --agent orchestrator`, say "maintenance run". The
   maintenance agent surveys outdated and vulnerable packages, SDKs and tools,
   and the upgrades go through the same gates.

**What the new checks need from you:** the UX fidelity and accessibility
agents need the app runnable here (an Android emulator and/or the Windows
build). Screen-reader checks they can't run come to you as a short manual
script. The DAST agent needs OWASP ZAP (Docker or Java) and only targets
`localhost` or a test host you list in `docs/project.md` under "DAST targets".
The privacy assessor needs the customer's jurisdiction in `docs/project.md`.
Screenshots and scan output go to `.evidence/` (git-ignored), never the repo.

Store or production deployment stays manual on purpose.

## What's where

| Path | Purpose |
|---|---|
| `docs/project.md` | Product, stack and exact commands. Filled in by the first run, approved by you |
| `CLAUDE.md` | Rules every agent follows |
| `.claude/agents/` | The 22 agents |
| `.claude/hooks/` | Enforcement scripts |
| `docs/governance/` | Pipeline, gate criteria, Definitions of Ready and Done, standards, release checklist |
| `docs/specs/`, `docs/ux/`, `docs/design/`, `docs/adr/`, `docs/security/`, `docs/privacy/` | What was decided and why: spec, UX, design, decisions, threat models, PIAs |
| `docs/ux/fidelity/`, `docs/a11y/`, `docs/security/dast/` | Evidence that screens, accessibility and the running server were checked |
| `docs/lookahead/`, `docs/metrics/`, `docs/runs/<run-id>/retro.md` | What's coming next; how each run went |
| `docs/guides/`, `docs/stakeholder/`, `docs/devops/`, `docs/maintenance/` | User and operator guides, stakeholder summaries, environment fixes, upgrade plans |
| `docs/runs/<run-id>/` | Run state (resumable) and audit report |
| `.github/` | PR template, CODEOWNERS, CI, governance check |

## How strict is it?

| Control | Enforced by |
|---|---|
| Reviewer, gatekeeper, security, auditor, look-ahead, tech writer, retrospective can't change code | Tool lists + read-only command hook |
| Tester writes only tests; planner only specs; architect only design, ADRs and the project profile; each checker only its own report folder; devops only build scripts and toolchain config | Per-agent write restrictions |
| Task merges also need fidelity MATCH and accessibility PASS for any screen | G3 criteria (gatekeeper) |
| DAST never scans anything except local or owner-named test targets | Agent rules + blocked scanner commands |
| No agent approves a PR; nothing pushed to main; no force push; no `--no-verify` | Global command guard |
| Governance files are owner-only | File guard + CODEOWNERS |
| Task merges need green CI, reviewer `VERDICT: APPROVE` and `GATE G3: PASS`, all after the last commit | Merge guard (reads GitHub, fails closed) |
| Release needs your GitHub approval after the last push, green checks and `GATE G5: PASS` | Merge guard + `main` branch rules |
| PR titles, issue and spec links, release checklist complete | `governance` CI check |
| Every command, file change, agent start/stop and blocked action logged | Audit log, summarised by the auditor |

Hooks read command text, so they're a strong guardrail rather than a sandbox.
The GitHub branch rules on `main` are the backstop: nothing reaches it without
your approval.

**Changing the rules:** edit governance files on a `governance/*` branch and
merge through a PR. For Claude's help, launch it with
`GOVERNANCE_OWNER_OVERRIDE=1` (logged). Make kit-wide improvements in the
template repo so future projects inherit them.

**Cost:** runs are capped at 160 agent invocations (you can set another
number for a run; it's recorded as your decision). The new checks add roughly
2 invocations per task with screens, plus about 6 per run. Opus runs the
orchestrator, planner, architect, threat modeller, privacy assessor and
reviewer; Sonnet does the volume work; Haiku writes the audit. Change `model:` in an agent file to trade quality for cost.
