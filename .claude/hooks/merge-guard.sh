#!/usr/bin/env bash
# PreToolUse (Bash) for the release agent: a `gh pr merge` only goes through when
# GitHub itself shows the evidence the gates require. Fails closed.
#
#  Task PR  (task/<run>-* -> feature/<run>): all checks green, latest reviewer
#           verdict is APPROVE and newer than the last commit, latest
#           "GATE G3:" comment is PASS and newer than the last commit.
#  Release PR (feature/* -> main): all checks green, the owner has approved on
#           GitHub, latest "GATE G5:" comment is PASS and newer than the last commit.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

cmd="$(bash_command)"
[ -z "$cmd" ] && exit 0

while IFS= read -r seg; do
  printf '%s' "$seg" | grep -Eq 'gh[[:space:]]+pr[[:space:]]+merge' || continue

  pr="$(printf '%s' "$seg" | sed -nE 's/.*gh[[:space:]]+pr[[:space:]]+merge[[:space:]]+#?([0-9]+).*/\1/p')"
  [ -z "$pr" ] && block "give the PR number explicitly: gh pr merge <number> ..."

  json="$(gh pr view "$pr" --json state,baseRefName,headRefName,reviewDecision,statusCheckRollup,reviews,comments,commits 2>/dev/null)" \
    || block "could not read PR #$pr from GitHub, so the merge can't be checked."

  state="$(printf '%s' "$json" | jq -r '.state')"
  base="$(printf '%s' "$json" | jq -r '.baseRefName')"
  head="$(printf '%s' "$json" | jq -r '.headRefName')"
  [ "$state" = "OPEN" ] || block "PR #$pr is $state, not OPEN."

  checks_total="$(printf '%s' "$json" | jq '.statusCheckRollup | length')"
  checks_bad="$(printf '%s' "$json" | jq '[.statusCheckRollup[]
      | select(
          (.__typename == "CheckRun" and ((.status != "COMPLETED") or ((.conclusion // "" | ascii_upcase) as $c | (["SUCCESS","NEUTRAL","SKIPPED"] | index($c)) == null)))
          or (.__typename == "StatusContext" and .state != "SUCCESS")
        )] | length')"
  [ "$checks_total" -gt 0 ] || block "PR #$pr has no CI results. Checks must run and pass before merging."
  [ "$checks_bad" -eq 0 ] || block "PR #$pr has $checks_bad check(s) not passed or still running."

  last_commit="$(printf '%s' "$json" | jq -r '[.commits[].committedDate] | max // ""')"

  gate_ok() {  # gate_ok G3 -> latest "GATE G3:" comment is PASS and after last commit
    printf '%s' "$json" | jq -e --arg g "GATE $1:" --arg lc "$last_commit" '
      [.comments[] | select(.body | startswith($g))] | sort_by(.createdAt) | last
      | . != null and (.body | test("^GATE [A-Z0-9]+: PASS")) and (.createdAt > $lc)' >/dev/null
  }

  if [ "$base" = "$MAIN_BRANCH" ]; then
    case "$head" in feature/*) ;; *) block "only feature/* release PRs may merge into $MAIN_BRANCH (this is $head)." ;; esac
    [ "$(printf '%s' "$json" | jq -r '.reviewDecision')" = "APPROVED" ] \
      || block "release PR #$pr is not approved on GitHub. The owner approves it there at Gate B."
    if [ -n "$OWNER_LOGIN" ]; then
      printf '%s' "$json" | jq -e --arg o "$OWNER_LOGIN" --arg lc "$last_commit" \
        '[.reviews[] | select(.author.login == $o and .state == "APPROVED" and .submittedAt > $lc)] | length > 0' >/dev/null \
        || block "release PR #$pr has no approval from $OWNER_LOGIN after its last commit."
    fi
    gate_ok G5 || block "release PR #$pr has no 'GATE G5: PASS' comment newer than its last commit."
  else
    case "$base" in feature/*) ;; *) block "task PRs may only merge into a feature/* branch (this targets $base)." ;; esac
    run="${base#feature/}"
    case "$head" in "task/$run-"*) ;; *) block "PR #$pr ($head) doesn't belong to run $run." ;; esac
    printf '%s' "$json" | jq -e --arg lc "$last_commit" '
      [.reviews[] | select(.body | test("VERDICT: (APPROVE|CHANGES_REQUESTED)"))] | sort_by(.submittedAt) | last
      | . != null and (.body | test("VERDICT: APPROVE")) and (.submittedAt > $lc)' >/dev/null \
      || block "PR #$pr's latest reviewer verdict is not APPROVE, or it predates the last commit. Re-run the reviewer."
    gate_ok G3 || block "PR #$pr has no 'GATE G3: PASS' comment newer than its last commit."
  fi

  audit_event "merge_allowed" "PR #$pr $head -> $base"
done < <(command_segments "$cmd")

exit 0
