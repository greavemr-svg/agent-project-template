#!/usr/bin/env bash
# Create a new agent-built project from the template. Run as the OWNER (yourself):
#   bash scripts/new-project.sh <project-name> [--private]
# Creates the repo from the template, clones it next to the current folder,
# then sets up labels, bot access and rulesets.
set -euo pipefail

NAME="${1:?usage: new-project.sh <project-name> [--private]}"
VIS="--public"; [ "${2:-}" = "--private" ] && VIS="--private"

TEMPLATE_REPO="greavemr-svg/agent-project-template"
BOT="greavemr-bot"
OWNER="$(gh api user --jq .login)"

[ "$OWNER" = "$BOT" ] && { echo "Run this as yourself, not the bot." >&2; exit 1; }

echo "== Creating $OWNER/$NAME from $TEMPLATE_REPO"
gh repo create "$OWNER/$NAME" --template "$TEMPLATE_REPO" "$VIS"

echo "== Waiting for GitHub to copy the template"
for _ in $(seq 1 20); do
  gh api "repos/$OWNER/$NAME/contents/docs/project.md" >/dev/null 2>&1 && break
  sleep 3
done

cd ..
gh repo clone "$OWNER/$NAME"
cd "$NAME"
sed -i.bak "s/^# <Project name>/# $NAME/" README.md && rm -f README.md.bak

bash scripts/setup-github.sh "$OWNER/$NAME" "$BOT"

echo
echo "== Ready: $(pwd)"
echo "   1. Accept the repo invitation as $BOT (GitHub notifications / email)."
echo "   2. In this folder: export GH_TOKEN=<bot token>; claude --agent orchestrator"
echo "   3. Describe the product idea. The first run picks the stack and builds the skeleton."
