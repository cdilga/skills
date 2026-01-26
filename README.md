# Skills Marketplace

Personal collection of Claude Code skills.

## Installation

```bash
# Add the marketplace
/plugin marketplace add cdilga/skills

# Install all skills
/plugin install all-skills@cdilga-skills

# Or install individual skills
/plugin install looping-video@cdilga-skills
```

## Available Skills

| Skill | Description |
|-------|-------------|
| **looping-video** | Create seamlessly looping, stabilized video using ffmpeg and the doubled video technique |

## Creating New Skills

Skills follow the SKILL.md format with YAML frontmatter:

```yaml
---
name: skill-name
description: Brief description of what the skill does
---

[Skill instructions here]
```

Place skills in `skills/<skill-name>/SKILL.md`.

## License

MIT
