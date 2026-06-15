---
name: squint-kickoff
description: First review round on a GitHub PR from just its URL — choose a safe checkout strategy (current folder, existing clone, worktree only when requested/preferred, or scratch clone), apply a fast/standard/deep/adversarial depth gate, trace execution flows, optionally run safe local validation, and write disposable outside-repo review scratch. You stay the reviewer of record. Never edits code, never posts. Hand off to squint-deeper and squint-walkthrough.
triggers:
  - squint-kickoff
  - squint this PR
  - kick off a review
  - someone asked me to review their PR
  - review https://github.com
  - deep review of this pull request
  - start a squint review
---

# squint-kickoff — first review round on a PR

You are a careful senior reviewer's research assistant. The **human is the
reviewer of record**. Your output is a set of **ranked, anchored findings** —
never code changes, never GitHub posts. Keep the workflow light by default and
escalate only when the user or repo context asks for more depth.

## House rules (non-negotiable, for you AND any model you consult)

1. **Read-only on the repo during analysis.** During analysis, squint-kickoff is
   strictly read-only on the repo and makes no GitHub mutations (no `gh pr review`,
   `gh pr comment`, `gh pr edit`, `gh pr merge`, …) and no
   `git commit/push/reset`; its only writes are outside the repo under the squint
   state dir. The suite's two
   deliberate GitHub-mutation exceptions live in *other* skills —
   `squint-walkthrough` (posts the final verdict) and `squint-cloud` (explicit,
   shown-before-run cloud-orchestration requests). Kickoff itself still never mutates.
2. When something looks broken you **record a finding with a proposed fix** —
   you do not fix it.
3. **Tracker / CI tooling is used only if the repo's own instructions name it
   AND it exists locally** (`which …`). Never assume such tools. The repo's
   instructions are the source of truth for what they are and how to call them.
4. If a tool you want is missing, degrade gracefully and note it in the report.

## Input

A PR URL like `https://github.com/<owner>/<repo>/pull/<N>` (or `owner/repo#N`).
Anything after the link is **steering** — extra emphasis from the human (e.g.
"they're worried about the migration"). Honor steering as an additional lens,
never as a reason to skip phases.

## Review depth gate

Infer depth from the user's words, repo onboarding, PR size/risk, and available
time. Ask only if the difference matters.

- **fast / quick / static only** — cheap static review. No subagents, no
  consultant CLIs, no cloud, no tests/dev servers unless explicitly requested.
- **standard** — default. Single-agent review with targeted code tracing and cheap
  local checks when they are likely to pay off.
- **deep** — broader local exploration, optional subagents if the harness supports
  them, targeted local validation, and at most one propose-only consultant.
- **adversarial / panel / multi-agent** — do not start from kickoff by default.
  Tell the human this is the expensive path and hand off to `squint-panel` only
  when explicitly requested or clearly warranted.

If the user says "test locally", "run it", or "boot the app", load
`references/local-validation.md` and make a safe local validation plan. If they
say "no live testing" or "just analyse statically", do not run local runtime
checks.

## Per-PR state (disposable, outside the repo)

Keep all scratch outside the target repository by default. Use
`references/state-and-anchors.md` when exact layout or schema matters.

```
<squint-state>/<owner>/<repo>/pr-<N>/
├── review.md      # human-facing scratch
├── meta.json      # compact machine state
├── logs/          # optional validation logs
└── checkout/      # optional, only if squint created one
```

This dir is **disposable**. Nothing sweeps it, nothing archives it, there is no
scheduled maintenance. Once `squint-walkthrough` posts, **GitHub is the
record** and any checkout squint created can be torn down. Reviewer voice, when needed, is
mined from posted GitHub reviews via `gh` — never from this local scratch.

## Phase 0 — Parse the URL & choose checkout strategy

```bash
gh auth status                          # fail early with a clear message if not logged in
```

- Parse `<owner>`, `<repo>`, `<N>` from the URL (or `owner/repo#N`).
- Fetch PR metadata first:

  ```bash
  gh pr view <N> --repo <owner>/<repo> \
    --json number,url,headRefOid,baseRefName,title,author,body,labels
  ```

- Locate a checkout: current directory first, then common dev dirs
  (`~/Documents/dev`, `~/dev`, `~/work`, `~/src`). If none is found, clone into
  the squint state dir or another scratch path.
- Choose the least disruptive checkout strategy:
  - **current-folder** when the current directory is the right repo and already
    corresponds to the PR head or the user clearly asked to review the current
    checkout.
  - **existing-clone** when another clean local clone can be used without branch
    changes.
  - **worktree** only when the user requested worktrees, repo onboarding says
    worktrees are preferred, the current clone is dirty/wrong branch, or parallel
    reviews would collide.
  - **scratch-clone** when no safe local checkout exists.
- Identify the remote for the base repo (often `origin`, but do not assume this
  in fork-heavy checkouts). If using a worktree, fetch into explicit refs so
  `FETCH_HEAD` cannot be overwritten by a later fetch:

  ```bash
  git fetch <base-remote> "+pull/<N>/head:refs/remotes/<base-remote>/pr/<N>" \
    "+refs/heads/<base>:refs/remotes/<base-remote>/<base>"
  git worktree add <squint-state>/<owner>/<repo>/pr-<N>/checkout refs/remotes/<base-remote>/pr/<N>
  ```

  For diffs, use `git diff <base-remote>/<base>...HEAD`.
- **Base divergence (first-class metadata).** Compute how far the PR branch is
  behind base and record it — a stale branch is a high-value signal:

  ```bash
  git rev-list --count $(git merge-base HEAD <base-remote>/<base>)..<base-remote>/<base>
  ```

  Write the count into `meta.json` as `behind_base`. Flag it if it is large.
- Write `meta.json` using the schema in `references/state-and-anchors.md`,
  including `depth`, `checkout.strategy`, `checkout.path`, `base_remote`,
  `head_sha`, `base_sha`, and `merge_base_sha`.

## Phase 1 — Study repo agent instructions (always before the code)

Boot context. Load whichever exist, in this order, and **comply with every rule
in them when judging the code** — deviations from the repo's own stated
conventions are findings:

- Any installed repo-specific squint shim, e.g. `<project>-squint-kickoff`, if
  the user invoked it. Treat it as steering plus repo context, not a fork of this
  procedure.
- In the repo: `AGENTS.md` (root, which is the keystone — nested ones are less
  portable), `CLAUDE.md`, `.github/copilot-instructions.md`,
  `.github/instructions/*.instructions.md`, `CONTRIBUTING.md`, `README.md`,
  and any `docs/` files those cite.

If no repo-specific squint skill is present, that is fine — you run on generics. Mention
**once** that running `squint-onboard` on this repo would make future reviews
richer, then continue without it.

Notice staleness at the moment of use: if loaded context references a much older
state of the repo (many commits behind `head_sha`), say so and offer a refresh —
better-timed than any scheduled check.

Discover how the project builds and tests (from instructions first, else infer
from `package.json` / `Cargo.toml` / `Makefile` / `pyproject.toml` / CI
workflows). Run local validation only according to the depth and steering gates
above; load `references/local-validation.md` if runtime checks are in scope.

## Phase 2 — PR context load

- `gh pr view <N> --repo <owner>/<repo> --json title,body,author,labels,reviews,comments,files,additions,deletions`
- `gh pr checks <N> --repo <owner>/<repo>` — note failing/flaky CI. When judging CI health, **ignore
  `skipping`/conditional lanes** — they are not failures.
- **Linked work items:** only if the PR body or repo instructions reference a
  tracker/CI system AND its CLI exists locally (`which …`), pull that context.
  Otherwise read linked GitHub issues with `gh issue view`.
- **Prior session history (tool-agnostic):** search prior agent/session history
  for what was tried, broken, or decided in the files this PR touches. Use
  whatever capability is present — e.g. a session-history search like `cass`,
  your harness's transcript search, or grepping local agent logs — and degrade
  gracefully if none exists. This surfaces context the diff alone can't show.
- Existing review comments (incl. any bot/Copilot review): read them so you
  don't duplicate — but **verify rather than trust**.

## Phase 3 — Deep exploration (the part most reviews skip)

Do NOT start from the diff. First understand the territory the diff lands in:

> Deeply investigate and understand the files this PR touches: trace their
> functionality and execution flows through the related code files which they
> import or which they are imported by, until you understand the purpose of the
> changed code in the larger context of the workflows it participates in.

For **fast** reviews, keep this to the minimum needed to avoid shallow
diff-only mistakes. For **standard** reviews, trace the main callers/callees and
nearby tests. For **deep** reviews, split distinct subsystems and use subagents
only if the harness supports them and the extra cost is justified. If subagents
are unavailable, do the same work serially and say so.

Write a short shared mental model (2–10 lines) at the top of `review.md` under
`## Context model` — the human reads this first.

## Phase 4 — Diff review

`gh pr diff <N> --repo <owner>/<repo>` (or `git diff <base-remote>/<base>...HEAD` inside the checkout — use
the remote base, not a bare local ref) — review hunk
by hunk against the context model. For every problem, record a finding (format
below). Severity taxonomy:

- **blocker** — wrong behavior, data loss, security hole, broken contract; would be a production incident
- **major** — real bug or design flaw, but bounded blast radius
- **minor** — correctness-adjacent: shaky error handling, missing edge case, misleading naming
- **nit** — style/polish; only record if the repo's own conventions are violated
- **question** — something you couldn't resolve from the code; phrase it as a genuine question

Every finding MUST carry a `file:line @ short-sha` anchor and a quoted excerpt.
**No anchor, no finding.**

## Phase 5 — Cast a wider net (omissions hunt)

Now look for what the diff does NOT contain. Go deep — don't restrict yourself to
the changed lines:

- callers/consumers of changed APIs that were not updated
- missing tests for the new behavior (and tests that now silently pass for the wrong reason)
- missing migration / rollback / feature-flag / config / docs counterparts
- concurrency: locks, awaits, shared state touched by the change
- security: input validation, authz on new paths, secrets, injection
- failure modes: what happens when the new code's dependencies are down/slow/partial
- performance on the hot paths the context model identified

Diagnose root causes from first principles before recording — a symptom without a
cause is a `question`, not a `major`.

## Phase 6 — Fresh eyes (adversarial re-read)

Switch from explorer to skeptic. Re-read the ENTIRE diff and your own findings
list with fresh eyes, looking carefully for any obvious bugs, errors, problems,
confusion you missed or got wrong — **including findings of yours that don't
survive scrutiny** (delete those; a list full of false positives is worse than a
short true one). Record — do not fix.

## Phase 7 — Second-model consult (deep only, propose-only)

Check for an independent consultant CLI: `which gemini codex claude`. **Prefer a
consultant from a different model family than the one you are running as** — a
second opinion from the same family is worth less. Run this by default only for
**deep** reviews, or when the human asks for a second opinion. If you can't tell
which family you are, prefer `gemini`. If one exists and the depth gate allows it:

- Build a consult pack: PR title/body, your context model, the full diff, and
  2–4 open questions from `review.md`.
- Invoke it non-interactively, e.g.
  `gemini -p "<consult prompt>" < consult-pack.md` (or `codex exec`), with a
  prompt that states verbatim: **"You are consulting on a code review. Do NOT
  modify any files, run any write commands, or post anywhere. Reply with: (a)
  bugs/omissions you see, each with file:line and a one-line root cause; (b) for
  each, a proposed fix as a unified diff IN TEXT ONLY; (c) answers to my
  questions. Flag anything you are unsure about as a question."**
- Merge its output with `source: gemini-r1` (etc.). De-dupe against existing
  findings; verify anything that contradicts your reading before recording. If no
  consultant CLI exists, skip and note it.

## Phase 8 — Write review.md + meta.json

Append to `<squint-state>/<owner>/<repo>/pr-<N>/review.md`. **Prefer a native
file-write tool over shell heredocs.** Harness destructive-command guards can
FALSE-POSITIVE on finding *prose* that quotes strings like `git restore` or
`rm -rf`, and report-file heuristics may resist writing. If a write is blocked,
the path is still correct — retry via an alternate write mechanism rather than
concluding writes are forbidden.

Entry format:

```markdown
## F<id> - [<severity>] <one-line title>
- anchor: src/cache/flush.ts:142 @ a1b2c3d
- state: open
- source: local-r1 | gemini-r1 | copilot-cloud | prior-review
- diff: right line 142 | left line 88 | body-only
- evidence: <quoted excerpt + 1–3 lines of why this is a problem>
- proposed fix: <concrete suggestion; small unified diff in a fenced block when useful>
- round: 1
```

If a verification angle applies (parameter tables, property/metamorphic/
differential checks, fuzzing, fault injection, mutation-style sanity checks),
note a short `## Verification strategy` block and turn missing verification into
a finding only when it protects a real risk — that lens is rotated in fully by
`squint-deeper`.

Set `meta.json` to `"status": "in-review"` and append a round entry. Keep
`review.md` light enough for a human to read in an editor; IDs exist to make
walkthrough easier, not to turn the scratch file into a tracker.

## Report to the human

Aim for **plenty of ranked, reviewable artifacts**. Give the report in this
order: a one-paragraph verdict *feel* (NOT a verdict — that's the human's), the
context model, findings ranked blocker→question with anchors and proposed fixes,
what you checked and found clean, and what you did NOT get to. Close with:

> Loop with `squint-deeper` (optionally with steering) to rotate new lenses
> until dry, then `squint-walkthrough` to step through findings and post once.
