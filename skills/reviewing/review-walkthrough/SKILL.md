---
name: review-walkthrough
description: Step through the findings ledger of a reviewed PR one finding at a time (accept / edit / drop), then render the full review draft and — only on explicit approval — post it to GitHub as one batched review. The only skill in the suite allowed to post.
triggers:
  - review-walkthrough
  - step through the findings
  - walk me through the review
  - post my review
  - draft my review
---

# review-walkthrough — triage, draft, approve, post

This is the ONLY skill in the suite that may post to GitHub, and only at the
very end, only after the human explicitly approves the rendered draft. Until
that moment the same hard rules apply: read-only repo, writes only under
`~/.reviews/`.

## Input

The PR in conversation, or the most recent `~/.reviews/*/*/pr-*/meta.json`
with `status: in-review` (confirm in one line).

## Step 1 — Drift check (fail closed)

`gh pr view <N> --json headRefOid` vs `meta.json`. If the head moved:
**refuse to proceed** and tell the human to run `review-deeper` first (it
reconciles the ledger). A review built on a stale ledger is worse than a late
one.

## Step 2 — Walkthrough, one finding at a time

Order: blocker → major → minor → question → nit. For each finding with
`state: open`, present compactly:

```
F7 [major] Race in cache flush on shutdown      (src/cache/flush.ts:142, round 1, gemini-r1 concurred)
evidence: …
proposed fix: …
→ accept / edit / drop / follow-up?
```

- **accept** → `state: accepted`
- **edit** → take their wording/severity change, then `state: accepted`
- **drop** → `state: dropped` + one-line reason in the ledger
- **follow-up** → `state: follow-up` (worth raising, but not in this review —
  collect these for a closing remark or a separate issue)

Batch the trivial: if there are many nits, offer "accept all nits /
drop all nits / go one by one". Respect the human's pace — if they say
"accept everything except F3", do exactly that.

If `reviewer-voice.md` exists in the repo's notes dir, match its tone and
phrasing when finalizing comment text — the posted words should sound like
the human, not like a bot.

## Step 3 — Render the draft

Build the complete review locally and show ALL of it before anything is sent:

- **Inline comments**: one per accepted finding that has a diff anchor —
  finding text + proposed fix (as a ```suggestion block only when the fix is
  a drop-in replacement for the anchored lines; otherwise as a fenced diff).
- **Review body**: 2–5 line summary in the human's voice — what was reviewed,
  the main themes, appreciation where genuinely due (no boilerplate praise).
- **Verdict proposal** with one-line rationale:
  - any accepted blocker/major → propose `REQUEST_CHANGES`
  - only minors/nits/questions → propose `COMMENT`
  - clean or trivially addressable → propose `APPROVE`
  The human may override; their call is final.

## Step 4 — Explicit approval gate

Ask plainly: **"Post this as <VERDICT>? (yes / change verdict / edit / abort)"**
Do not post on anything less than an unambiguous yes. "Looks good" about the
*draft content* is not approval to *post* — if ambiguous, ask again.

## Step 5 — Post as ONE batched review

Build a JSON payload and post once (single API call = single review, atomic):

```bash
cat > /tmp/review-<N>.json <<'EOF'
{
  "commit_id": "<head_sha from meta.json>",
  "event": "REQUEST_CHANGES",
  "body": "<review body>",
  "comments": [
    {"path": "src/cache/flush.ts", "line": 142, "side": "RIGHT", "body": "<finding text>"}
  ]
}
EOF
gh api "repos/<owner>/<repo>/pulls/<N>/reviews" --method POST --input /tmp/review-<N>.json
```

Notes: `line` is the line in the head revision; use `start_line` +
`start_side` for multi-line comments; comments on files not in the diff are
rejected by GitHub — convert those findings into the review body instead.

On success: record the returned review id and URL in `meta.json`
(`"posted": [{"review_id": …, "verdict": …, "at": …}]`), set accepted
findings to `state: posted`, set `status: posted`, and show the review URL.

On failure: report the exact API error, leave the ledger untouched, and let
the human decide — never retry with a mutated payload silently.

## Step 6 — Loose ends

Offer (don't push): file `follow-up` findings as GitHub issues
(`gh issue create`, each one shown before creation), and append any
recurring-theme lesson to `~/.reviews/<owner>/<repo>/repo-notes.md` so the
next `review-kickoff` starts smarter.
