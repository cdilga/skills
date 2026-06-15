---
name: squint-deeper
description: Run another finding-hunt round on a PR already started with squint-kickoff — reconcile if the head moved, rotate to a fresh lens (including a verification lens covering parameter tables, properties, fuzzing, metamorphic/differential checks, fault injection, and mutation-style ideas), do random deep inspection of an untouched subsystem, a fresh-eyes pass, and an optional propose-only consult — appending only NEW findings to per-PR scratch. Loop until dry. Read-only on the repo; never edits code, never posts. Accepts optional steering.
triggers:
  - squint-deeper
  - go deeper on the review
  - find more bugs in this PR
  - another review pass
  - keep looking for findings
  - run a verification pass on this PR
---

# squint-deeper — loop for more findings

Another adversarial round on the PR you started with `squint-kickoff`. You are
the reviewer's research assistant; the human stays the reviewer of record. Your
output is appended scratch findings, never code and never a posted review.

## Hard rules (non-negotiable, for you AND any model you consult)

1. **Read-only on the repo during analysis.** No file edits, no `git
   commit/push/reset`, no `gh` mutation (`gh pr review`, `gh pr comment`, `gh pr
   edit`, …). The only writes allowed are under `~/.squint/`.
2. When something looks broken, you **record a finding with a proposed fix** —
   you do not fix it.
3. **Only `squint-walkthrough` posts.** This skill never posts.
4. **Tracker/CI tooling only if the repo names it AND it exists locally.** Don't
   reach for a tool the repo hasn't adopted; degrade gracefully and note the gap.
5. Per-PR scratch is **disposable** — appended notes, not a permanent ledger.
   GitHub is the record once `squint-walkthrough` posts.

## Input

Optional steering after the skill name (e.g. `squint-deeper focus on the
migration path`). Steering becomes this round's lens — honor it as the emphasis,
not a reason to skip phases.

If no PR is obvious from the conversation, find the most recent
`~/.squint/*/*/pr-*/meta.json` with `"status": "in-review"` and confirm the PR
with the human in one line before hunting. If NONE is found, ask the human for a
PR URL — they probably want to run `squint-kickoff` first.

## Per-PR state

State lives under `~/.squint/<owner>/<repo>/pr-<N>/`:

- `worktree/` — the read-only checkout from `squint-kickoff`.
- `findings.md` — scratch, **append-only**. NOT a permanent ledger.
- `meta.json` — `{ pr, url, head_sha, base, rounds, status }`.

This is disposable: no sweep, no archive, no scheduled maintenance.

## Procedure

### 1. Load state

Read `findings.md` and `meta.json`. Note the current round number R — this run
produces round **R+1**.

### 2. Reconcile if the head moved

Check `gh pr view <N> --json headRefOid`. If the head SHA differs from
`meta.json`'s `head_sha`, **reconcile before hunting**:

- Diff `<old_sha>..<new_sha>` to see exactly what changed.
- Re-anchor every open finding to the new SHAs: still present → keep (update
  line refs); fixed by the new commits → mark `state: resolved`; the code it
  referenced is gone → mark `state: stale`.
- Update `head_sha` in `meta.json`.
- Tell the human what changed in one or two lines before continuing.

### 3. Pick this round's lens

Steering, if given, is the lens. Otherwise rotate to whichever of these has NOT
yet had a dedicated round (track which lenses are spent in `findings.md`):

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

### 4. Random deep inspection of an untouched subsystem

Independently of the lens, pick ONE changed file or subsystem you have NOT yet
traced end-to-end — semi-randomly, not the one you know best. **Spawn a subagent**
to investigate it deeply: trace its functionality and execution flows through the
files it imports and the files that import it, then do a careful, methodical,
critical check with fresh eyes for any obvious bugs, problems, errors, issues, or
silly mistakes the change introduces there. Spawn more than one subagent if there
are several untouched subsystems worth a parallel sweep.

Subagents are read-only and must comply with ALL rules in the repo's
`AGENTS.md` / instructions files when judging the code. Merge anything real they
surface into the new findings for this round.

### 5. Fresh-eyes re-read

Re-read the full diff once more as a skeptic, carrying this round's lens. Also
re-test 2–3 existing open findings — if one doesn't survive scrutiny, mark it
`state: dropped` with a reason.

### 6. Verification lens (when this round's lens is verification)

When this round is the verification lens (or steering points at testing), run a
review-grade verification pass. Posture stays **read-only**: run existing safe
tests when useful, but propose verification work as findings — do not create
test files, change code, or post unless the human explicitly asks to implement.

**Core philosophy.** Verify behavior, not implementation trivia. Prefer the
cheapest test that can falsify the riskiest assumption. Treat LLM-generated tests
as hypotheses; keep only tests with a real oracle. A missing test is a finding
only when it protects a meaningful risk. Match the tactic to the code shape,
project maturity, time budget, and existing tooling — don't add heavyweight
methods blindly. Distinguish "I ran this" from "I recommend this"; never imply
coverage you did not obtain.

**Verification ladder** (cheap → heavier; stop when residual risk no longer
justifies more machinery):

1. **Existing focused checks** — targeted unit/integration tests, type checks,
   linters, CI failures, contract tests already present.
2. **Example & regression tests** — concrete cases from the PR, bug report,
   ticket, incident, or a review finding.
3. **Parameter & boundary tables** — roles, states, null/empty/max values,
   encoding, time zones, retries, feature flags, permission combinations.
4. **Property-based checks** — generated inputs for invariants: round-trip,
   idempotence, monotonicity, ordering, conservation, reversibility,
   normalization, no-crash.
5. **Metamorphic tests** — related inputs where exact output is hard but a
   relation must hold: permutation invariance, filtering subsets, scaling,
   renaming, adding irrelevant data, replaying after normalization.
6. **Differential tests** — compare against an old implementation, reference
   library, database query, API version, or feature-flag path, allowing for
   documented differences.
7. **Stateful / model-based tests** — workflows, state machines, carts, ledgers,
   retries, queues, lifecycle transitions, distributed jobs.
8. **Fuzzing & corpus tests** — parsers, deserializers, query builders, protocol
   handlers, file formats, text processing, user-controlled inputs, compression,
   crypto boundaries, native-code interfaces.
9. **Fault & concurrency injection** — timeouts, partial failure, duplicate
   messages, reordering, clock changes, lock contention, cancellation, crashes,
   rollback, idempotent retries.
10. **Mutation-style checks** — mutation testing, or manual "would this test fail
    if the operator/branch/guard were wrong?" reasoning to catch tests that
    execute code without asserting behavior.
11. **Formal / spec methods** — schemas, contracts, type-level constraints, model
    checking, proof obligations, or protocol specs when the domain supports them.

**Fit matrix** — select tactics by changed-code shape:

- **Pure transformation / validation** — parameter table, property tests,
  metamorphic relations, differential comparison to previous behavior.
- **Parser / serializer / file or wire format** — round-trip properties,
  malformed-input corpus, fuzzing, golden compatibility cases.
- **Authorization / security gate** — positive and negative permission matrix,
  confused-deputy cases, input validation, tenant/user boundary tests.
- **DB migration / data backfill** — up/down or forward-only proof, seeded legacy
  fixtures, idempotence, partial-run resume, rollback/restore story, performance
  on representative volume.
- **Queue / retry / job worker** — duplicate delivery, out-of-order delivery,
  timeout, cancellation, poison message, idempotence, observability.
- **Public API / schema / SDK** — compatibility tests, old clients, optional vs
  required fields, version negotiation, error-shape stability.
- **State machine / workflow** — transition table, impossible transitions,
  replay, concurrent actors, recovery after interruption.
- **Search / ranking / ML / LLM / heuristic output** — metamorphic relations,
  curated eval set, regression snapshots with tolerance, adversarial examples,
  provenance/grounding checks.
- **Performance-sensitive path** — representative workload, asymptotic traps,
  allocation/query-count regression, timeout budgets, cache correctness.

**Verification steps:**

1. **Classify the change.** Name the main changed-code shapes from the fit matrix
   and the highest-risk assumptions.
2. **Find the oracle.** Identify how a test would know it failed: exact output,
   invariant, relation, old-vs-new comparison, crash/sanitizer, schema, event,
   persisted state, metric, or human-approved golden case.
3. **Check existing coverage.** Read nearby tests and CI config. Flag tests that
   execute the code but assert the wrong thing or miss the risky branch.
4. **Run only useful safe checks.** Prefer focused existing tests. If a check is
   expensive, flaky, destructive, or environment-dependent, say so and propose it
   instead of running it.
5. **Design the smallest high-signal additions.** For each real gap, propose a
   compact test shape: setup, tabled/generated inputs, oracle, and why it catches
   the risk.
6. **Score gaps.** Missing verification is `major` when the untested risk can
   cause a production bug or security/data incident; `minor` when bounded;
   `question` when the risk is plausible but the needed guarantee is unclear.
7. **Separate now vs later.** Mark quick tests for this PR, heavier harnesses as
   follow-up, research-only ideas as non-blocking unless risk justifies it.

Record only high-value gaps as findings; fold the rest into the round summary.

### 7. Consult (propose-only, optional)

Session-history and consultant tooling is a **capability, not a specific tool**.
If a consultant CLI exists locally (e.g. `gemini`, `codex`, `claude` — prefer a
different model family from your own; non-binding examples, degrade gracefully if
none is present), send it the diff plus this round's lens and the open questions,
under the same verbatim guard as kickoff: no file modification, proposals as
text-only unified diffs, uncertainties flagged as questions. When the lens is
verification, ask specifically for **test ideas with oracles**, not just "more
tests." Merge results with `source: <model>-r<R+1>`, de-duped and verified.

Good LLM uses: propose parameter axes and boundary cases; suggest invariants and
metamorphic relations; generate candidate fixtures from a spec; identify old/new
paths for differential comparison; explain why an existing test may be vacuous.
Bad uses to reject: accepting generated assertions without checking the oracle;
large brittle snapshots as "proof"; inventing guarantees not in code/docs;
replacing fuzz/property tools with one-off random examples; treating green
generated tests as evidence when they only mirror the code.

### 8. Append, don't rewrite

Add only NEW findings (or state changes to existing ones) to `findings.md`,
tagged `round: R+1`. Never renumber existing findings. Bump `rounds` in
`meta.json`.

Prefer a native file-write tool over shell heredocs when appending findings: a
harness's destructive-command guard can false-positive on finding prose that
contains strings like `git restore` or `rm -rf`. If a write is blocked, the path
is still correct — retry via an alternate write mechanism.

## Report

Tell the human:

- How many NEW findings this round, by severity.
- Which lens this round used and which subsystem got the random deep inspection.
- Any findings reconciled (resolved/stale), dropped, or re-anchored after a head
  move.
- The dry-run signal:
  - New findings found → "worth another `squint-deeper`."
  - **Two consecutive rounds with zero new findings → declare the hunt DRY** and
    recommend `squint-walkthrough` to step through and (optionally) post.
