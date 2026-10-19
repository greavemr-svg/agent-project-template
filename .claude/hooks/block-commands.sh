#!/usr/bin/env bash
# PreToolUse (Bash) for one agent: refuse commands matching any of the extended
# regexes given as arguments. With --readonly, also refuse anything that changes
# files, git history or GitHub state.
#   block-commands.sh --readonly 'gh[[:space:]]+pr[[:space:]]+create'
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

cmd="$(bash_command)"
[ -z "$cmd" ] && exit 0

# Harmless redirections that shouldn't trip the "writes a file" check
clean="$(printf '%s' "$cmd" | sed -E 's#[0-9]*>>?[[:space:]]*/dev/null##g; s#[0-9]*>&[0-9]##g')"

patterns=()
if [ "${1:-}" = "--readonly" ]; then
  shift
  patterns+=(
    '(^|[^0-9<=])>'                                   # any output redirection to a file
    '(^|[[:space:];&|(])tee([[:space:]]|$)'
    '(^|[[:space:];&|(])(rm|mv|cp|chmod|chown|truncate|touch|mkdir|ln|dd)[[:space:]]'
    'sed[[:space:]]+(-[a-zA-Z]*i|--in-place)'
    'perl[[:space:]]+-[a-zA-Z]*i'
    'git[[:space:]]+(commit|push|merge|rebase|reset|tag|cherry-pick|stash|am|apply|restore|clean|rm|mv)([[:space:]]|$)'
    'gh[[:space:]]+(pr|issue)[[:space:]]+(merge|close|reopen|edit|ready|create|delete|lock|transfer)'
    'gh[[:space:]]+(release|repo|secret|variable|ruleset|label|workflow)[[:space:]]+(create|edit|delete|set|run|enable|disable)'
    'gh[[:space:]]+api.*(-X|--method)[[:space:]]*(POST|PUT|PATCH|DELETE)'
    'gh[[:space:]]+api.*[[:space:]](-f|-F|--field|--raw-field|--input)[[:space:]]'
    'audit[[:space:]]+fix'
  )
fi
patterns+=("$@")

for p in "${patterns[@]}"; do
  if printf '%s' "$clean" | grep -Eq -- "$p"; then
    block "this agent is not allowed to run that command (matched rule: $p). Your role is limited; report what needs doing instead of doing it."
  fi
done
exit 0
