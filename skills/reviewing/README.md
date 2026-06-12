# reviewing — a PR review suite for a trusted human reviewer

Five skills that turn "someone pinged me on Teams asking for a review" into a
deep, multi-round, multi-model review where **you** stay the reviewer of record.
Built for Copilot CLI and OpenCode (also works in Claude Code and inside GitHub
Copilot app sessions — anything that reads `~/.agents/skills`).

The method is adapted from Dicklesworthstone's review doctrine (study the repo's
agent instructions first → deep exploration tracing execution flows, not just
the diff → explore more, casting a wider net → adversarial "fresh eyes" passes →
loop until dry), with two deliberate changes:

1. **Nothing edits code and nothing posts without you.** Consultant models
   (Gemini, Codex, the cloud coding agent) only ever *propose* fixes as text.
   Findings accumulate in a local ledger; you step through them one by one and
   the review is posted only after you say so.
2. **No custom tooling.** Plain `gh`, `git`, and the filesystem. State lives in
   `~/.reviews/` as markdown + json you can read yourself.

## The flow

```
Teams ping: "can you review my PR?" → copy the link
│
▼ paste into your harness (Copilot CLI / OpenCode)
review-kickoff https://github.com/org/repo/pull/123
│   checkout → study repo instructions → deep exploration → diff review
│   → wider net → fresh-eyes pass → Gemini consult (propose-only)
│   → findings ledger + ranked recommendations
▼ (come back; loop as many times as you like, with optional steering)
review-deeper
review-deeper focus on the migration and rollback path
│   each round: new lens + random deep inspection + fresh eyes + consult
│   only NEW findings reported; stop after 2 dry rounds
▼
review-walkthrough
│   step through findings: accept / edit / drop, one at a time
│   → renders the full review draft → waits for your explicit "post it"
│   → posts ONE batched review via gh (comment / approve / request changes)
```

## Quickstart — local lane (Copilot CLI or OpenCode)

```bash
# once per machine
curl -fsSL https://raw.githubusercontent.com/cdilga/skills/main/install.sh | bash

# once per repo (optional but worth it — mines your past reviews into persistent notes)
copilot   # or: opencode
> review-onboard for github.com/org/repo

# every review
> review-kickoff https://github.com/org/repo/pull/123
> review-deeper            # repeat until it reports nothing new
> review-walkthrough       # step through, then post
```

## Quickstart — cloud lane (Copilot coding agent, remotely hosted)

```bash
> review-cloud setup for org/repo        # one-time: custom reviewer agent + shared doctrine in .github/
> review-cloud review PR 123             # kick a propose-only deep review session in the cloud
> review-cloud harvest PR 123            # pull its findings into the local ledger
> review-walkthrough                     # your verdict still happens locally
```

## What's in the box

| Skill | When |
|---|---|
| `review-kickoff` | You have a PR link and want the full first-round deep review |
| `review-deeper` | Loop for more findings, optionally steered ("focus on X") |
| `review-walkthrough` | Step through the ledger, then draft + post the review |
| `review-onboard` | First time reviewing in a repo: mine your gh history, discover build tools, write persistent repo notes (and optionally a repo-local skill) |
| `review-cloud` | Set up / run / harvest reviews on the GitHub Copilot coding agent |

## Persistent state

```
~/.reviews/<owner>/<repo>/
  repo-notes.md        # build/test commands, architecture, conventions, tracker/CI tooling
  reviewer-voice.md    # your past review themes & phrasing, mined from gh
  pr-<N>/
    findings.md        # the ledger — one structured entry per finding
    meta.json          # head SHA reviewed, round count, posted state
```

It's all plain text. Grep it, back it up, or `git init` the folder if you want history.

## House rules (every skill enforces these)

- The review agent and all consultants are **read-only on the repo**: no file
  edits, no commits, no pushes, no `gh` mutations during analysis.
- Posting happens **only** in `review-walkthrough`, only after the rendered
  draft is shown and you explicitly approve, and only as one batched review.
- If the PR head moved since the ledger was written, posting is refused until
  a `review-deeper` reconciliation round runs.
- Tracker / CI tooling (Jira-ish, Azure-ish CLIs) is never assumed: skills use
  it only if the repo's own instructions name it *and* it exists on the machine.
