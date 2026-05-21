# Changelog

All notable changes to this skill are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the version
numbers match the `version:` field in [`SKILL.md`](SKILL.md) (which is what
ClawHub publishes).

## [Unreleased]

(nothing yet)

## [0.2.0] — 2026-05-21

### Added

First write surface for the skill — the 0.2.x light-writes slice from
[zkoss/boeneo#24746](https://github.com/zkoss/boeneo/issues/24746). All
four tools share a write-safety protocol in SKILL.md: the model restates
the change in plain language and waits for explicit user confirmation
before invoking.

- `create_task` — wraps `quire task create`. Required `--name`; optional
  description, priority, dates, assignees, tags, parent/sibling
  positioning, and recurrence.
- `update_task` — wraps `quire task update`. Full flag surface: name,
  description, status, priority, dates, tags, assignees, successors,
  custom fields, and recurrence.
- `complete_task` — wraps `quire task complete`. Preferred over
  `update_task --status 100` for marking tasks done.
- `add_comment` — wraps `quire comment add`. `--text` accepts plain
  string, `-` for stdin, or `@/path/to/file` for long content. SKILL.md
  tells the model to quote the comment text verbatim back to the user
  before sending, since the user is on the hook for the wording.

### Changed

- Skill `description` rewritten to enumerate read and write surfaces.
- "When NOT to use this skill" narrowed: the remaining deferred writes
  are delete, attach, move/transfer, uncomplete, comment edit/delete,
  and approval workflows.
- README tool table grew a `Kind` column distinguishing reads from writes.

## [0.1.3] — 2026-05-21

### Added

- Pitfall #9: free-plan recovery. `mine --all-orgs`, `mine --org`, and
  `task search --org`/`--folder` return error 469 on free Quire plans.
  Skill now tells the model to fan out via `list_projects` →
  per-project `list_my_tasks`, with a >10-project guardrail to avoid
  blind fan-out.

## [0.1.2] — 2026-05-21

### Added

- Note documenting the free-plan 469 limitation on org-wide scopes
  (recovery guidance landed in 0.1.3).

## [0.1.0] — 2026-05-20

Initial release. Nine read-only tools shipped:

- `whoami`, `list_my_tasks`, `list_project_tasks`, `get_task`,
  `search_tasks`, `get_task_tree`, `list_projects`, `get_project`,
  `resolve_url`.
- CI validator: parses every `quire ...` invocation out of SKILL.md
  bash fences and asserts each resolves against the installed CLI.

Deviations from the spec in
[zkoss/boeneo#24746](https://github.com/zkoss/boeneo/issues/24746):
shipped 9 tools (not 6) after auditing the real CLI surface — the spec
assumed plural `tasks`/`projects` subcommands and a `--mine` flag on
`task list` that don't exist. Real commands are singular, `mine` is
top-level, and `whoami` + `resolve_url` were added for cheap
chat-surface wins.

[Unreleased]: https://github.com/quire-io/openclaw-quire-skill/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/quire-io/openclaw-quire-skill/releases/tag/v0.2.0
[0.1.3]: https://github.com/quire-io/openclaw-quire-skill/releases/tag/v0.1.3
