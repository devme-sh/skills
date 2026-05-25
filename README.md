# devme Claude Code Plugin

Claude Code plugin for [devme](https://github.com/devme-sh/devme).

```
npx skills add devme-sh/claude-plugin
```

<details>
<summary>Or install via Claude Code directly</summary>

```
claude plugin add devme-sh/claude-plugin
```

</details>

## Commands

- `/devme setup` generates a `devme.toml` from your project (services, steps, env vars, dependency ordering)
- `/devme doctor` runs diagnostics and fixes failing services
- `/devme logs` reads service logs for debugging
- Also auto-triggers when Claude detects services are down

## License

MIT
