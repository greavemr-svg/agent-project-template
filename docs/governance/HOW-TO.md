# How this project is built

Give the orchestrator an idea and a team of Claude Code agents plans, designs,
builds, tests, reviews, secures and releases it under work-grade governance. You
are needed at two points (three on a new project): approving the spec, approving
the tech stack (first run only), and approving the release on GitHub.

```
idea ─▶ planner ─▶ G1 ─▶ ★ GATE A: spec (you) ─▶ architect ─▶ G2 ─▶ [★ stack, first run only]
     ─▶ for each task: developer ─▶ tester ─▶ reviewer ─▶ G3 ─▶ merge into feature/<run>
     ─▶ security + performance ─▶ G4
     ─▶ release(prepare) ─▶ auditor ─▶ G5 ─▶ ★ GATE B: release PR (you, on GitHub) ─▶ release(ship)
```

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

Store or production deployment stays manual on purpose.

## What's where

| Path | Purpose |
|---|---|
| `docs/project.md` | Product, stack and exact commands. Filled in by the first run, approved by you |
| `CLAUDE.md` | Rules every agent follows |
| `.claude/agents/` | The 11 agents |
| `.claude/hooks/` | Enforcement scripts |
| `docs/governance/` | Pipeline, gate criteria, Definitions of Ready and Done, standards, release checklist |
| `docs/specs/`, `docs/design/`, `docs/adr/` | What was decided and why |
| `docs/runs/<run-id>/` | Run state (resumable) and audit report |
| `.github/` | PR template, CODEOWNERS, CI, governance check |

## How strict is it?

| Control | Enforced by |
|---|---|
| Reviewer, gatekeeper, security, auditor can't change code | Tool lists + read-only command hook |
| Tester writes only tests; planner only specs; architect only design, ADRs and the project profile | Per-agent write restrictions |
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

**Cost:** runs are capped at 60 agent invocations. Opus runs the orchestrator,
planner, architect and reviewer; Sonnet does the volume work; Haiku writes the
audit. Change `model:` in an agent file to trade quality for cost.
