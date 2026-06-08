# devme skill evals

Behavioral end-to-end tests for the `devme` agent skill. Each scenario drops a
fixture into a throwaway directory, installs **only** this skill into it, hands
a headless agent a task, and then asserts on the **resulting state** — the files
and service states the agent produced — not on what the agent said.

The point: prove that an agent driven by `SKILL.md` actually moves the world
into the expected shape. If the skill drifts from the CLI, a scenario fails.

## Layout

```
evals/
  run.sh                 # the runner
  scenarios/
    <name>/
      task.txt           # the prompt handed to the agent (required)
      fixture/           # copied into the workdir before the agent runs (optional)
      setup.sh           # runs before the agent, cwd = workdir (optional)
      assert.sh          # the pass/fail check, cwd = workdir (required)
      teardown.sh        # cleanup, always runs if present (optional)
```

`run.sh` for each scenario: `mktemp` a workdir, copy `fixture/`, symlink this
repo's `skills/devme` into `.claude/skills/devme`, run `setup.sh`, invoke the
agent with `task.txt`, run `assert.sh`, then `teardown.sh`. Exit is non-zero if
any scenario fails; failed workdirs are kept for inspection (path is printed).

## Running locally

```sh
# Requirements: devme on PATH, and the agent under test (default: Claude Code
# `claude`, headless) with credentials available (e.g. ANTHROPIC_API_KEY).
evals/run.sh                 # all scenarios
evals/run.sh setup           # one scenario

# Plug in a different agent — it receives the task in $AGENT_PROMPT:
AGENT_CMD='my-agent "$AGENT_PROMPT"' evals/run.sh
```

## Scenarios

- **setup** — an empty Bun project (`package.json` with a `dev` script, no
  `devme.toml`). The agent must run the skill's *setup* action and write a
  `devme.toml` that parses, sets `schema_version = 1`, and models the dev server
  as a `bun`-based `[service.*]`. Daemon-free and deterministic — the CI baseline.

### Adding a scenario

Drop a new directory under `scenarios/`. Keep `assert.sh` checking *state*, not
prose. A good next one is **doctor-fix** (heavier — needs a running daemon):

```
scenarios/doctor-fix/
  fixture/devme.toml   # a [service.web] on a fixed port
  setup.sh             # squat that port, then `devme --no-input up -d`
                       #   so the service lands in Failed/CrashLoop
  task.txt             # "a devme service is failing — diagnose and fix it"
  assert.sh            # `devme --json status` shows web `running`
  teardown.sh          # `devme down`; kill the squatter
```

It exercises the *doctor* action (read JSON state → find the port conflict →
`lsof -ti :PORT | xargs kill` → `devme restart`). Left out of the default CI run
for now because it needs a live daemon; wire it in once the CI image has one.

## CI

`.github/workflows/skill-evals.yml` runs this harness on:

- **`repository_dispatch` (`devme-release`)** — fired by devme's release
  workflow on every tagged version, so the skill is re-validated against the
  binary it ships alongside (the payload carries the version tag).
- **`workflow_dispatch`** — manual runs.

The job needs an `ANTHROPIC_API_KEY` secret (for the headless agent) and a
`devme` binary (downloaded from the release artifact / installed via brew).
