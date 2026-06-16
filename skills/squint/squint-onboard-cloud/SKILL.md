---
name: squint-onboard-cloud
description: This skill should be used when the user asks to onboard a repo for GitHub Copilot code review, the GitHub Review button, or cloud-specific PR review guidance.
triggers:
  - squint-onboard-cloud
  - onboard-cloud
  - onboard cloud review
  - onboard for GitHub review button
  - set up GitHub Copilot code review
  - create .github/skills/code-review
  - set up cloud reviews for this repo
  - cloud review onboarding
---

# squint-onboard-cloud

Onboard a repo for GitHub-hosted code review. The main output is a cloud-native
`.github/skills/code-review/SKILL.md` used by GitHub Copilot's Review button.
Do not create a local squint shim for this surface.

## Scope

- Load `references/onboarding-study.md` only as far as needed to identify this
  repo's review risks, commands, docs, and conventions.
- Load `references/github-cloud-surfaces.md` before drafting GitHub artifacts.
- Default output: `.github/skills/code-review/SKILL.md`.
- Optional outputs: `.github/copilot-instructions.md` as a short pointer,
  `.github/workflows/copilot-setup-steps.yml` only when GitHub needs dependencies
  to inspect/test the repo, and `.github/agents/*.agent.md` only when requested.

## Rules

- Propose paths and content before writing.
- Keep GitHub artifacts cloud-native. Do not mention local squint state,
  `review.md`, `meta.json`, checkout strategy, `squint-deeper`,
  `squint-walkthrough`, or local posting flow.
- Let GitHub review in GitHub's own shape: review comments, suggestions,
  questions, and task replies. Local squint can harvest later.
- Use this repo's actual review priorities. Do not import generic workflow rules
  or another repo's toolchain habits.
- Prefer concise, high-signal guidance over a long review methodology.

## Flow

1. Identify repo and default branch. Confirm write intent if unclear.
2. Read existing repo guidance first: `AGENTS.md`, `.github/copilot-instructions.md`,
   `.github/instructions/*`, existing `.github/skills/code-review/SKILL.md`,
   `CONTRIBUTING.md`, `README.md`, and cited review docs.
3. Extract only cloud-review-relevant defaults: strongest correctness risks,
   security/data/migration/API invariants, style/noise preferences, and safe
   commands GitHub can realistically run.
4. Draft `.github/skills/code-review/SKILL.md` for the Review button:
   - short frontmatter description
   - follow repo instructions/docs
   - prioritize high-impact findings over style noise
   - cite concrete paths/lines and explain the failing path
   - use GitHub suggestions when they are small and safe
   - mark uncertainty as questions
5. Propose optional GitHub agent/setup files only when they solve a concrete repo
   need.
6. Write only after explicit approval.

## Report

Return: sources checked, proposed GitHub files, why each file belongs, what was
excluded, and any org/repo setting that may block GitHub Copilot review.
