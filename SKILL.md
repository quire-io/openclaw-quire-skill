---
name: quire
description: Read tasks, projects, and task trees from Quire via the quire CLI.
version: 0.1.2
metadata:
  openclaw:
    requires:
      bins:
        - quire
    emoji: "📋"
    homepage: https://quire.io
---

# Quire

Read-only access to a user's Quire workspace via the `quire` CLI. Use this skill
when the user asks about their Quire tasks, projects, comments, or wants to act
on a Quire URL they've pasted.

Authentication is handled by the CLI's own token store (`quire login` runs an
OAuth loopback flow once per machine). No environment variables or API keys are
needed from the user.

All commands emit raw API JSON when invoked with `--json`. Shape is stable
across CLI versions — safe to depend on.

## When to use this skill

Invoke when the user asks anything along the lines of:

- "What's on my plate today?" / "What am I assigned to?"
- "What tasks are open in project X?"
- "Find tasks tagged Y in org Z that are blocked."
- "Show me the subtree of task #408."
- "Summarize this Quire URL: …"
- "Who's on the Marketing project?"

## When NOT to use this skill

- Questions about Notion, Asana, Linear, Jira, Todoist, or any tracker other
  than Quire — even if the phrasing is similar. Pick the skill that matches
  the user's tool, not this one.
- Writes (creating tasks, posting comments, completing tasks, attaching files).
  This skill is read-only in v0.1. If asked to mutate state, decline politely
  and tell the user that write support is planned for a later version.
- General productivity advice, planning, or coaching with no concrete need
  to read live Quire data.

---

## Tool: whoami

**Use for:** identity grounding — who am I logged in as, and which orgs do I
belong to? Cheap to call; useful at the start of a session to know which org's
projects are reachable.

**Command:**
```bash
quire whoami --json
```

**Output:** a single user object plus an `organizations` array.

```json
{
  "oid": "0e…",
  "id": 12345,
  "name": "Jane Doe",
  "nameText": "Jane Doe",
  "email": "jane@example.com",
  "organizations": [
    { "oid": "0e…", "id": "acme", "name": "Acme Inc.", "nameText": "Acme Inc." }
  ]
}
```

---

## Tool: list_my_tasks

**Use for:** "what's on my plate" — tasks assigned to the signed-in user.
**Exactly one** scope flag is required.

**Command:**
```bash
quire mine [--project <id> | --inbox | --org <id> | --all-orgs] [--skip-inbox] [--limit <n>] --json
```

**Scope flags (pick one):**
- `--project <id>` — one project (slug or OID).
- `--inbox` — the user's private Inbox.
- `--org <id>` — one organization.
- `--all-orgs` — every org the user belongs to. Includes Inbox by default;
  add `--skip-inbox` to exclude it.

**Other flags:**
- `--limit <n>` — positive integer or `no` for unlimited. Default is paged.

**Output:** array of task objects (`oid`, `id`, `name`, `status`, `priority`,
`due`, `assignees`, `tags`, `project`, …).

**Examples:**
```bash
quire mine --all-orgs --json                       # Everything assigned to me
quire mine --project marketing-launch --json       # Just my tasks in one project
quire mine --org acme --limit 50 --json            # First 50 in Acme org
```

---

## Tool: list_project_tasks

**Use for:** all tasks in a specific project (regardless of assignee). Use
this when the user names a project; use `list_my_tasks --project` when they
want only their own tasks in that project.

**Command:**
```bash
quire task list <project-id> [--limit <n>] [--cursor <token>] --json
```

**Args:**
- `<project-id>` — project slug, numeric ID, or OID.

**Flags:**
- `--limit <n>` — positive integer or `no` for unlimited.
- `--cursor <token>` — pass the cursor from a previous page to continue.

**Output:** array of task objects.

**Example:**
```bash
quire task list marketing-launch --json
```

---

## Tool: get_task

**Use for:** full detail on one task — description, custom fields, recurrence,
dates, assignees. Always use this before suggesting a write that the user has
to confirm (e.g. "should I close #408?") so the suggestion is grounded.

**Command:**
```bash
quire task get <id> --json
```

**Args:**
- `<id>` — accepts `#408` (short id, within current project context), a full
  OID, or a full Quire task URL. If the user pasted a URL, `quire resolve` is
  often cleaner — it returns a typed `{kind, resource}` envelope.

**Output:** single task object (raw API shape).

---

## Tool: search_tasks

**Use for:** filtered queries — "blocked tasks tagged backend in Acme org",
"high-priority items due this week in project X". Must scope with **one of**
`--project`, `--org`, or `--folder`.

**Command:**
```bash
quire task search <query> ( --project <id> | --org <id> | --folder <id> ) \
  [--mine] [--assignee <user>] [--tag <tag>] [--status <s>] \
  [--priority <p>] [--limit <n>] --json
```

**Args:**
- `<query>` — free-text search string. Pass `""` (empty) if you only want to
  filter, not text-search.

**Scope flags (pick one — required):**
- `--project <id>`
- `--org <id>`
- `--folder <id>` — a folder OID.

**Filter flags:**
- `--mine` — restrict to tasks assigned to the signed-in user.
- `--assignee <user>` — OID, numeric id, or email.
- `--tag <tag>` — tag name.
- `--status <s>` — `active`, `completed`, or numeric `0`–`100`.
- `--priority <p>` — `low`, `medium`, `high`, `urgent`, or `-1`/`0`/`1`/`2`.
- `--limit <n>` — page size.

**Output:** array of task objects.

**Example:**
```bash
quire task search "deploy" --org acme --priority high --status active --json
```

> There is **no `--due` filter.** If the user asks for "tasks due this week",
> fetch with the available filters and then filter by `due` field in your
> own logic (or just summarize what came back).

---

## Tool: get_task_tree

**Use for:** the full subtree under one task — useful when summarizing an
epic or when the user asks about subtasks of subtasks.

**Command:**
```bash
quire task tree <id> [--depth <n>] --json
```

**Flags:**
- `--depth <n>` — positive integer (default `3`) or `full` for unbounded.
  Prefer a small depth (1–3) for chat responses; only ask for `full` if the
  user explicitly wants everything.

**Output:** array of nested tree nodes. Each node has `oid`, `id`, `name`, a
`tasks` array of children, and an optional `cropped: true` flag when the
depth cut off further children.

---

## Tool: list_projects

**Use for:** discovery — "what projects do I have access to?" Filter to one
org when the user has named one.

**Command:**
```bash
quire project list [--org <id>] --json
```

**Output:** array of project objects (`oid`, `id`, `name`, `nameText`,
`organization`, `archived`, …).

---

## Tool: get_project

**Use for:** project-level metadata — owner, description, dates, archived
status, custom-field schema.

**Command:**
```bash
quire project get <id> --json
```

**Output:** single project object.

---

## Tool: resolve_url

**Use for:** turning a Quire URL the user pasted into a typed resource
without having to guess what kind of thing it points to. Handles project,
task, chat, document, organization, and user URLs uniformly.

**Command:**
```bash
quire resolve <url> --json
```

**Output:** `{ "kind": "task" | "project" | "chat" | "document" | "organization" | "user", "resource": { … } }`.

After resolving, you typically already have the full object — no follow-up
`get` call needed.

---

## Common pitfalls

1. **Singular subcommands.** The CLI uses `quire task …` and `quire project …`
   (singular), not `tasks`/`projects`. The `mine`, `whoami`, and `resolve`
   commands sit at the top level, not under `task`.
2. **`task list` requires a project argument.** It is not a global "list every
   task I can see" command. For "my tasks across everything", use
   `quire mine --all-orgs --json`.
3. **`task search` requires a scope flag** (`--project` / `--org` / `--folder`).
   Searching with no scope is rejected with a validation error.
4. **No `--due` filter on search.** Fetch then filter the `due` field yourself.
5. **IDs come in three shapes.** Project IDs accept slug, numeric id, or OID.
   Task IDs accept short id (`#408` or `408`), full OID, or full Quire URL.
   When a Quire URL is in hand, prefer `quire resolve` over guessing.
6. **Do not surface opaque OIDs (the `0e…` strings) in user-facing replies.**
   They are internal handles. Refer to tasks by name + short id (`#408`) and
   to projects by name. Use OIDs only when piping back into another CLI call.
7. **One scope at a time on `mine`.** `--project`, `--inbox`, `--org`, and
   `--all-orgs` are mutually exclusive; pick one.
8. **Rate limits exist.** Avoid fan-out loops that call `get_task` over
   hundreds of tasks in a single turn. Prefer `task tree` or `task list` to
   pull many tasks in one request.
9. **Free Quire plans restrict org-wide scope.** `quire mine --all-orgs`,
   `quire mine --org`, `quire task search --org`, and `quire task search --folder`
   return error **469** ("Quire quota exceeded … isn't supported on the free
   plan") when the signed-in user is on a free plan. If you hit 469, retry
   with a per-project scope (e.g. `quire mine --project <id> --json`) and tell
   the user the limitation. If you don't know which project, call
   `list_projects` first and either pick the obvious one or ask the user.

## Authentication failures

If a command exits with an authentication error, tell the user to run
`quire login` once in their terminal — the skill cannot drive that flow
itself (it opens a browser for OAuth). After that completes, retry.

## Reference

- CLI source and docs: <https://github.com/quire-io/quire-cli>
- AI usage recipes: see `AI_GUIDE.md` in the CLI repo for end-to-end pipe
  patterns (weekly digests, triage queues, bulk task creation from notes).
- Quire API docs: <https://quire.io/dev/api/>
