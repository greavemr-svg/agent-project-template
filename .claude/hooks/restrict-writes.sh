#!/usr/bin/env bash
# PreToolUse (Edit|Write) for one agent: allow writes only to paths matching
# one of the glob patterns given as arguments (relative to the project root).
#   restrict-writes.sh "docs/specs/*" "docs/adr/*"
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

path="$(target_rel_path)"
[ -z "$path" ] && exit 0

case "$path" in
  /*|[A-Za-z]:/*|../*|*/../*)
    block "this agent may only write inside the project; '$path' is outside it." ;;
esac

for pattern in "$@"; do
  # shellcheck disable=SC2254
  case "$path" in
    $pattern) exit 0 ;;
  esac
done

block "this agent may only write to: $*. '$path' is not one of them. If this file genuinely needs changing, report it as a finding for the agent that owns it."
