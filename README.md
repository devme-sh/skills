# devme Claude Code Plugin

Claude Code plugin for [devme](https://github.com/devme-sh/devme) — the executable README for multi-service dev environments.

## Install

```
claude plugin add devme-sh/claude-plugin
```

## What it does

- **`/devme setup`** — Analyzes your project and generates a `devme.toml` config file with services, steps, env vars, and dependency ordering.
- **`/devme doctor`** — Runs diagnostics, identifies failing services, and fixes issues automatically.
- **`/devme logs`** — Reads service logs for debugging.
- **Auto-triggered** — Claude detects when services are down or broken and invokes diagnostics without you asking.

## Prerequisites

Install devme:

```bash
cargo install --git https://github.com/devme-sh/devme
```

## License

MIT
