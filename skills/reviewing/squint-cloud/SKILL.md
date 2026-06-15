---
name: squint-cloud
description: Explicitly gated cloud lane for PR reviews on GitHub Copilot — native Copilot code review plus optional propose-only cloud-agent sessions — normalizing cloud findings back into outside-repo squint review scratch so the human verdict still happens locally via squint-walkthrough. Three modes: setup / review PR N / harvest PR N. Read-only locally; cloud agents are treated as expensive and not structurally read-only; never posts the human's review.
triggers:
  - squint-cloud
  - run the review in the cloud
  - copilot coding agent review
  - request copilot review
  - set up cloud reviews for this repo
  - harvest the cloud review
---

# squint-cloud — the remotely-hosted lane

Use GitHub's hosted agents as extra reviewers feeding YOUR findings. This is an
explicit escalation path, not a default part of every review. They are
PROPOSE-ONLY: they hand you leads, never verdicts, and never code changes you
keep. Two cloud surfaces, different jobs:

- **Copilot code review** — the native PR reviewer. Fast first pass, inline
  comments, comment-only by design (it can never approve/block — that
  authority stays with the human).
- **Copilot coding agent** — ephemeral Actions-hosted sessions. Its design
  center is *making* changes, so for reviewing it must be explicitly
  instructed to be propose-only. Sessions are capped (~1 hour) and need the
  org to have enabled the agent.

## House rules (non-negotiable, here and in everything you delegate)

1. **Read-only on the local repo.** No file edits, no `git commit/push/reset`,
   no `gh` mutation while analyzing. The only local writes are under
   the squint state dir. The exceptions are the deliberate cloud requests in
   *setup* and *review* below, each shown before it runs.
2. **Cloud agents are PROPOSE-ONLY.** Every instruction you send a hosted agent
   states verbatim that it must not push commits or modify files — only reply
   with findings. If it does anyway, *harvest* flags it loudly (step 4).
3. **squint-cloud never posts the human's review.** It requests cloud passes
   and pulls findings home; the verdict is posted only by `squint-walkthrough`,
   only on explicit human approval.
4. **Tracker/CI tooling only if the repo names it AND it exists locally.** Don't
   assume any tool; the repo's instructions are the source of truth.

## Per-PR state (disposable)

Everything for a PR lives under `<squint-state>/<owner>/<repo>/pr-<N>/`:
`review.md`, `meta.json`, optional `checkout/`, optional `logs/`. squint-cloud
writes only `review.md` (adding cloud-sourced entries) and a `cloud` block in
`meta.json`. It does not own the checkout. Per-repo cloud-lane setup notes live
one level up under the squint state dir.

## Mode is intent, not a flag

Infer which of the three modes the human wants from the request; ask only if
genuinely ambiguous. "Set up cloud reviews" → setup. "Run the cloud review on
PR 42" → review. "Pull in what the cloud found" → harvest.

---

## Mode: SETUP (once per repo)

Propose the checked-in artifacts that make cloud reviewers converge on your
review doctrine, then (if allowed) wire up the native auto-pass. Show every file
before writing it.

1. **Check what the org allows** — don't promise what's disabled.
   `gh api repos/<owner>/<repo>` for access and permissions. Coding-agent
   availability and skills/MCP for code review are org-policy-gated — if
   blocked, name the admin switch needed rather than failing silently. Defer
   actually requesting a reviewer to the *review* mode.

2. **Propose GitHub-specific artifacts as one PR** (show every file before creating
   it; the human approves; you do not push it yourself unless they ask). Cloud
   reviewers read instruction/skill files from the **base branch**, so these
   take effect only after the PR merges — say so.
   - For GitHub.com Copilot code review, use a review-focused skill under
     `.github/skills/code-review/SKILL.md`. The body is a distilled
     `squint-kickoff`: severity
     taxonomy (blocker/major/minor/nit/question), the `file:line @ sha`
     evidence-anchor rule, the omissions checklist, and "propose fixes, never
     push fixes while reviewing."
   - For Copilot CLI / OpenCode, project-specific shims may live under
     `.agents/skills/<project>-squint-*/SKILL.md`. Do not rely on `.agents/skills`
     alone for GitHub.com code review.
   - A **custom deep-reviewer agent profile** at
     `.github/agents/deep-reviewer.agent.md`, with the platform's required YAML
     frontmatter (`description`, and restrictive `tools` where supported) plus a
     propose-only prompt:
     > You are a PROPOSE-ONLY deep reviewer. Trace execution flows beyond the
     > diff, hunt omissions (tests, migrations, callers, failure modes), then a
     > fresh-eyes pass. Reply with findings — each as severity, file:line,
     > evidence, and a proposed fix written as a text diff. Do NOT push commits,
     > do NOT modify files, do NOT open PRs.
   - Optionally `.github/workflows/copilot-setup-steps.yml` if the agent needs
     deps preinstalled to run the repo's tests.
   - Keep critical rules in **root `AGENTS.md`** (nested AGENTS.md isn't
     reliably portable across surfaces); if `.github/copilot-instructions.md`
     exists, keep it a one-line "See AGENTS.md." pointer, not a duplicate.

3. **Auto-first-pass (optional, needs repo admin):** suggest the repository
   ruleset that auto-requests Copilot code review on new PRs, so every PR
   arrives pre-annotated before the human opens it. Propose only — the human
   flips the admin switch.

4. **Record** what was set up and what the org blocked in
   `<squint-state>/<owner>/<repo>/repo-notes.md` under `## cloud lane`.

---

## Mode: REVIEW PR <N>

Before doing anything, confirm the intended cloud depth unless the user's request
already makes it explicit:

- **native only** — request GitHub Copilot code review. Cheapest cloud option.
- **deep cloud** — start a Copilot cloud-agent task/session. More expensive and
  less structurally read-only; use only when asked or clearly warranted.

1. **Native pass.** Request Copilot code review:
   ```bash
   gh pr edit <N> --repo <owner>/<repo> --add-reviewer copilot
   ```
   Skip if a Copilot review already exists on the latest head — check
   `gh api repos/<owner>/<repo>/pulls/<N>/reviews`.

2. **Deep pass (coding agent), propose-only and explicitly gated.** Prefer the
   current first-party task surfaces instead of PR-comment folklore:
   - If `gh agent-task create` is available (`gh` v2.80+), use it only after the
     human approves the exact prompt. Check `gh agent-task create --help` for the
     current flags.
   - If using the Agent Tasks API, set `create_pull_request: false` when the API
     supports it and record the task id in `meta.json`.
   - Otherwise use the github.com Agents panel and tell the human the exact click
     path.

   The instruction invokes the deep-reviewer doctrine explicitly:
   > Act as the deep-reviewer agent for PR <N>. Review PROPOSE-ONLY: do NOT push
   > commits, do NOT change files, do NOT open PRs. Trace the changed code's
   > execution flows beyond the diff, hunt for bugs and omissions (tests,
   > migrations, callers, failure modes), then re-check with fresh eyes. Reply
   > with a findings list: severity, file:line, evidence, and proposed fix as
   > text. <plus any steering from the human>

3. **Don't block waiting** — sessions take minutes to ~an hour. Tell the human
   to come back and run `squint-cloud harvest PR <N>`, or just continue local
   `squint-deeper` rounds meanwhile; the lanes are independent.

Cloud agent is a code-generating surface by design. Prompting it to be
propose-only reduces risk but does not make it structurally read-only. Harvest
must therefore check for commits or PRs it created.

---

## Mode: HARVEST PR <N>

1. **Pull everything the cloud produced** since the last harvest:
   - `gh api repos/<owner>/<repo>/pulls/<N>/reviews` and `.../comments` —
     Copilot code review inline findings.
   - `gh pr view <N> --repo <owner>/<repo> --json comments` — the coding agent's findings reply.

2. **Normalize into the local findings** at
   `<squint-state>/<owner>/<repo>/pr-<N>/review.md`, using the same entry format as
   the rest of the suite, tagged `source: copilot-cloud` (coding agent) or
   `source: copilot-review` (native reviewer):
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
   restates one you already have becomes a one-line "(concurred: copilot-cloud)"
   note on the existing finding, not a new entry. Report new-vs-duplicate
   counts.

3. **Verify before trusting.** For every blocker/major the cloud claims, open
   the cited code yourself and confirm it. Downgrade to `question` anything you
   cannot confirm. Cloud findings are leads, not verdicts.

4. **Flag propose-only violations loudly.** If the coding agent pushed commits,
   opened a PR, or changed a branch despite the instruction, surface it
   prominently. Check task/session metadata, PR commits, and bot-authored
   branches where available. Note the violation in `meta.json.cloud`.

5. **Hand off.** Update the `cloud` block in `meta.json` (last harvest sha,
   sources seen, any violation), then: "findings updated — continue with
   `squint-deeper` or go to `squint-walkthrough` to step through and post."

---

## Cost & expectations (be upfront)

Each cloud run consumes the org's Copilot usage budget (AI-credits / Actions
metering) — fan out deliberately, not by default. The native reviewer is fast
and cheap; coding-agent deep passes are for PRs that earn them. And neither can
ever approve or request changes — that is, structurally, the human's job via
`squint-walkthrough`, which is the whole point of this suite.
