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

### reviewing (squint suite)
Six skills for running deep, multi-round, multi-model PR reviews where you stay the reviewer of record — `squint-kickoff` (paste a PR link, get a worktree checkout + ranked findings; works cold, no onboarding required), `squint-deeper` (loop for more findings until dry, with optional steering, rotating lenses including a verification lens), `squint-walkthrough` (step through findings, then post one batched review only after explicit approval — the only skill that posts), `squint-cloud` (run propose-only reviews on GitHub's hosted Copilot agents and harvest them into the same scratch), `squint-panel` (an optional deep adversarial path — a panel of different models, default Gemini/GPT-5.4/Opus, each with a distinct lens, that cross-examine each other's findings), and `squint-onboard` (one heavy, manual deep pass that produces repo-readiness `AGENTS.md`/`.agents/skills` and/or repo-tailored review skills). Consultant models (Gemini/Codex) only ever propose fixes — nothing edits code, nothing posts without you; per-PR state is disposable and GitHub is the record once posted. See [`skills/reviewing/README.md`](skills/reviewing/README.md) for the working guide and quickstarts.

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
description: One sentence — when should an agent use this?
triggers:
  - keyword agents will think when they need this
  - another trigger phrase
---

# Instructions for the agent...
```

The `description` and `triggers` fields are what surface the skill to agents — make them reflect the *problem*, not the tool name.

PRs welcome.

## License

MIT
