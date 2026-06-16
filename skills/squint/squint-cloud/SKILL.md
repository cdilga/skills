---
name: squint-cloud
description: This skill should be used when the user asks to request, inspect, or harvest GitHub Copilot code-review or cloud-agent findings for a squint PR review.
triggers:
  - squint-cloud
  - run the review in the cloud
  - copilot coding agent review
  - request copilot review
  - harvest the cloud review
---

# squint-cloud

Local bridge for GitHub-hosted review signal. Use it to request native Copilot
review when asked and harvest cloud findings into squint scratch. For repo
onboarding and the GitHub Review button, use `squint-onboard-cloud`.

## Separation rule

GitHub-invoked review artifacts are not `squint-kickoff` shims. They must not
mention `<squint-state>`, `review.md`, `meta.json`, checkout strategy,
`squint-deeper`, `squint-walkthrough`, or "loop until dry". Let GitHub use its
own review/comment/suggestion surfaces; local squint later harvests, dedups,
ranks, and verifies the output.

## Rules

- Local analysis is read-only. The only local writes are squint state files.
- GitHub mutations are explicit actions: show the command/action first and run
  only when requested or approved.
- Cloud review is findings/suggestions by default. If the user asks the cloud
  agent to implement, treat that as a separate coding task and mark it clearly
  during harvest.
- `squint-cloud` never posts the final PR review. Posting stays in
  `squint-walkthrough`.
- Use tracker/CI tooling only if the repo names it and it exists locally.

## Per-PR state (disposable)

Everything for a PR lives under `<squint-state>/<owner>/<repo>/pr-<N>/`:
`review.md`, `meta.json`, optional `checkout/`, optional `logs/`. squint-cloud
writes only `review.md` (adding cloud-sourced entries) and a `cloud` block in
`meta.json`. It does not own the checkout. Per-repo cloud-lane setup notes live
one level up under the squint state dir.

## Mode is intent, not a flag

Infer mode from the request; ask only if genuinely ambiguous. "Request Copilot
review" -> request. "Pull in what the cloud found" -> harvest. "Onboard for the
GitHub Review button" -> use `squint-onboard-cloud`.

---

## Mode: REQUEST PR <N>

Use this mode only when the user asks to request or start GitHub-hosted review.

1. **Native Copilot code review.** If requested, show and run:

   ```bash
   gh pr edit <N> --repo <owner>/<repo> --add-reviewer copilot
   ```

   Skip if a Copilot review already exists on the latest head — check
   `gh api repos/<owner>/<repo>/pulls/<N>/reviews`.

2. **Cloud coding agent review.** Prefer GitHub-invoked entrypoints: automatic
   reviewer rules, GitHub UI, issue/PR assignment, or the org's approved task
   surface. Do not run a local squint prompt "in the cloud". If the user wants a
   local agent to create a GitHub task, show the exact task prompt first and run
   it only after approval.

   Suggested instruction:
   > Review PR <N> for real bugs and omissions. Trace execution flows beyond the
   > diff and return high-signal GitHub review comments or task findings. Use
   > concrete suggestions where they fit. Do not mention squint scratch,
   > `review.md`, `meta.json`, local checkout strategy, or walkthrough. Do not
   > push commits or open PRs unless this task explicitly asks for implementation.

3. **Don't block waiting** — sessions take minutes to ~an hour. Tell the user
   to come back and run `squint-cloud harvest PR <N>`, or just continue local
   `squint-deeper` rounds meanwhile; the lanes are independent.

Cloud agent is a code-generating surface by design. Prompting it to be
findings-only does not make it structurally read-only. Harvest must check for
commits or PRs it created. If the user asked it to implement, record that
separately from review findings.

---

## Mode: HARVEST PR <N>

1. **Pull everything GitHub produced** since the last harvest:
   - `gh api repos/<owner>/<repo>/pulls/<N>/reviews` and `.../comments` —
     Copilot code review inline findings.
   - `gh pr view <N> --repo <owner>/<repo> --json comments` — the coding agent's findings reply.

2. **Normalize into local findings** at
   `<squint-state>/<owner>/<repo>/pr-<N>/review.md`. Do not expect cloud output
   to use squint's schema; adapt GitHub comments, suggestions, and task replies.
   Tag each item `source: copilot-cloud` (coding agent) or `source:
   copilot-review` (native reviewer):
   ```markdown
   ## F<id> - [<severity>] <one-line title>
   - anchor: src/cache/flush.ts:142 @ a1b2c3d
   - state: open
   - source: copilot-cloud
   - diff: right line 142 | body-only
   - evidence: <quoted excerpt + why it's a problem>
   - proposed fix: <text diff when given>
   - round: cloud
   ```
   **Dedup against existing findings** by anchor + meaning — a cloud item that
   restates an existing finding becomes a one-line "(concurred: copilot-cloud)"
   note on the existing finding, not a new entry. Report new-vs-duplicate
   counts.

3. **Verify before trusting.** For every blocker/major the cloud claims, open
   the cited code yourself and confirm it. Downgrade to `question` anything you
   cannot confirm. Cloud findings are leads, not verdicts.

4. **Flag unexpected mutations.** If the coding agent pushed commits, opened a
   PR, or changed a branch when the request was review-only, surface it
   prominently. Check task/session metadata, PR commits, and bot-authored
   branches where available. Note it in `meta.json.cloud`.

5. **Hand off.** Update the `cloud` block in `meta.json` (last harvest sha,
   sources seen, any violation), then: "findings updated — continue with
   `squint-deeper` or go to `squint-walkthrough` to step through and post."

---

## Exit

After harvest, continue with `squint-deeper` for another local pass or
`squint-walkthrough` for triage and posting.
