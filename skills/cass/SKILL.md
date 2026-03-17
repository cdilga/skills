---
name: cass
description: Search all past AI coding agent histories (Claude Code, Cursor, Cline, OpenCode, etc.) using cass — find how you solved something before, mine patterns, investigate bugs, or look up historical context across all your conversations
triggers:
  # Explicit tool mentions
  - cass
  - cass search
  - coding agent search
  - search agent history
  - search past sessions

  # Context-building tasks — agent is exploring/understanding unfamiliar territory
  - understand the codebase
  - understand this codebase
  - build context
  - building context
  - explore the codebase
  - explore the project
  - understand the architecture
  - understand this architecture
  - understand the project structure
  - understand how this works
  - understand how X works
  - get context on
  - gather context

  # Investigation tasks — agent is diagnosing something unknown
  - investigate this bug
  - investigate this error
  - investigate this issue
  - diagnose this bug
  - diagnose this error
  - track down this bug
  - understand this error
  - understand why this is happening
  - understand what caused
  - figure out what happened
  - figure out why
  - research this problem

  # Approaching difficult problems — agent is stuck or uncertain
  - not sure how to approach
  - unclear how to approach
  - not sure how to implement
  - not sure how to handle
  - looking for patterns
  - look for patterns
  - find patterns for
  - find examples of
  - find prior examples
  - find prior art
  - what's the pattern for
  - what pattern to use
  - best approach for
  - best way to implement
  - how to implement this
  - how to handle this

  # Analytics / token tracking
  - token usage across
  - which projects use the most tokens
  - token analytics
  - agent analytics
  - session analytics
---

# cass — Coding Agent Session Search

> **Requires**: `cass` CLI. Not installed or first run? → read `setup.md` (index build, model install, diagnostics). Read it once, never again.

Search across **all your AI coding agent histories** (Claude Code, Cursor, Cline, OpenCode, ChatGPT, and 15+ others) using a single tool. cass indexes everything into a local SQLite DB and lets agents query it with structured JSON output.

**Binary**: `~/.local/bin/cass` | **Version**: 0.2.1 | **Repo**: github.com/Dicklesworthstone/coding_agent_session_search

## When cass Shines

- *"How did I solve X before?"* — search all past sessions regardless of which IDE/agent
- *"What was that workaround for Y bug?"* — find debugging steps and fixes from history
- *"Which GitHub issue number was that?"* — cross-reference past issue discussions
- *"How have I approached auth/caching/migrations?"* — mine your own coding patterns
- *"What's consuming the most tokens?"* — analytics across agents and projects

## Quick Start for Agents

```bash
# 1. Health check (always first, fast)
cass status --json 2>/dev/null

# 2. Search with token-efficient output
cass search "your query" --robot-format toon --limit 10 --max-content-length 400 2>/dev/null

# 3. View a result in context
cass view <source_path> -n <line_number> -C 5 2>/dev/null
```

## Search Command

```bash
cass search "query" [OPTIONS]

# Output formats (pick one)
--robot-format toon       # token-optimized, best for agents
--robot-format json       # pretty JSON
--robot-format compact    # single-line JSON
--robot / --json          # enables JSON mode (auto-suppresses INFO logs)

# Filter results
--agent claude_code       # agent slug: claude_code, opencode, cursor, cline, codex, chatgpt...
--workspace /my/project   # filter to specific project
--today / --week / --days 30
--since 2025-01-01
--limit 10 --offset 10    # pagination

# Token management
--max-content-length 400  # truncate snippets (adds *_truncated: true)
--max-tokens 2000         # soft budget
--fields title,snippet,score,source_path,line_number  # select only needed fields

# Overview queries (99% token reduction)
--aggregate agent         # count by agent instead of listing results
--aggregate workspace     # count by project
--aggregate date --week   # time distribution
```

## Follow-Up Commands

```bash
# View line in context from a search result's source_path + line_number
cass view /path/to/session.jsonl -n 42 -C 10

# Expand around a session line
cass expand /path/to/session.jsonl --line 42

# Export a session to markdown
cass export /path/to/session.jsonl --format markdown
```

## Self-Discovery (agents should run these first)

```bash
cass robot-docs guide        # quickstart handbook
cass robot-docs commands     # full flag reference
cass robot-docs examples     # usage examples
cass capabilities --json     # features, connectors, limits
```

## Known Issues & Gotchas

### Silent reduced performance — semantic model missing
**Check**: `cass models status` — look for `✗ onnx/model.onnx`
**Impact**: If `onnx/model.onnx` is missing, semantic/hybrid search silently falls back to lexical-only. Search recall is worse for conceptual queries. You may not notice — the tool still says "Ready".
**Fix**:
```bash
cass models status      # check which files have ✗
cass model install      # downloads ~86MB embedding model
cass models status      # verify all show ✓
```
This is a trap — you can run cass for weeks with degraded search quality without realising.

### `cass doctor` false-positive + dangerous `--fix` (bug #117)
**Symptom**: `cass doctor` reports `fts_messages` missing even though search works fine.
**Reality**: Known bug. The FTS table exists and has data; `doctor` mischecks it.
**WARNING**: Do NOT run `cass doctor --fix` — it corrupts the DB:
- Creates duplicate `fts_messages` entries in `sqlite_master`
- Breaks `PRAGMA integrity_check`
- Still exits nonzero after "fixing" — so you've just made things worse

**Real check**: `cass search "test" --limit 1 2>/dev/null` — if results come back, FTS is fine.

### Bare subcommand = "Could not parse arguments" (bug #118)
These all fail with a useless error if run without required args:
`cass analytics`, `cass search`, `cass robot-docs`, `cass view`, `cass export`, `cass expand`, `cass sources`, `cass models`, `cass import`

**Fix**: always provide args or `--help`:
```bash
cass analytics --help          # show subcommands
cass analytics status --json   # works
cass robot-docs guide          # needs topic
cass search "something"        # needs query
```

### TUI disabled in non-TTY
`cass tui` fails with "No subcommand provided; in non-TTY contexts TUI is disabled".
In agent contexts, use `cass search` — TUI is human-only.

### INFO logs in output
Without `--robot`/`--json`, INFO and WARN messages stream to stderr and can pollute output.
Always use `--robot-format toon` or append `2>/dev/null` in agent contexts.

## Common Patterns

```bash
# How was X done before in this project?
cass search "authentication middleware" --workspace /my/project --robot-format toon --limit 5 --max-content-length 500 2>/dev/null

# Find a past bug fix across all agents
cass search "cors error fix" --week --robot-format toon --limit 8 2>/dev/null

# Overview: which projects have most activity?
cass search "*" --json --aggregate workspace 2>/dev/null

# Find GitHub issue discussions
cass search "issue #" --agent claude_code --robot-format toon --limit 10 2>/dev/null

# Token analytics
cass analytics status --json 2>/dev/null
cass analytics tokens --days 7 2>/dev/null
```

## Index Management

```bash
cass index           # incremental update (fast)
cass index --full    # full reindex (slow, use if results seem stale)
cass stats --json    # see indexed counts
```

## Full Command List

```
search        One-off search (primary agent command)
status/state  Quick health check — use this, not doctor
health        Minimal liveness check (<50ms)
capabilities  Features, connectors, limits as JSON
robot-docs    Machine-focused docs — START HERE
view          View session file at specific line
expand        Expand context around a session line
context       Session context
export        Export to markdown/HTML
stats         Indexed data statistics
diag          Diagnostic info (safer than doctor)
index         Run indexer
analytics     Token/tool/model analytics
models/model  Manage semantic search models
sources       List indexed sources
timeline      Timeline of sessions
tui           Interactive TUI (human use only)
doctor        DB diagnostics — AVOID --fix (corrupts DB)
introspect    Full API schema introspection
api-version   API + contract version
```
