---
name: review-deeper
description: Run another finding-hunt round on a PR already reviewed with review-kickoff — new lens, random deep inspection, fresh-eyes pass, propose-only consult — appending only NEW findings to the ledger. Repeat until dry. Accepts optional steering.
triggers:
  - review-deeper
  - go deeper on the review
  - find more bugs in this PR
  - another review pass
  - keep looking for findings
---

# review-deeper — loop for more findings

Another adversarial round on the current PR review. Same hard rules as
`review-kickoff`: **read-only on the repo, record-don't-fix, no posting,
writes only under `~/.reviews/`.**

## Input

Optional steering after the skill name (e.g. `review-deeper focus on the
rollback path`). If no PR is obvious from the conversation, find the most
recent `~/.reviews/*/*/pr-*/meta.json` with `status: in-review` and confirm
with the human in one line.

## Procedure

1. **Load state.** Read `findings.md` and `meta.json`. Note the round number
   R (this run is R+1). Check `gh pr view <N> --json headRefOid` — if the head
   moved since `meta.json`, FIRST reconcile: diff
   `<old_sha>..<new_sha>`, re-anchor every open finding (still present →
   keep; fixed → `state: resolved`; code gone → `state: stale`), update
   `head_sha`, and tell the human what changed before hunting.

2. **Pick this round's lens.** Steering, if given, is the lens. Otherwise
   rotate through whichever of these has NOT had a dedicated round yet:
   1. concurrency & state (races, locks, async ordering, idempotency)
   2. security & input handling (authz, validation, injection, secrets)
   3. API contracts & backwards compatibility (callers, serialization, versioning, public types)
   4. tests & omissions (what's untested, what tests lie, missing migration/docs/flags)
   5. failure modes & operations (timeouts, retries, partial failure, observability, rollback)
   6. performance on the hot paths

3. **Random deep inspection.** Independently of the lens, pick ONE changed
   file or subsystem you have not yet traced end-to-end — semi-randomly, not
   the one you know best — and deeply investigate it: trace its functionality
   and execution flows through the files it imports and the files that import
   it, then do a super careful, methodical, critical check with fresh eyes for
   any obvious bugs, problems, errors, issues, or silly mistakes the change
   introduces there. Comply with ALL rules in the repo's AGENTS.md /
   instructions files when judging.

4. **Fresh-eyes re-read.** Re-read the full diff once more as a skeptic,
   carrying this round's lens. Also re-test 2–3 existing open findings —
   if one doesn't survive scrutiny, mark it `state: dropped` with a reason.

5. **Consult (propose-only).** If a consultant CLI exists (`gemini`, `codex`,
   `claude` — prefer a different model family from your own), send it the diff
   plus this round's lens and the open questions, with the same verbatim
   guard as kickoff: no file modification, proposals as text-only unified
   diffs, uncertainties flagged as questions. Merge with `source:
   <model>-r<R+1>`, de-duped and verified.

6. **Append, don't rewrite.** Add only NEW findings (or state changes to old
   ones) to `findings.md`, tagged `round: R+1`. Never renumber existing
   findings. Bump `rounds` in `meta.json`.

## Report

Tell the human: how many NEW findings this round (by severity), which lens and
which randomly-inspected subsystem, any findings resolved/stale/dropped, and
the dry-run signal:

- New findings found → "worth another `review-deeper`."
- **Two consecutive rounds with zero new findings → declare the hunt dry** and
  recommend `review-walkthrough`.
