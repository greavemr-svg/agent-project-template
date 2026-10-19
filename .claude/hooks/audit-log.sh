#!/usr/bin/env bash
# Appends a line to .governance/audit-events.jsonl for the auditor.
#   audit-log.sh tool        (PostToolUse: git/gh commands and file writes)
#   audit-log.sh subagent    (SubagentStart / SubagentStop)
# Never blocks.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

case "${1:-}" in
  tool)
    tool="$(hook_field '.tool_name')"
    if [ "$tool" = "Bash" ]; then
      cmd="$(bash_command)"
      if printf '%s' "$cmd" | grep -Eq '(git[[:space:]]+(commit|push|merge|tag|switch -c|checkout -b)|gh[[:space:]]+(pr|issue|release)[[:space:]]+(create|merge|review|comment|close|edit))'; then
        audit_event "command" "$(printf '%s' "$cmd" | head -c 500)"
      fi
    else
      audit_event "file_write" "$(target_rel_path)"
    fi
    ;;
  subagent)
    audit_event "$(hook_field '.hook_event_name')" "$(hook_field '.agent_type')"
    ;;
esac
exit 0
