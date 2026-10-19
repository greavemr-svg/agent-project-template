#!/usr/bin/env bash
# PreToolUse (Edit|Write|NotebookEdit), every session and every agent:
# governance files can only be changed by the owner. To edit them with Claude's
# help, start Claude Code with GOVERNANCE_OWNER_OVERRIDE=1 in your own shell
# and send the change through a governance/* branch PR like any other change.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

[ "${GOVERNANCE_OWNER_OVERRIDE:-}" = "1" ] && { audit_event "owner_override" "$(target_rel_path)"; exit 0; }

path="$(target_rel_path)"
# Match both the project-relative path and, as a fallback for paths that didn't
# relativise (e.g. drive-letter differences on Windows), any path segment.
case "$path" in
  .claude/*|.github/*|docs/governance/*|CLAUDE.md|CODEOWNERS|.governance/*|docs/perf/baseline.json|scripts/setup-github.sh|\
  */.claude/*|*/.github/*|*/docs/governance/*|*/CLAUDE.md|*/CODEOWNERS|*/.governance/*|*/docs/perf/baseline.json|*/scripts/setup-github.sh)
    block "'$path' is a governance file and is owner-only. Agents follow the rules; they don't change them." ;;
esac
exit 0
