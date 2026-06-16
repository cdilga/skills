# GitHub Cloud Review Surfaces

Load only when configuring GitHub-hosted review artifacts, especially the
GitHub Copilot Review button.

## Principle

GitHub-invoked artifacts are cloud-native. They guide GitHub's reviewer; they do
not run local squint. Do not mention `<squint-state>`, `review.md`, `meta.json`,
checkout strategy, `squint-deeper`, `squint-walkthrough`, or "loop until dry" in
files under `.github/`.

Local squint consumes GitHub output later by harvesting, deduping, ranking, and
verifying it.

## `.github/skills/code-review/SKILL.md`

Primary artifact for the GitHub Review button. Keep it short. It should tell
Copilot code review:

- follow `AGENTS.md` and repo review docs
- prioritize high-signal correctness, security, data-loss, migration, API, and
  operational issues over style noise
- use GitHub review comments and suggestions naturally
- cite concrete files/lines and explain the failing path
- mark uncertainty as a question
- avoid repo-external local workflow instructions

Do not force squint's local finding schema. GitHub may emit inline comments,
questions, suggestions, or summary feedback; local squint can normalize later.

## `.github/agents/*.agent.md`

Use for GitHub-invoked deep review agents. The prompt should:

- identify the review lens or repo risks
- ask for high-signal findings in GitHub/task format
- allow concrete suggestions when they fit the GitHub surface
- forbid commits/PRs only for review tasks; allow implementation when the user
  explicitly assigned an implementation task
- avoid all local squint state, scratch, and posting instructions

## Setup Workflow

Use `.github/workflows/copilot-setup-steps.yml` only for dependencies the GitHub
agent needs to inspect or test the repo. Keep it minimal and repo-specific.
