#!/usr/bin/env bash
# One-off setup, run by the OWNER (authenticated as yourself, not the bot):
#   bash scripts/setup-github.sh <owner>/<repo> <bot-username>
#
# - Creates the labels the pipeline uses
# - Gives the bot account write access (it can push branches and open PRs; it
#   cannot approve its own PRs or bypass the rulesets)
# - Creates two rulesets:
#     main:       PR required, 1 approval from a code owner (you), approval must
#                 come after the last push, required checks, no force push or deletion
#     feature/*:  no force push (task merges are gated by the merge guard)
#
# Rulesets are free on public repos. Private repos need GitHub Pro/Team.
set -euo pipefail

REPO="${1:?usage: setup-github.sh <owner>/<repo> <bot-username>}"
BOT="${2:?usage: setup-github.sh <owner>/<repo> <bot-username>}"

me="$(gh api user --jq .login)"
if [ "$me" = "$BOT" ]; then
  echo "Run this as the owner, not as the bot account." >&2
  exit 1
fi

echo "== Labels"
for l in "epic:5319e7" "task:1d76db" "idea:fbca04" "descoped:cfd3d7" "governance:b60205"; do
  gh label create "${l%%:*}" --color "${l##*:}" --repo "$REPO" --force
done

echo "== Bot collaborator ($BOT, write access)"
gh api -X PUT "repos/$REPO/collaborators/$BOT" -f permission=push >/dev/null
echo "   Invitation sent. Accept it while signed in as $BOT."

echo "== Ruleset: main"
gh api -X POST "repos/$REPO/rulesets" --input - >/dev/null <<'JSON'
{
  "name": "governance-main",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": true,
        "require_last_push_approval": true,
        "required_review_thread_resolution": true
      } },
    { "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": true,
        "required_status_checks": [ { "context": "build-test" }, { "context": "governance" } ]
      } }
  ],
  "bypass_actors": []
}
JSON

echo "== Ruleset: feature/*"
# Only history protection here: the orchestrator and release agent commit docs
# and version bumps straight to feature/<run>, and task merges into it are
# gated by the merge guard (CI green + reviewer verdict + G3 comment).
gh api -X POST "repos/$REPO/rulesets" --input - >/dev/null <<'JSON'
{
  "name": "governance-feature",
  "target": "branch",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["refs/heads/feature/**"], "exclude": [] } },
  "rules": [ { "type": "non_fast_forward" } ],
  "bypass_actors": []
}
JSON

echo "== Done. Also turn on in Settings > Code security: Dependabot alerts, secret scanning, push protection, CodeQL default setup."
