#!/usr/bin/env bash
# SessionStart: checks the prerequisites and tells Claude (and you) what's missing.
# Never blocks; its output is added to the session context.
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
OWNER_LOGIN=""
# shellcheck disable=SC1091
[ -f "$PROJECT_ROOT/.claude/governance.env" ] && . "$PROJECT_ROOT/.claude/governance.env"

warn=()
command -v jq >/dev/null 2>&1 || warn+=("jq is not installed. Every governance hook will block until it is.")
if ! command -v gh >/dev/null 2>&1; then
  warn+=("GitHub CLI (gh) is not installed.")
else
  login="$(gh api user --jq .login 2>/dev/null)"
  if [ -z "$login" ]; then
    warn+=("gh is not authenticated. Set GH_TOKEN to the bot account's token.")
  elif [ -n "$OWNER_LOGIN" ] && [ "$login" = "$OWNER_LOGIN" ]; then
    warn+=("gh is authenticated as the owner ($login). Agents must use the bot account, otherwise you can't approve their PRs and separation of duties is lost.")
  fi
fi
[ -z "$OWNER_LOGIN" ] && warn+=("OWNER_LOGIN is not set in .claude/governance.env.")

if [ ${#warn[@]} -gt 0 ]; then
  echo "GOVERNANCE PREFLIGHT - do not start a pipeline run until these are fixed:"
  for w in "${warn[@]}"; do echo "- $w"; done
fi
exit 0
