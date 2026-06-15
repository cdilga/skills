# squint state and anchors

Use this reference when a squint skill needs exact scratch layout, `meta.json`
fields, or GitHub review anchor rules.

## Scratch root

Keep review scratch outside the target repository by default. Choose the first
available root:

1. `$SQUINT_HOME`
2. `$XDG_STATE_HOME/squint`
3. `~/.local/state/squint`
4. existing legacy `~/.squint` if it already contains this PR

Per-PR state:

```text
<squint-state>/<owner>/<repo>/pr-<N>/
  review.md           # human-facing scratch, light IDs, editable
  meta.json           # machine state, schema below
  draft-review.json   # only created by walkthrough before posting
  logs/               # optional local validation logs
  checkout/           # optional, only when squint created a worktree/scratch clone
```

Never write review scratch into the target repo unless the human explicitly asks
for a committed onboarding artifact.

## `meta.json` schema

Keep this small and forgiving. Missing optional fields are not fatal.

```json
{
  "schema": "squint.review.v1",
  "owner": "org",
  "repo": "repo",
  "pr": 123,
  "url": "https://github.com/org/repo/pull/123",
  "base_ref": "main",
  "base_remote": "origin",
  "base_sha": "abc123",
  "head_sha": "def456",
  "merge_base_sha": "789abc",
  "behind_base": 0,
  "depth": "fast|standard|deep|adversarial",
  "checkout": {
    "strategy": "current-folder|existing-clone|worktree|scratch-clone",
    "path": "/absolute/path",
    "created_by_squint": false
  },
  "rounds": [
    {
      "n": 1,
      "skill": "squint-kickoff",
      "lens": "standard",
      "new_findings": 2,
      "ran_local_validation": false
    }
  ],
  "lenses_spent": [],
  "dry_streak": 0,
  "next_finding_id": 1,
  "status": "in-review|posted|abandoned",
  "cloud": {}
}
```

## Review scratch format

Prefer a readable `review.md` over a heavy tracker. IDs help walkthrough but do
not need to become bureaucracy:

```markdown
## F3 - [major] Cache invalidation misses deleted users
- anchor: src/cache/users.ts:142 @ def456
- state: open
- source: local-r1
- diff: right line 142
- evidence: short quote plus why it matters
- proposed fix: concrete text or a small diff when useful
```

Use `state: open | accepted | dropped | resolved | stale`.

## GitHub inline anchors

Only post inline comments where GitHub can anchor them to the PR diff. At finding
creation time, record whether the anchor is in the diff:

- `diff: right line <n>` for a changed/new line.
- `diff: left line <n>` for a removed line.
- `diff: range right <start>-<end>` for a multiline range.
- `diff: body-only` when the issue is real but not anchorable in the PR diff.

`squint-walkthrough` folds `body-only` findings into the review body instead of
trying to force an invalid inline comment.
