---
name: squint-walkthrough
description: Walk through accumulated squint findings one at a time (accept/edit/drop), render the full draft, and post one batched GitHub PR review only after explicit approval. Use to finalize and post a squint review.
triggers:
  - squint-walkthrough
  - step through the findings
  - walk me through the review
  - post my review
  - draft my review
  - finalize the review
---

# squint-walkthrough — triage, draft, approve, post

This is the **ONLY** skill in the squint suite that may post to GitHub, and only
at the very end, only after the user explicitly approves the rendered draft.
Until that moment the same hard rules as every other squint skill apply:
**read-only on the repo, writes only outside the repo under the squint state
dir.** This skill never
edits repo code. Tracker/CI tooling is used only if the repo names it AND it
exists locally.

## Input

The PR in conversation, or the most recent
`<squint-state>/<owner>/<repo>/pr-<N>/meta.json` with `status: in-review`
(confirm in one line). State lives outside the repo: `review.md`, `meta.json`,
optional `checkout/`, optional `logs/`. Load `references/state-and-anchors.md`
if you need exact schema or anchor rules.

## Step 1 — Drift check (fail closed)

Compare `meta.json` `head_sha` to the live PR head:

```bash
gh pr view <N> --repo <owner>/<repo> --json headRefOid -q .headRefOid
```

If it differs from `head_sha`: **refuse to post.** Tell the user plainly that
the PR has moved since the findings were written and that they must run a
`squint-deeper` reconciliation round first — it re-anchors every open finding to
the new head — then come back. A review built on a stale tree is worse than a
late one. Do not proceed, do not post, do not "best-effort" re-anchor here;
re-anchoring is squint-deeper's job.

If the head matches, continue.

## Step 2 — Walkthrough, one finding at a time

Order: **blocker → major → minor → question → nit.** For each open finding,
present it compactly and ask for a decision:

```
F7 [major] Race in cache flush on shutdown      (src/cache/flush.ts:142, round 1, gemini-r1 concurred)
evidence: …
proposed fix: …
→ accept / edit / drop?
```

- **accept** → keep as-is, mark accepted.
- **edit** → take the user's wording or severity change, then mark accepted.
- **drop** → mark dropped with a one-line reason in `review.md`.

Batch the trivial: if there are many nits, offer "accept all nits / drop all
nits / go one by one". Respect the user's pace — if they say "accept everything
except F3", do exactly that.

If the user wants the findings in front of them, show the state path and offer
to open `review.md` in their editor. Do not require an editor workflow.

Match the reviewer's voice when finalizing comment text — the posted words
should sound like the reviewer, not like a bot. Mine that voice from how they
phrase things in this session and, if available, from their prior posted GitHub
reviews; never invent boilerplate praise.

## Step 3 — Render the FULL draft locally

Build the complete review **locally** and show ALL of it before anything is
sent. Nothing leaves the machine in this step.

- **Inline comments**: one per accepted finding that has a valid diff anchor —
  finding text + proposed fix, anchored to `file:line` in the head revision.
  Render the fix as a ```suggestion block only when it's a drop-in replacement
  for the anchored lines; otherwise as a fenced diff. Findings marked
  `diff: body-only` or on files not in the PR diff must go in the review body.
- **Review body**: a short summary in the reviewer's voice — what was reviewed, the
  main themes, genuine appreciation where due (no filler).
- **Overall verdict** with a one-line rationale:
  - any accepted blocker/major → propose **REQUEST_CHANGES**
  - only minors / nits / questions → propose **COMMENT**
  - clean or trivially addressable → propose **APPROVE**

  The human may override; their call is final.

## Step 4 — Explicit approval gate

Ask plainly:

> **Post this as <VERDICT>? (yes / change verdict / edit / abort)**

Do not post on anything less than an unambiguous **"post it"** / yes. Praise of
the *draft content* ("looks good", "nice") is NOT approval to *post* — if
there's any ambiguity, ask again. No approval, no API call.

## Step 5 — Post as ONE batched review (single call)

Build one JSON payload in the squint state dir and post it in a **single**
`gh api` call — one call = one atomic review, never a comment-per-call drip.
Prefer a native JSON writer/tool over shell heredocs so multiline code blocks,
quotes, and suggestions are escaped correctly.

```bash
gh api "repos/<owner>/<repo>/pulls/<N>/reviews" \
  --method POST --input <squint-state>/<owner>/<repo>/pr-<N>/draft-review.json
```

Notes: `line` is the line in the head revision; use `start_line` + `start_side`
for multi-line comments. GitHub rejects comments on files not in the diff —
those must live in the body (Step 3 already folded them in).

**On failure:** report the exact API error, leave `meta.json` and `review.md`
untouched, and let the user decide. Never silently retry with a mutated
payload.

## Step 6 — Record the post

On success, update `meta.json`: set `status: posted` and record the returned
review id (and URL). Show the review URL to the user.

## Step 7 — Offer to tear down the scratch

GitHub is now the record — the per-PR scratch under the squint state dir is disposable
and nothing should accumulate. **Offer** (don't force) to remove it:

```bash
rm -rf <squint-state>/<owner>/<repo>/pr-<N>/
```

If the user wants to keep it (e.g. follow-up findings still to file as issues),
leave it. But the default suggestion after a clean post is to tear it down, so
no stale state lingers.
