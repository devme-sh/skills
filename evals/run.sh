#!/usr/bin/env bash
#
# devme skill evals — behavioral end-to-end tests.
#
# For each scenario, we drop a fixture into a throwaway workdir, install ONLY
# the devme skill into it (.claude/skills/devme), hand a headless agent a task,
# and then assert on the resulting STATE — not on the agent's prose. The skill
# passes a scenario only if the agent, driven by SKILL.md, actually moves the
# world into the expected shape.
#
# Requirements:
#   - devme (and its sibling binaries) on PATH
#   - the agent under test (default: Claude Code `claude`, headless) on PATH,
#     with credentials available (e.g. ANTHROPIC_API_KEY)
#   - python3 (used by some scenarios + assertions)
#
# Usage:
#   evals/run.sh                 # run every scenario
#   evals/run.sh setup           # run one scenario by name
#   AGENT_CMD='my-agent "$AGENT_PROMPT"' evals/run.sh   # test a different agent
#
# Exit code is non-zero if any scenario fails.

set -uo pipefail

EVALS_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_SRC="$(cd "$EVALS_DIR/../skills/devme" && pwd)"
SCENARIOS_DIR="$EVALS_DIR/scenarios"

# Drive the agent under test. It runs with cwd = the scenario workdir, which
# already has the devme skill installed at .claude/skills/devme. Override
# AGENT_CMD to plug in a different agent; it receives the task in $AGENT_PROMPT.
run_agent() {
  local prompt="$1"
  if [ -n "${AGENT_CMD:-}" ]; then
    AGENT_PROMPT="$prompt" bash -c "$AGENT_CMD"
  else
    # Headless Claude Code. --dangerously-skip-permissions is for the CI
    # sandbox only — the agent must be free to run devme/docker/lsof unattended.
    claude -p "$prompt" --dangerously-skip-permissions
  fi
}

command -v devme >/dev/null || { echo "FATAL: devme not on PATH"; exit 2; }

# Which scenarios to run.
if [ "$#" -gt 0 ]; then
  selected=("$@")
else
  selected=()
  for d in "$SCENARIOS_DIR"/*/; do selected+=("$(basename "$d")"); done
fi

pass=0
fail=0
summary=()

for name in "${selected[@]}"; do
  dir="$SCENARIOS_DIR/$name"
  if [ ! -f "$dir/task.txt" ]; then
    echo "skip: $name (no task.txt)"
    continue
  fi

  work="$(mktemp -d "${TMPDIR:-/tmp}/devme-eval-${name}.XXXXXX")"
  [ -d "$dir/fixture" ] && cp -R "$dir/fixture/." "$work/"
  mkdir -p "$work/.claude/skills"
  ln -s "$SKILL_SRC" "$work/.claude/skills/devme"

  echo ""
  echo "=== scenario: $name ==="
  echo "    workdir: $work"

  (
    cd "$work" || exit 99
    export SCENARIO_DIR="$dir"
    [ -f "$dir/setup.sh" ] && bash "$dir/setup.sh"
    run_agent "$(cat "$dir/task.txt")" >agent.log 2>&1
    bash "$dir/assert.sh"
    rc=$?
    [ -f "$dir/teardown.sh" ] && bash "$dir/teardown.sh" >/dev/null 2>&1
    exit $rc
  )
  rc=$?

  if [ "$rc" -eq 0 ]; then
    echo "PASS: $name"
    pass=$((pass + 1))
    summary+=("PASS  $name")
    rm -rf "$work"
  else
    echo "FAIL: $name (workdir kept for debugging: $work)"
    echo "      agent transcript: $work/agent.log"
    fail=$((fail + 1))
    summary+=("FAIL  $name  ($work)")
  fi
done

echo ""
echo "=== summary ==="
printf '%s\n' "${summary[@]}"
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
