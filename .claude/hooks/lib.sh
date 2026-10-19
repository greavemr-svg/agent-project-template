#!/usr/bin/env bash
# Shared helpers for governance hooks. Sourced by the other scripts, not run directly.
# Requires jq: https://jqlang.org/download/  (Windows: winget install jqlang.jq)

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_ROOT="${PROJECT_ROOT//\\//}"
PROJECT_ROOT="${PROJECT_ROOT%/}"
AUDIT_LOG="$PROJECT_ROOT/.governance/audit-events.jsonl"

# Repo-level settings (owner login, main branch name)
OWNER_LOGIN=""
MAIN_BRANCH="main"
# shellcheck disable=SC1091
[ -f "$PROJECT_ROOT/.claude/governance.env" ] && . "$PROJECT_ROOT/.claude/governance.env"

if ! command -v jq >/dev/null 2>&1; then
  echo "BLOCKED by governance: jq is not installed, so the hooks cannot check this action. Install jq and retry." >&2
  exit 2   # fail closed: no jq means no checks, so nothing runs
fi

HOOK_INPUT="$(cat)"

hook_field() {
  printf '%s' "$HOOK_INPUT" | jq -r "$1 // empty" 2>/dev/null
}

audit_event() {
  # audit_event <event> <detail>
  mkdir -p "$(dirname "$AUDIT_LOG")" 2>/dev/null || return 0
  jq -cn \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg event "$1" \
    --arg detail "$2" \
    --arg session "$(hook_field '.session_id')" \
    --arg agent "$(hook_field '.agent_type')" \
    --arg tool "$(hook_field '.tool_name')" \
    '{ts:$ts, event:$event, agent:(if $agent=="" then "main" else $agent end), tool:$tool, session:$session, detail:$detail}' \
    >> "$AUDIT_LOG" 2>/dev/null || true
}

block() {
  audit_event "blocked" "$1"
  echo "BLOCKED by governance: $1" >&2
  exit 2
}

# Path of the file being written, relative to the project root, with / separators.
target_rel_path() {
  local file lf lr
  file="$(hook_field '.tool_input.file_path // .tool_input.notebook_path')"
  file="${file//\\//}"
  lf="$(printf '%s' "$file" | tr '[:upper:]' '[:lower:]')"
  lr="$(printf '%s' "$PROJECT_ROOT" | tr '[:upper:]' '[:lower:]')"
  case "$lf" in
    "$lr"/*) file="${file:$((${#PROJECT_ROOT}+1))}" ;;
  esac
  file="${file#./}"
  printf '%s' "$file"
}

bash_command() {
  hook_field '.tool_input.command'
}

# Split a shell command into simple segments (one per line) on && || ; | and newlines.
command_segments() {
  printf '%s\n' "$1" | sed -E 's/(&&|\|\||;|\|)/\n/g'
}
