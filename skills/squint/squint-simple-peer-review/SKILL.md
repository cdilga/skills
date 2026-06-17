---
name: squint-simple-peer-review
description: Run a deep, wide peer-review pass on a PR — scrutinize a colleague's change for bugs, inefficiencies, security, and reliability issues, diagnose root causes from first principles, and hand a short findings list to the human reviewer. Use as the final, most thorough simple-lane pass, casting a wider net beyond the latest commits. Findings only; never edits code.
triggers:
  - squint-simple-peer-review
  - peer review this PR
  - go deep on this pull request
  - cast a wider net on this review
  - scrutinize my colleague's code
  - find security and reliability issues in this PR
---

# squint-simple-peer-review — a deep colleague-style pass

You are assisting a **human reviewer** doing peer review of a change written by
their **fellow human colleagues**. This is the deepest, widest pass. You hand
back findings — you never change the code yourself.

**Read-only. Produce findings, not edits.** Never modify, fix, revise, commit, or
push code, and never post to GitHub. Where the dicklesworthstone flow says "fix
or revise them," here you *write them up* for the human to decide on.

## 1. Review your colleagues' work, deeply

Turn your attention to reviewing the code written by your fellow human
colleagues. Check for any issues, bugs, errors, problems, inefficiencies,
security problems, and reliability issues. For each, carefully diagnose the
underlying root cause using first-principles analysis rather than stopping at the
symptom — the human reviewer needs to understand *why* it's wrong, not just that
it looks off.

## 2. Cast a wider net

Don't restrict yourself to the latest commits — go super deep and wide. Follow
the change into the surrounding system: callers and consumers that weren't
updated, missing or now-vacuous tests, error and failure paths, concurrency and
shared state, input validation and authorization on new paths, and performance on
the hot paths the change sits on.

## 3. Keep findings on-target

Even cast wide, anchor your findings to **this PR** — the change and the flows,
contracts, and dependencies it touches, breaks, or leaves inconsistent. The
breadth exists to catch what the diff alone hides about *this* change, not to
audit the whole repo. Genuinely serious off-PR issues get a brief note marked out
of scope.

## Output

Hand the human a short, ranked findings list — quality over volume. For each
finding give:

- a `file:line` anchor and a short quoted excerpt,
- the root cause in one or two lines (first-principles, not just symptom),
- a suggested fix direction (as a suggestion — you don't apply it),
- rough severity: **blocker / major / minor / nit / question**.

Lead with blockers and majors. Drop anything that doesn't survive scrutiny;
false positives cost the reviewer more than they're worth. This is the end of the
simple squint flow — the human reviewer takes it from here.
