---
name: squint-onboard
description: Study a repo in depth and propose lightweight review artifacts — root AGENTS.md guardrails, review docs, and project-specific squint shims. Use when onboarding a repo for review or making it agent-ready before the first review.
triggers:
  - squint-onboard
  - onboard this repo for review
  - set up review context for this repo
  - author or improve this repo's AGENTS.md
  - make this repo agent-ready
  - generate project review skills for this repo
  - deeply study this codebase before reviewing
  - first time reviewing in this repo
---

# squint-onboard

Onboard lightly. Infer the smallest useful output, study only enough to support
it, then propose files before writing.

## Scope

- **Study only**: gather repo review context and report recommendations.
- **AGENTS/docs**: load `references/onboarding-study.md`, then
  `references/onboarding-artifacts.md`.
- **Project squint shims**: load both onboarding references.
- **GitHub Review-button/cloud setup**: use `squint-onboard-cloud` unless the
  user explicitly wants this general onboarding pass to include those artifacts.

Ask only when repo, project path, or intended output is genuinely ambiguous.
Default to a concise recommendation, not broad repo churn.

## Rules

- Discovery is read-only by default. Edit repo files only after showing exact
  proposed paths/content and getting approval.
- Local validation is allowed when requested or clearly useful; obey
  `static only` / `no live testing`. Load `references/local-validation.md`.
- Summarize durable guidance. Do not commit raw tickets, chats, transcripts,
  incident details, secrets, customer data, or person-specific commentary.
- Prefer real committed project artifacts over local-only symlinks.
- Reuse existing repo conventions. Do not impose generic workflow rules.

## Flow

1. Identify repo, project slug, monorepo path if any, and requested output.
2. Read existing repo instructions/docs first.
3. Load only the reference needed for the requested output.
4. Mine history/reviews/session context only as far as it changes the artifact.
5. Propose exact paths and concise content/diffs.
6. Write only after explicit approval.

## Report

Return: sources checked, access gaps, strongest repo-specific review risks,
commands discovered/run, recommended artifacts, and what was deliberately skipped.
