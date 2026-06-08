# devme skills

Agent skills for [devme](https://github.com/devme-sh/devme). Works with Claude Code, Cursor, Codex, and [50+ other agents](https://github.com/vercel-labs/skills).

```
npx skills add devme-sh/skills
```

Or, if you have devme installed, get the copy that's version-locked to your
binary (offline, no Node):

```
devme skill install        # into ./.claude/skills/devme
devme skill install -g     # into ~/.claude/skills/devme
```

> **`skills/devme/SKILL.md` is generated — don't edit it here.** The canonical
> source lives in the devme repo at `crates/config/skill/SKILL.md` and is
> embedded into the binary; this repo is a mirror that CI overwrites on each
> devme release. Edits here will be clobbered — change the skill in the devme
> repo instead.

## What you get

- `/devme setup` generates a `devme.toml` from your project (services, steps, env vars, dependency ordering)
- `/devme doctor` runs diagnostics and fixes failing services
- `/devme logs` reads service logs for debugging
- Also auto-triggers when it detects services are down

## License

MIT
