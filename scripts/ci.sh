#!/usr/bin/env bash
# Build, lint and test. Used by CI and by agents locally, so both run the same thing.
# Detects the project type; replace the body with your exact commands once you
# know them, and keep CLAUDE.md's command table in step.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -x ./gradlew ]; then
  echo "== Gradle project"
  ./gradlew --no-daemon lint testDebugUnitTest
elif [ -f package.json ]; then
  echo "== Node project"
  npm ci
  npm run lint --if-present
  npm test
elif [ -f pyproject.toml ] || [ -f requirements.txt ]; then
  echo "== Python project"
  python -m pip install --upgrade pip
  if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
  if [ -f pyproject.toml ]; then pip install -e ".[dev]" 2>/dev/null || pip install -e .; fi
  python -m pytest
elif grep -q "Status: NOT SET UP" docs/project.md 2>/dev/null; then
  echo "== New project, not bootstrapped yet: nothing to build. The first pipeline run adds the skeleton."
  exit 0
else
  echo "No build system detected. Edit scripts/ci.sh with this project's build, lint and test commands." >&2
  exit 1
fi
