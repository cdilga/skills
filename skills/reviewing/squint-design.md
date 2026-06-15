# squint — design

**Status:** design, updated 2026-06-15.

`squint` is a lightweight PR-review suite for a trusted human reviewer. The
default posture is cheap and forgiving: review the PR, keep scratch outside the
repo, and escalate only when the user or repo context asks for more depth.

## Skill roster

| Skill | Role |
|---|---|
| `squint-kickoff` | First PR review round. Chooses a safe checkout strategy and a review depth. |
| `squint-deeper` | Additional lens-driven rounds, including verification. |
| `squint-walkthrough` | Step through findings, draft, approve, and post one batched review. |
| `squint-cloud` | Explicitly gated GitHub Copilot code-review / cloud-agent lane. |
| `squint-panel` | Opt-in expensive adversarial multi-model review. |
| `squint-onboard` | Manual repo study that can propose AGENTS/docs and project shims. |

## Depth gates

The suite must not make every review expensive.

- **fast / static**: static analysis, no subagents, no consultant CLIs, no dev
  server/tests unless explicitly requested.
- **standard**: default. Targeted code tracing and cheap local checks when useful.
- **deep**: broader tracing, optional subagents, targeted local validation, at
  most one propose-only consultant.
- **adversarial / panel**: explicit escalation to `squint-panel`.

`test locally`, `run it`, or `boot the app` should encourage safe local
validation. `static only` or `no live testing` disables runtime checks.

## Checkout strategy

Worktrees are useful but not mandatory. `squint-kickoff` chooses the least
disruptive checkout:

1. current folder, if it is already the right repo/branch/head or the user asked
   to review the current checkout
2. existing clean clone
3. worktree, only when requested, repo onboarding prefers it, the current clone is
   dirty/wrong branch, or concurrent reviews would collide
4. scratch clone

If a worktree is used, fetch PR/base into explicit refs; never rely on
`FETCH_HEAD` after multiple fetches.

## State

Review scratch lives outside the repo by default:

```text
<squint-state>/<owner>/<repo>/pr-<N>/
  review.md
  meta.json
  logs/
  checkout/
```

`review.md` is human-facing and light touch. `meta.json` tracks machine state:
head/base SHAs, depth, checkout strategy, rounds, lenses spent, dry streak, and
cloud metadata. Exact schema lives in `references/state-and-anchors.md`.

## Onboarding

Onboarding is a study plus proposed artifacts, not an automatic repo rewrite.
Default to the least invasive useful output.

Repo-local artifacts:

```text
repo/
  AGENTS.md
  docs/agents/reviewing.md
  .agents/skills/<project>-squint-kickoff/SKILL.md
  .agents/skills/<project>-squint-deeper/SKILL.md
  .agents/skills/<project>-squint-walkthrough/SKILL.md
  .github/skills/code-review/SKILL.md
  .github/agents/deep-reviewer.agent.md
```

The `<project>-squint-*` skills are thin shims, not forks. They set project
defaults such as preferred depth, checkout strategy, validation commands, risky
subsystems, and optional panel roster, then refer back to the generic procedure.
There is no default separate context-skill pattern.

Durable context belongs in docs, usually `docs/agents/reviewing.md`, with links
to deeper architecture docs. Project artifacts should be real committed files so
teammates and CI see them. Do not invent local-only symlink infrastructure unless
the team already has a bootstrap mechanism and asks for it.

## GitHub surfaces

Use GitHub paths for GitHub surfaces:

- GitHub.com Copilot code review: `.github/skills/code-review/SKILL.md`
- Copilot cloud custom agents: `.github/agents/*.agent.md`
- Copilot CLI / OpenCode project skills: `.agents/skills/<project>-squint-*`

Cloud agent is a code-generating surface by design. Treat deep cloud review as
expensive and not structurally read-only; gate it explicitly and check for
commits/branches/PRs during harvest.

## Posting boundary

Only `squint-walkthrough` posts. It shows the full draft first, requires explicit
approval, checks that the PR head has not moved, and sends one batched GitHub
review. Findings that are not diff-anchorable go into the review body.
