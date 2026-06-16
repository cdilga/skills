# squint — PR review skills

Skills for gated PR review: start from a PR URL, trace changed code beyond
the diff, loop with fresh lenses until dry, then draft and post only after
explicit approval. Built for Copilot CLI and OpenCode; also works in any harness
that reads `~/.agents/skills`.

There are two lanes. The **full lane** (`squint-kickoff` → `squint-deeper` →
`squint-walkthrough`, plus the cloud/panel/onboard skills) manages disposable
per-PR state and can post a batched review. The **simple lane** is three
ultra-lean, human-oriented skills — `squint-simple-kickoff`,
`squint-simple-fresh-eyes`, `squint-simple-peer-review` — that just surface a
findings list for a human reviewer and never touch code or GitHub.

Core posture:

- Analysis is read-only by default. Implement fixes, produce GitHub suggestions,
  or mutate PR state only when the user explicitly asks.
- Prefer a short, high-confidence findings list ordered by impact over volume.
- Use the repo's actual workflow and tools. Worktrees, cloud agents, local
  validation, and panel review are gated choices, not mandatory defaults.
- Scratch is disposable and lives outside the repo by default. After posting,
  GitHub is the record.

## The flow

```
Review request arrives with a PR link
│
▼ paste into the agent harness
squint-onboard for org/repo        # optional, once — repo docs and/or review tailoring
squint-kickoff https://github.com/org/repo/pull/123 [fast|standard|deep]
│   boot context (AGENTS.md / repo docs / project shim, else generics)
│   → choose checkout (current folder / existing clone / worktree / scratch clone)
│   → depth-gated exploration → optional safe local validation → findings scratch
▼ (come back; loop as many times as you like, with optional steering)
squint-deeper
squint-deeper focus on the migration and rollback path
│   each round: new lens (incl. a verification lens) + random deep inspection
│   + fresh eyes + optional consult; only NEW findings; stop after 2 dry rounds
│
├─▶ squint-panel            # OPTIONAL deep adversarial path, when a PR warrants it
│     a panel of different model families (Gemini / OpenAI / Opus, overridable), each a
│     distinct lens → cross-examine each other's findings → survivors fold in
▼
squint-walkthrough
│   step through findings: accept / edit / drop, one at a time
│   → renders the full draft → waits for explicit "post it"
│   → posts ONE batched review via gh, then offers to clear the scratch
```

## Quickstart — local lane (Copilot CLI or OpenCode)

```bash
# once per machine
curl -fsSL https://raw.githubusercontent.com/cdilga/skills/main/install.sh | bash

# once per repo (optional but worth it)
copilot   # or: opencode
> squint-onboard for github.com/org/repo

# every review
> squint-kickoff https://github.com/org/repo/pull/123
> squint-deeper            # repeat until it reports nothing new
> squint-walkthrough       # step through, then post
```

## Quickstart — cloud lane (GitHub-hosted review)

```bash
> onboard-cloud for org/repo             # one-time: GitHub Review-button guidance
> squint-cloud request PR 123            # optional: request native Copilot review
# GitHub invokes code review / agent tasks through its own UI, rules, or task surfaces
> squint-cloud harvest PR 123            # pull its findings into the local scratch
> squint-walkthrough                     # reviewer verdict still happens locally
```

## What's in the box

| Skill | When |
|---|---|
| `squint-kickoff` | Start review from a PR link; works cold, no onboarding required |
| `squint-deeper` | Loop for more findings, optionally steered ("focus on X"); rotates lenses including a verification lens |
| `squint-walkthrough` | Step through the findings, then draft + post the review. **The only skill that posts.** |
| `squint-cloud` | Request Copilot review and harvest GitHub findings into local squint scratch |
| `squint-panel` | *Optional* deep adversarial path — a panel of different model families (Gemini / OpenAI / Opus, overridable), distinct lenses, cross-examined |
| `squint-onboard` | Manual repo study that proposes lightweight repo artifacts — see below |
| `squint-onboard-cloud` | Cloud-specific onboarding for GitHub's Review button via `.github/skills/code-review/SKILL.md` |
| `squint-simple-kickoff` | *Simple lane.* Get oriented on a PR and read the diff with fresh eyes; understands repo + data flow. Findings only. |
| `squint-simple-fresh-eyes` | *Simple lane.* Explore and trace the flows the PR touches, then a fresh-eyes bug pass. Findings only. |
| `squint-simple-peer-review` | *Simple lane.* Deep, wide peer-review of a colleague's change — root causes, security, reliability. Findings only. |

## Simple lane

Three lean skills modelled on dicklesworthstone's review flow, adapted for
**human** review: they never modify code, never post, and keep findings anchored
to what the PR touches. Run them in order, or pick whichever pass you want.

```
> squint-simple-kickoff       # understand the PR + repo, fresh-eyes read of the diff
> squint-simple-fresh-eyes    # explore and trace the flows, then a fresh-eyes bug pass
> squint-simple-peer-review   # deep, wide colleague-style pass; root causes
```

Each one hands back a short, ranked findings list with `file:line` anchors for a
human to act on. No per-PR scratch, no state machine — that's the full lane.

## Onboarding

`squint-onboard` mines source history, work history, design docs, prior
agent/session history, architecture, and review culture as deeply as the request
warrants. It can then propose:

- **Repo readiness** — author/improve the repo's root `AGENTS.md` (lean, behaviour-
  changing guardrails; depth decomposed into focused `docs/`) and scaffold the
  review docs and optional project skills. Benefits *every* agent in the repo.
- **Review tailoring** — generate `<project>-squint-*` thin shims that set the
  repo's preferred depth, checkout strategy, safe local validation commands, and
  review lenses without copying the generic procedure.

Which it proposes is the loading agent's judgement, with a bias toward the least
invasive useful artifact. Session-history mining is tool-agnostic and skipped
when no suitable local capability exists.

`squint-onboard-cloud` is the cloud-specific path. It proposes GitHub-native
review artifacts for the Review button, especially
`.github/skills/code-review/SKILL.md`, without importing local squint scratch or
walkthrough mechanics into GitHub's reviewer.

## State — disposable

```
<squint-state>/<owner>/<repo>/pr-<N>/
  review.md      # reviewer-facing scratch, outside the repo
  meta.json      # head SHA, depth, checkout strategy, round state
  logs/          # optional local validation logs
  checkout/      # optional, only when squint created one
```

It's all plain text and **disposable**: `squint-walkthrough` offers to remove it
after a successful post, because GitHub is then the record. Nothing sweeps or
archives it; re-run `squint-onboard` by hand when a repo's context drifts.

## Cross-tool & CI

Use the right path for each surface. Project CLI skills live under
`.agents/skills/<project>-squint-*`. GitHub.com Copilot code review should use
`.github/skills/code-review/SKILL.md`; cloud custom agents use
`.github/agents/*.agent.md`. GitHub-invoked artifacts stay cloud-native and do
not mention local squint scratch/state/walkthrough mechanics. Keep critical
rules in **root** `AGENTS.md`.

## House rules (every skill enforces these)

- The review agent and all consultants are **read-only on the repo** during
  analysis: no file edits, no commits, no pushes, no `gh` mutations.
- Posting happens **only** in `squint-walkthrough`, only after the rendered draft is
  shown and explicitly approved, and only as one batched review.
- If the PR head moved since the findings were written, posting is refused until a
  `squint-deeper` reconciliation round runs.
- Tracker / CI tooling is never assumed: skills use it only if the repo's own
  instructions name it *and* it exists on the machine.
