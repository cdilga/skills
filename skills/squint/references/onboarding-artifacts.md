# Onboarding Artifacts

Load only when `squint-onboard` is proposing repo files. Propose paths and
content before writing.

## AGENTS.md / Docs

Keep root `AGENTS.md` short: behavior-changing rules only. Put depth in linked
docs, commonly `docs/agents/reviewing.md`.

Useful `AGENTS.md` sections:

- Rule 0: user instruction overrides this file
- hard safety rules, each with a why
- build/lint/test commands, marking run vs inferred
- repo-specific editing discipline only when it matches actual repo norms
- architecture quick reference with links to deeper docs
- project-specific non-negotiables
- completion checklist and compaction re-read hook

Do not import another repo's workflow or toolchain habits. Reject generic rules
such as "main only", "never branch", "never use worktrees", or personal-tool
appendices unless this repo already follows them. Document this repo's real
tools from the study instead.

## Project Squint Shims

Use project-scoped shims, not context skills:

```text
.agents/skills/<project>-squint-kickoff/SKILL.md
.agents/skills/<project>-squint-deeper/SKILL.md
.agents/skills/<project>-squint-walkthrough/SKILL.md
```

Each shim stays thin: load `AGENTS.md` and `docs/agents/reviewing.md` if present,
then run the generic `squint-*` skill with project defaults: preferred depth,
checkout preference, safe validation commands, risky subsystems, optional panel
roster.

Project artifacts should be real committed files by default so teammates and CI
see them. Avoid local-only symlink infrastructure unless the team asks for it.

## GitHub Surfaces

- GitHub.com Copilot code review: `.github/skills/code-review/SKILL.md`
- Copilot cloud custom agents: `.github/agents/*.agent.md`
- optional setup workflow: `.github/workflows/copilot-setup-steps.yml`

These are GitHub-invoked surfaces, not local squint shims. For content rules,
load `references/github-cloud-surfaces.md`. Keep `.github/copilot-instructions.md`
short; prefer pointing to root `AGENTS.md` and review docs.
