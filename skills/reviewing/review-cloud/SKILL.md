---
name: review-cloud
description: Set up, run, and harvest PR reviews on GitHub's remotely-hosted Copilot agents — native Copilot code review plus propose-only deep-review sessions on the cloud coding agent — pulling all findings back into the local ledger so the human verdict still happens locally via review-walkthrough.
triggers:
  - review-cloud
  - run the review in the cloud
  - copilot coding agent review
  - set up cloud reviews for this repo
  - harvest the cloud review
---

# review-cloud — the remotely-hosted lane

Use GitHub's hosted agents as extra reviewers feeding YOUR ledger. Two cloud
surfaces, different jobs:

- **Copilot code review** — the native PR reviewer. Fast first pass, inline
  comments, comment-only by design (it can never approve/block — that
  authority stays with the human).
- **Copilot coding agent** — ephemeral Actions-hosted sessions. Its design
  center is *making* changes, so for reviewing it must be explicitly
  instructed to be propose-only. Sessions are capped (~1 hour) and need the
  org to have enabled the agent.

House rule unchanged: cloud output lands in the local ledger tagged by source;
posting the human's review happens only via `review-walkthrough`.

## Subcommand: setup (once per repo)

1. **Check what the org allows** — don't promise what's disabled:
   `gh api repos/<owner>/<repo>` for access; try
   `gh pr edit <any-open-pr> --add-reviewer copilot` only when actually
   requesting (step below); note that coding-agent availability and
   skills/MCP for code review are org-policy-gated — if blocked, say which
   admin switch is needed rather than failing silently.
2. **Shared doctrine** (so the cloud reviewers converge on your taxonomy) —
   propose a PR (show every file before creating it; the human approves) adding:
   - `.github/skills/pr-review-doctrine/SKILL.md` — a condensed
     `review-kickoff`: severity taxonomy, evidence-anchor rule, omissions
     checklist, "propose fixes, never push fixes while reviewing".
   - `.github/agents/deep-reviewer.md` — a custom agent for the coding agent:
     "You are a propose-only deep reviewer. Trace execution flows beyond the
     diff, hunt omissions, then a fresh-eyes pass. Reply with findings
     (severity, file:line, evidence, proposed fix as a text diff). Do NOT
     push commits or modify files."
   - optionally `copilot-setup-steps.yml` if the repo needs deps preinstalled
     for the agent to run tests.
   - Remember: instruction/skill files are read from the **base branch** —
     they take effect only after this PR merges.
3. **Auto-first-pass (optional, needs repo admin):** suggest the repository
   ruleset that auto-requests Copilot code review on new PRs, so every PR
   arrives pre-annotated before the human ever opens it.
4. Record what was set up (and what the org blocked) in
   `~/.reviews/<owner>/<repo>/repo-notes.md` under `## cloud lane`.

## Subcommand: review PR <N>

1. **Native pass:** `gh pr edit <N> --add-reviewer copilot` (skip if a
   Copilot review already exists on the latest head — check
   `gh api repos/<owner>/<repo>/pulls/<N>/reviews`).
2. **Deep pass (coding agent), propose-only:** post one PR comment mentioning
   the agent — `gh pr comment <N> --body "@copilot <instruction>"` — where the
   instruction invokes the deep-reviewer doctrine explicitly, e.g.:
   > @copilot Act as the deep-reviewer agent. Review this PR propose-only: do
   > NOT push commits or change files. Trace the changed code's execution
   > flows beyond the diff, hunt for bugs and omissions (tests, migrations,
   > callers, failure modes), then re-check with fresh eyes. Reply with a
   > findings list: severity, file:line, evidence, and a proposed fix as a
   > text diff. <plus any steering from the human>
   Note: the mention only works if the human has write access and the agent
   is enabled; otherwise fall back to starting the session from the agents
   panel on github.com (tell the human the exact click path).
3. Don't block waiting — sessions take minutes. Tell the human to come back
   and run `review-cloud harvest PR <N>` (or just continue local rounds
   meanwhile; the lanes are independent).

## Subcommand: harvest PR <N>

1. Pull everything the cloud produced since last harvest:
   - `gh api repos/<owner>/<repo>/pulls/<N>/reviews` + `/comments` — Copilot
     code review inline findings.
   - `gh pr view <N> --json comments` — the coding agent's findings reply.
2. Normalize each item into the ledger
   (`~/.reviews/<owner>/<repo>/pr-<N>/findings.md`) using the standard entry
   format, `source: copilot-cloud` or `source: copilot-review`, de-duplicated
   against existing findings by anchor + meaning.
3. **Verify before trusting:** for each blocker/major the cloud claims, check
   the cited code yourself; downgrade to `question` anything you cannot
   confirm. Cloud findings are leads, not verdicts.
4. If the coding agent pushed commits despite instructions (it can happen),
   flag that loudly — the human may want those commits reverted by the author,
   and the findings re-derived from the diff as it was reviewed.
5. Report new-vs-duplicate counts and hand off: "ledger updated — continue
   with `review-deeper` or go to `review-walkthrough`."

## Cost & expectations (be upfront)

Each cloud run consumes the org's Copilot usage budget (AI-credits/Actions
style metering) — fan out deliberately, not by default. The native reviewer
is fast and cheap; coding-agent deep passes are for PRs that earn them. And
neither can ever approve or request changes — that is, structurally, the
human's job, which is the whole point of this suite.
