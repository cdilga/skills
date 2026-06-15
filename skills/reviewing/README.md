# squint — a PR review suite for a trusted human reviewer

Five skills that turn "someone pinged me to review their PR" into a deep,
multi-round, propose-only review where **you** stay the reviewer of record. Built
for Copilot CLI and OpenCode (also works in Claude Code and any harness that reads
`~/.agents/skills`).

The method is adapted from Dicklesworthstone's review doctrine (study the repo's
agent instructions first → deep exploration tracing execution flows, not just the
diff → cast a wider net → adversarial "fresh eyes" passes → loop until dry), with
two deliberate changes:

1. **Nothing edits code and nothing posts without you.** Consultant models (Gemini,
   Codex, the cloud coding agent) only ever *propose* fixes as text. Findings
   accumulate as scratch; you step through them one by one and the review is posted
   only after you say so.
2. **No bespoke tooling, no background jobs.** Plain `gh`, `git` worktrees, and the
   filesystem. Per-PR state is disposable — once the review is posted, GitHub is the
   record. There is no scheduled maintenance: **you are the scheduler.**

## The flow

```
Teams ping: "can you review my PR?" → copy the link
│
▼ paste into your harness (Copilot CLI / OpenCode)
squint-onboard for org/repo        # optional, once — repo docs and/or review tailoring
squint-kickoff https://github.com/org/repo/pull/123
│   boot context (AGENTS.md / repo docs / team ctx, else generics) → git worktree
│   → deep exploration (subagents) → diff review → wider net → fresh-eyes pass
│   → propose-only consult → findings scratch + ranked recommendations
▼ (come back; loop as many times as you like, with optional steering)
squint-deeper
squint-deeper focus on the migration and rollback path
│   each round: new lens (incl. a verification lens) + random deep inspection
│   + fresh eyes + consult; only NEW findings; stop after 2 dry rounds
▼
squint-walkthrough
│   step through findings: accept / edit / drop, one at a time
│   → renders the full draft → waits for your explicit "post it"
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

## Quickstart — cloud lane (Copilot coding agent, remotely hosted)

```bash
> squint-cloud setup for org/repo        # one-time: custom reviewer agent + shared doctrine in .github/
> squint-cloud review PR 123             # kick a propose-only deep review session in the cloud
> squint-cloud harvest PR 123            # pull its findings into the local scratch
> squint-walkthrough                     # your verdict still happens locally
```

## What's in the box

| Skill | When |
|---|---|
| `squint-kickoff` | You have a PR link and want the full first-round deep review (works cold, no onboarding required) |
| `squint-deeper` | Loop for more findings, optionally steered ("focus on X"); rotates lenses including a verification lens |
| `squint-walkthrough` | Step through the findings, then draft + post the review. **The only skill that posts.** |
| `squint-cloud` | Set up / run / harvest reviews on the GitHub Copilot coding agent |
| `squint-onboard` | Heavy, manual, one-time deep pass — see below |

## Onboarding — one deep pass, two kinds of output

`squint-onboard` runs the expensive part once (mining source history, work history,
design docs, prior agent/session history, architecture — using subagents) and from
that shared pass produces either or both of:

- **Repo readiness** — author/improve the repo's root `AGENTS.md` (lean, behaviour-
  changing guardrails; depth decomposed into focused `docs/`) and scaffold the
  cross-tool `.agents/skills/` layout. Benefits *every* agent in the repo.
- **Review tailoring** — generate `<team>-squint-*` thin shims and `<team>-ctx*`
  context skills (with `repos:` / `paths:` frontmatter) that sharpen later reviews.

Which it does is the loading agent's judgement, with a bias toward **both** (the deep
pass is already paid for). Session-history mining is tool-agnostic — it uses whatever
prior-session search you have, and degrades gracefully if you have none.

## State — disposable

```
~/.squint/<owner>/<repo>/pr-<N>/
  worktree/      # git worktree checkout of the PR head
  findings.md    # the scratch ledger — appended across rounds
  meta.json      # head SHA reviewed, round count, posted state
```

It's all plain text and **disposable**: `squint-walkthrough` offers to remove it
after a successful post, because GitHub is then the record. Nothing sweeps or
archives it; re-run `squint-onboard` by hand when a repo's context drifts.

## Cross-tool & CI

Both Copilot CLI and OpenCode natively read a repo's root `AGENTS.md` and both scan
`.agents/skills/`, so anything `squint-onboard` checks into a repo works for both
tools — locally and in CI — from one layout. Keep critical rules in **root**
`AGENTS.md` (nested files aren't reliably portable); `.github/copilot-instructions.md`
is optional and should be a thin pointer to `AGENTS.md`.

## House rules (every skill enforces these)

- The review agent and all consultants are **read-only on the repo** during
  analysis: no file edits, no commits, no pushes, no `gh` mutations.
- Posting happens **only** in `squint-walkthrough`, only after the rendered draft is
  shown and you explicitly approve, and only as one batched review.
- If the PR head moved since the findings were written, posting is refused until a
  `squint-deeper` reconciliation round runs.
- Tracker / CI tooling is never assumed: skills use it only if the repo's own
  instructions name it *and* it exists on the machine.
