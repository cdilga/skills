# cdilga/skills

A collection of AI coding agent skills that work across Claude Code, Cursor, Codex, OpenCode, Gemini CLI, Windsurf, Kimi, and GitHub Copilot.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/cdilga/skills/main/install.sh | bash
```

Clones to `~/.local/share/cdilga-skills`, installs into `~/.agents/skills/` (the shared hub), and creates per-agent symlinks automatically. Re-run to update, or:

```bash
git -C ~/.local/share/cdilga-skills pull
```

## Agent compatibility

| Agent | Skills path |
|---|---|
| Claude Code | `~/.claude/skills/` + plugin system |
| Cursor | `~/.cursor/skills/` |
| Codex | `~/.codex/skills/` |
| OpenCode | `~/.config/opencode/skills/` |
| Gemini CLI | `~/.gemini/skills/` |
| Windsurf | `~/.codeium/windsurf/skills/` |
| Kimi | `~/.kimi/skills/` |
| GitHub Copilot | `~/.copilot/skills/` |

All agent dirs symlink to `~/.agents/skills/` — one `git pull` updates everywhere.

### Claude Code native install

If you prefer Claude Code's built-in plugin system:

```
/plugin marketplace add cdilga/skills
/plugin install all-skills@cdilga-skills
```

Or add via **Settings → Plugins** and search for `cdilga/skills`.

## Skills

### squint
Seven skills for PR reviews where the requester stays reviewer of record — `squint-kickoff`, `squint-deeper`, `squint-walkthrough`, `squint-cloud`, `squint-panel`, `squint-onboard`, and `squint-onboard-cloud`. Scratch lives outside the repo by default; posting still requires explicit approval. See [`skills/squint/README.md`](skills/squint/README.md) for the working guide and quickstarts.

### cass
Search all past AI coding agent histories (Claude Code, Cursor, Codex, OpenCode, etc.) using the [`cass`](https://github.com/Dicklesworthstone/coding_agent_session_search) CLI. Find how you solved something before, mine patterns, or look up historical context across all your conversations.

> **Requires `cass`** — first time: read [`skills/cass/setup.md`](skills/cass/setup.md)

### suno-sounds
Generate sound effects, foley, and music via the [Suno API](https://suno.com). Covers one-shot SFX, ambient audio, voice-over, and full songs — batch via API or interactive via the web UI.

### looping-video
Create seamlessly looping, tripod-stable video from handheld footage using `ffmpeg` and `vidstab`. Good for hero section backgrounds and cinemagraphs.

## Adding your own skills

Each skill is a directory with a `SKILL.md`:

```
skills/
└── my-skill/
    └── SKILL.md
```

```yaml
---
name: my-skill
description: This skill should be used when the user asks to do a specific task this skill handles.
---

# Instructions for the agent...
```

The `name` and `description` fields are the portable trigger metadata. Keep descriptions concise, concrete, and phrased around the user request that should load the skill.

PRs welcome.

## License

MIT
