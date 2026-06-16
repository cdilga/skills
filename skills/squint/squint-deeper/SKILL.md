---
name: squint-deeper
description: This skill should be used when an in-progress squint PR review needs another pass, a specific review lens, head-move reconciliation, verification, or more findings.
triggers:
  - squint-deeper
  - go deeper on the review
  - find more bugs in this PR
  - another review pass
  - keep looking for findings
  - run a verification pass on this PR
---

# squint-deeper — loop for more findings

Another review round on the PR started with `squint-kickoff`. Act as the
reviewer's research assistant; the user/reviewer remains reviewer of record.
Output appended scratch findings. Implement fixes or GitHub suggestions only
when the user asks.

## Hard rules (non-negotiable, for you AND any model you consult)

1. **Read-only on the repo during analysis.** No file edits, no `git
   commit/push/reset`, no `gh` mutation (`gh pr review`, `gh pr comment`, `gh pr
   edit`, …). The only writes allowed are outside the repo under the squint
   state dir.
2. When something looks broken, record a finding and proposed fix. Implement or
   generate GitHub suggestions only when the user explicitly asks.
3. **Only `squint-walkthrough` posts.** This skill never posts.
4. **Tracker/CI tooling only if the repo names it AND it exists locally.** Don't
   reach for a tool the repo hasn't adopted; degrade gracefully and note the gap.
5. Per-PR scratch is **disposable** — appended notes, not a permanent tracker.
   GitHub is the record once `squint-walkthrough` posts.

## Input

Optional steering after the skill name (e.g. `squint-deeper focus on the
migration path`, `fast`, `verification`, `static only`, `test locally`).
Steering becomes this round's lens and depth gate — honor it as emphasis, not a
reason to skip drift checks.

If no PR is obvious from the conversation, find the most recent
`<squint-state>/*/*/pr-*/meta.json` with `"status": "in-review"` and confirm the PR
with the user in one line before hunting. If NONE is found, ask the user for a
PR URL — they probably want to run `squint-kickoff` first.

## Per-PR state

State lives outside the repo under `<squint-state>/<owner>/<repo>/pr-<N>/`.
Load `references/state-and-anchors.md` if exact fields or anchors matter.

- `review.md` — reviewer-facing scratch, **append-only except state changes**.
- `meta.json` — compact machine state.
- optional `checkout/` and `logs/`.

This is disposable: no sweep, no archive, no scheduled maintenance.

## Procedure

### 1. Load state

Read `review.md` and `meta.json`. Note the current round number R — this run
produces round **R+1**.

### 2. Reconcile if the head moved

Check `gh pr view <N> --repo <owner>/<repo> --json headRefOid`. If the head SHA differs from
`meta.json`'s `head_sha`, **reconcile before hunting**:

- Diff `<old_sha>..<new_sha>` to see exactly what changed.
- Re-anchor every open finding to the new SHAs and diff positions: still present
  -> keep (update line refs); fixed by the new commits -> mark `state:
  resolved`; the code it referenced is gone -> mark `state: stale`; no longer
  inline-anchorable -> set `diff: body-only`.
- Update `head_sha` in `meta.json`.
- Report what changed in one or two lines before continuing.

### 3. Pick this round's lens

Steering, if given, is the lens. Otherwise rotate to whichever of these has NOT
yet had a dedicated round (track spent lenses in `meta.json.lenses_spent`, with
`review.md` as readable backup):

1. **Concurrency & state** — races, locks, async ordering, idempotency.
2. **Security & input handling** — authz, validation, injection, secrets.
3. **API contracts & backwards compatibility** — callers, serialization,
   versioning, public types.
4. **Tests & omissions** — what's untested, what tests lie, missing
   migration/docs/flags.
5. **Failure modes & operations** — timeouts, retries, partial failure,
   observability, rollback.
6. **Performance on the hot paths.**
7. **Verification** — the dedicated testing-strategy lens below.

### 4. Targeted or deep inspection

Independently of the lens, pick ONE changed file or subsystem you have NOT yet
traced end-to-end. In **fast** mode, keep this short. In **standard** mode, trace
the main callers/callees and nearby tests. In **deep** mode, spawn subagents for
separable subsystems if available and worth the cost; otherwise do the same work
serially. Do not run `squint-panel` from here unless the user explicitly asks
for the adversarial/multi-agent path.

Subagents are read-only and must comply with ALL rules in the repo's
`AGENTS.md` / instructions files when judging the code. Merge anything real they
surface into the new findings for this round.

### 5. Fresh-eyes re-read

Re-read the full diff once more as a skeptic, carrying this round's lens. Also
re-test 2–3 existing open findings — if one doesn't survive scrutiny, mark it
`state: dropped` with a reason.

### 6. Verification and local validation

If this round's lens is verification, load `references/verification-lens.md`.
If the user asked to run local checks or runtime behavior matters, load
`references/local-validation.md`. Respect `static only` / `no live testing`
steering even when the verification lens is selected.

Record only high-value verification gaps as findings; fold the rest into the
round summary. Separate "I ran this" from "I recommend this."

### 7. Consult (propose-only, optional)

Session-history and consultant tooling is a **capability, not a specific tool**.
If depth is **deep** or the user asks for another model, and a consultant CLI
exists locally (e.g. `gemini`, `codex`, `claude`), send it the diff plus this
round's lens and open questions under the same verbatim guard as kickoff. When
the lens is verification, ask for **test ideas with oracles**, not just "more
tests." Merge results with `source: <model>-r<R+1>`, de-duped and verified.

Good LLM uses: propose parameter axes and boundary cases; suggest invariants and
metamorphic relations; generate candidate fixtures from a spec; identify old/new
paths for differential comparison; explain why an existing test may be vacuous.
Bad uses to reject: accepting generated assertions without checking the oracle;
large brittle snapshots as "proof"; inventing guarantees not in code/docs;
replacing fuzz/property tools with one-off random examples; treating green
generated tests as evidence when they only mirror the code.

### 8. Append, don't rewrite

Add only NEW findings (or state changes to existing ones) to `review.md`,
tagged `round: R+1`. Never renumber existing findings. Append a round entry in
`meta.json`, update `lenses_spent`, and adjust `dry_streak`.

Prefer a native file-write tool over shell heredocs when appending findings: a
harness's destructive-command guard can false-positive on finding prose that
contains strings like `git restore` or `rm -rf`. If a write is blocked, the path
is still correct — retry via an alternate write mechanism.

## Report

Report:

- How many NEW findings this round, by severity.
- Which lens this round used and which subsystem got the random deep inspection.
- Any findings reconciled (resolved/stale), dropped, or re-anchored after a head
  move.
- The dry-run signal:
  - New findings found → "worth another `squint-deeper`."
  - **Two consecutive rounds with zero new findings → declare the hunt DRY** and
    recommend `squint-walkthrough` to step through and (optionally) post.
