#!/usr/bin/env bash
#
# Pass condition for the `setup` scenario: driven by the skill's "setup"
# action, the agent should have written a devme.toml that actually parses as a
# devme config — schema version + at least one service modelling `bun run dev`.
#
# Runs with cwd = the scenario workdir. We assert on STATE (the file it wrote),
# never on what the agent said.

set -u

fail=0
note() { echo "  - $1"; fail=1; }

if [ ! -f devme.toml ]; then
  echo "FAIL: devme.toml was not created"
  exit 1
fi

grep -qE '^[[:space:]]*schema_version[[:space:]]*=[[:space:]]*1' devme.toml \
  || note "missing 'schema_version = 1'"

grep -qE '^\[service\.' devme.toml \
  || note "no [service.*] table (nothing to run)"

# The fixture is a Bun project; a good config drives it with bun, not npm/node.
grep -qiE 'bun' devme.toml \
  || note "service cmd doesn't use bun (fixture is a Bun project)"

# devme can actually load it (catches TOML/schema mistakes the greps miss).
if command -v devme >/dev/null; then
  if ! devme --json status >/dev/null 2>&1; then
    # `status` with no daemon still parses devme.toml; a parse error exits non-zero
    # with a message. Tolerate "no daemon" but not a parse failure.
    err="$(devme --json status 2>&1 || true)"
    case "$err" in
      *parse*|*invalid*|*schema*|*"expected"*) note "devme rejects the config: $err" ;;
    esac
  fi
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: devme.toml is a valid devme config with a bun service"
fi
exit $fail
