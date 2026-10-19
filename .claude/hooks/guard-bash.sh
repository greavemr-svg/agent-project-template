#!/usr/bin/env bash
# PreToolUse (Bash), every session and every agent: the non-negotiable rules.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

cmd="$(bash_command)"
[ -z "$cmd" ] && exit 0

PROTECTED='(\.claude/|\.github/|docs/governance/|CLAUDE\.md|CODEOWNERS|\.governance/|docs/perf/baseline\.json|scripts/setup-github\.sh)'
WRITE_OP='((^|[^0-9<=])>|(^|[[:space:];&|(])(tee|rm|mv|cp|chmod|truncate|touch|ln)[[:space:]]|sed[[:space:]]+(-[a-zA-Z]*i|--in-place)|perl[[:space:]]+-[a-zA-Z]*i|git[[:space:]]+(checkout|restore|rm|mv)[[:space:]])'

while IFS= read -r seg; do
  [ -z "${seg//[[:space:]]/}" ] && continue

  if printf '%s' "$seg" | grep -Eq -- '--no-verify'; then
    block "--no-verify skips the checks the governance relies on."
  fi

  if printf '%s' "$seg" | grep -Eq 'git[[:space:]]+push'; then
    printf '%s' "$seg" | grep -Eq -- '(--force|--force-with-lease|[[:space:]]-[a-zA-Z]*f([[:space:]]|$)|[[:space:]]\+[^[:space:]]+)' \
      && block "force pushes are not allowed. History is part of the audit trail."
    printf '%s' "$seg" | grep -Eq -- '(--mirror|--all|--delete|[[:space:]]:[^[:space:]]+)' \
      && block "mirror, --all and branch-deleting pushes are not allowed."
    printf '%s' "$seg" | grep -Eq "(^|[[:space:]:/])${MAIN_BRANCH}([[:space:]]|$)" \
      && block "nothing is pushed to ${MAIN_BRANCH} directly. ${MAIN_BRANCH} only changes through an owner-approved release PR."
  fi

  if printf '%s' "$seg" | grep -Eq 'gh[[:space:]]+pr[[:space:]]+review' && \
     printf '%s' "$seg" | grep -Eq -- '(--approve|[[:space:]]-a([[:space:]]|$))'; then
    block "agents never approve pull requests. Approval of record comes only from the owner on GitHub."
  fi

  if printf '%s' "$seg" | grep -Eq -- 'gh[[:space:]]+pr[[:space:]]+merge.*(--admin|--auto)'; then
    block "--admin bypasses branch protection and --auto merges without the guard. Neither is allowed."
  fi

  if printf '%s' "$seg" | grep -Eq 'gh[[:space:]]+(repo[[:space:]]+(edit|delete|rename|archive)|ruleset|secret|variable|auth[[:space:]]+(token|refresh|logout|login))' || \
     printf '%s' "$seg" | grep -Eq 'gh[[:space:]]+api.*(rulesets|/protection|collaborators|/actions/secrets|/environments|/hooks|/keys)'; then
    block "repository settings, protection rules, secrets and credentials are owner-only."
  fi

  if printf '%s' "$seg" | grep -Eq 'git[[:space:]]+config.*(core\.hooksPath|user\.(name|email))'; then
    block "changing git hooks path or commit identity is owner-only."
  fi

  if printf '%s' "$seg" | grep -Eq '(^|[[:space:]])rm[[:space:]].*\.git([[:space:]/]|$)'; then
    block "deleting git metadata is not allowed."
  fi

  if [ "${GOVERNANCE_OWNER_OVERRIDE:-}" != "1" ] && \
     printf '%s' "$seg" | grep -Eq -- "$PROTECTED" && printf '%s' "$seg" | grep -Eq -- "$WRITE_OP"; then
    block "governance files (.claude/, .github/, docs/governance/, CLAUDE.md, CODEOWNERS) are owner-only."
  fi
done < <(command_segments "$cmd")

exit 0
