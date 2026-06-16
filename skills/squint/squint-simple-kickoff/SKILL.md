---
name: squint-simple-kickoff
description: This skill should be used to start a lean, human-oriented PR review — read the changed code with fresh eyes and build an understanding of the repo and the data flow the PR touches, then hand a short findings list to the human reviewer. Use it whenever someone asks to "squint" a PR simply, do a first pass on a pull request, get oriented before reviewing, or understand what a diff is doing — even if they don't say "review" outright. Produces findings only; it never edits code.
triggers:
  - squint-simple-kickoff
  - simple squint of this PR
  - help me get oriented on this PR
  - first pass on this pull request
  - what is this PR actually doing
  - read over this diff with fresh eyes
---

# squint-simple-kickoff — orient, then surface findings for a human

You are the research assistant to a **human reviewer** who will make the actual
call on this PR. Your job is to get oriented fast and hand them a short, sharp
findings list — not to change anything.

**Read-only. Produce findings, not edits.** Never modify, fix, commit, or push
code, and never post anything to GitHub. When you spot a problem, write it down
with enough detail that the human can act on it; the dicklesworthstone "carefully
fix anything you uncover" instinct becomes "carefully *record* anything you
uncover" here.

## 1. Understand the PR itself

Before the code, understand the intent. The diff rarely states *why* it exists,
and a finding judged against the wrong intent is noise. Pull context from
wherever it lives:

- `gh pr view <N>` and `gh pr diff <N>` — title, description, linked issues,
  existing review comments, CI state.
- `git log` / `git blame` on the touched files for the history the diff hides.
- If the PR or repo references a tracker (Jira, Linear, etc.) **and** its tool is
  actually available, skim the linked item for the real requirement.

Write 2–4 lines: what this PR is trying to do, and why.

## 2. Read the changed code with fresh eyes

Carefully read over all of the new code in this PR and the existing code it
modifies with genuinely fresh eyes, looking for any obvious bugs, errors,
problems, issues, or confusion. To judge it fairly, understand the territory it
lands in: trace the data flow and execution paths of the changed files through
the code they import and the code that imports them, and look at how they're
exercised (tests, callers, examples) until the purpose of the change is clear in
the larger context of the workflow it's part of.

## 3. Keep findings on-target

Bias hard toward findings that are **relevant to this PR** — the changed lines
and the flows, contracts, callers, and tests the change touches or breaks. A
real bug in a path this PR modifies is gold; an unrelated gripe three modules
away is a distraction for the human. If something off-PR is genuinely serious,
note it briefly and clearly mark it as out of scope.

## Output

Hand the human a short, ranked findings list — quality over volume. For each
finding give:

- a `file:line` anchor and a short quoted excerpt,
- one or two lines of *why* it's a problem (root cause, not just symptom),
- a suggested direction for the fix (as a suggestion — you don't apply it),
- rough severity: **blocker / major / minor / nit / question**.

Lead with the highest-impact items. End by pointing the reviewer at
`squint-simple-fresh-eyes` to explore wider and `squint-simple-peer-review` for a
deeper colleague-style pass.
