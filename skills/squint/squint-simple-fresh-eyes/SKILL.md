---
name: squint-simple-fresh-eyes
description: This skill should be used to explore a codebase around a PR and do a careful fresh-eyes pass for bugs, tracing execution flows through the files a change imports or is imported by, then handing a short findings list to the human reviewer. Use it for a deeper second look after squint-simple-kickoff, when someone asks to dig into the code paths a PR touches, follow the data flow, or take another careful look with fresh eyes. Produces findings only; it never edits code.
triggers:
  - squint-simple-fresh-eyes
  - fresh-eyes pass on this PR
  - explore the code around this change
  - trace the execution flow for this PR
  - take another careful look at this code
  - dig deeper into this pull request
---

# squint-simple-fresh-eyes — explore the flows, then surface findings

You are assisting a **human reviewer**. This is the exploration pass: wander the
code the PR lives in, build a real mental model of it, then re-read it as a
skeptic. You hand back findings — you do not change anything.

**Read-only. Produce findings, not edits.** Never modify, fix, commit, or push
code, and never post to GitHub. Where the dicklesworthstone flow says "correct
them," here you *record* them for the human instead.

## 1. Explore and trace

Explore the code files involved in and around this PR, choosing files to deeply
investigate and understand. Trace their functionality and execution flows
through the related code files which they import, or which they are imported by,
until you understand the purpose of the code in the larger context of the
workflows it participates in. Start from the files the PR touches and follow the
flow outward — that's where understanding pays off most.

## 2. Fresh-eyes check

Once you understand how it actually fits together, do a super careful,
methodical, and critical check with **fresh eyes** to find any obvious bugs,
problems, errors, issues, or silly mistakes. Read it as if you'd never seen it
and are trying to catch what the author and the first pass missed — wrong
assumptions, mishandled edge cases, broken contracts between the pieces you just
traced.

## 3. Keep findings on-target

Bias toward findings **relevant to this PR** — the changed code and the flows,
callers, contracts, and tests it touches or could break. The wide exploration is
there to judge the change in context, not to file a backlog of unrelated cleanup.
If you do hit something serious off-PR, note it briefly and mark it out of scope.

## Output

Hand the human a short, ranked findings list — quality over volume. For each
finding give:

- a `file:line` anchor and a short quoted excerpt,
- one or two lines of *why* it's a problem (root cause, not just symptom),
- a suggested fix direction (as a suggestion — you don't apply it),
- rough severity: **blocker / major / minor / nit / question**.

Drop anything that doesn't survive your own scrutiny — a short true list beats a
long noisy one. Point the reviewer at `squint-simple-peer-review` for a deeper,
wider colleague-style pass when the PR warrants it.
