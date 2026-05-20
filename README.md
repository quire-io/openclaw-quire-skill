# openclaw-quire-skill

An [OpenClaw](https://openclaw.dev) skill that lets chat agents read tasks,
projects, and task trees from [Quire](https://quire.io) by shelling out to
the [`quire`](https://github.com/quire-io/quire-cli) CLI.

This is a read-only v0.1 surface. Writes (create / update / complete tasks)
are deferred to a later version.

## Install

```bash
openclaw skills install quire
```

Or, from a local clone:

```bash
openclaw skills install ./openclaw-quire-skill
```

## Prerequisites

- [`quire` CLI](https://github.com/quire-io/quire-cli) on `$PATH`.
- One-time auth: run `quire login` in a terminal — it opens a browser for
  OAuth. After that, every host using the skill reuses the same token store.

The skill declares `quire` in `requires.bins`, so OpenClaw will refuse to
load it until the binary is present.

No environment variables, no API keys to paste.

## What the skill exposes

Nine read tools, all backed by `quire <command> --json`:

| Tool | Wraps |
|---|---|
| `whoami` | `quire whoami` |
| `list_my_tasks` | `quire mine` |
| `list_project_tasks` | `quire task list` |
| `get_task` | `quire task get` |
| `search_tasks` | `quire task search` |
| `get_task_tree` | `quire task tree` |
| `list_projects` | `quire project list` |
| `get_project` | `quire project get` |
| `resolve_url` | `quire resolve` |

See [`SKILL.md`](SKILL.md) for the full manifest the model reads at install
time — including when-to-use guidance, common pitfalls, and example prompts.

## Why a skill and not a hosted integration?

Because `quire-cli` already exists, already handles auth, and already speaks
JSON. The skill is ~one Markdown file telling the model which command to
run for which question. There is nothing to host, nothing to scale, nothing
to keep secret.

The strategic plan is for `quire-cli` itself to expose an MCP server in a
future version (`quire mcp`). When that lands, this skill stays useful for
OpenClaw-specific contexts but new MCP-aware clients can talk to Quire
directly.

## Development

The skill is plain Markdown — no build step, no tests beyond manifest
validation.

```bash
# Validate frontmatter and that every documented `quire ...` command
# resolves against the installed CLI:
.github/scripts/validate.sh   # added in a follow-up PR

# Dry-run publish to ClawHub (does not actually publish):
clawhub skill publish . --slug quire --dry-run
```

## License

[MIT-0](LICENSE) — no attribution required.
