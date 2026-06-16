---
name: squint-panel
description: This skill should be used when the user explicitly asks for adversarial, multi-model, panel, second-opinion, or high-stakes review of an in-progress squint PR.
triggers:
  - squint-panel
  - run an adversarial panel on this PR
  - get a multi-model review
  - have gemini gpt and opus review this
  - deep adversarial review
  - second and third opinions on these findings
  - convene the review panel
---

# squint-panel — adversarial multi-model review

An **optional, expensive escalation** of the single second-model consult in
`squint-kickoff` / `squint-deeper`. Where that consult asks one other model for
test ideas, this convenes a **panel of different models**, gives each a distinct
adversarial lens, then has them **cross-examine each other's findings** before any
survive into the scratch. Use it when the user explicitly asks for
adversarial/multi-agent review, or when a PR is high-stakes enough to justify
asking first. Skip it otherwise. The reviewer verdict still happens in
`squint-walkthrough`.

This is not on the critical path: `kickoff → deeper → walkthrough` works without it.
Run it after at least one `squint-kickoff` round, when you want depth.

## House rules (non-negotiable, here and in everything you delegate)

- **Every panelist is READ-ONLY on the repo and PROPOSE-ONLY.** No file edits, no
  commits, no pushes, no `gh` mutations. They return findings as text — nothing else.
- **Only `squint-walkthrough` posts.** This skill writes only outside the repo
  under the squint state dir.
- **Tool-agnostic.** Use whatever your harness gives you to run a subagent on a
  specific model; if it can't pin models, invoke the model's own CLI. Never assume a
  specific provider is present — check first and degrade gracefully.
- **Verify, don't trust.** A panelist's claim is a lead, not a fact, until its
  evidence is checked against the code.

## 0. Locate the review

Find the in-progress scratch: the most recent `<squint-state>/<owner>/<repo>/pr-<N>/` with
`meta.json` `status: in-review` (or the PR the user names). You need its checkout,
its `review.md` (existing findings the panel will both extend and stress-test), and
`meta.json` (`head_sha`, `base`, `behind_base`). If none exists, run `squint-kickoff`
first.

## 1. Assemble the roster

**Defaults (overridable):**

| Slot | Model | How to invoke (if no harness model-pin) | Default lens |
|---|---|---|---|
| A | Gemini (latest Pro) | `gemini` CLI | correctness, concurrency, data races, state machines |
| B | latest OpenAI high-effort | `codex` / OpenAI CLI | security, API contracts, input validation, auth |
| C | Opus (latest) | `claude` CLI | failure modes, omissions, error handling, rollback |

**Stay current, don't pin.** Each slot defaults to the **latest, most capable model in
its family at high reasoning effort**, resolved by the CLI/harness — *not* a fixed
version string — so the panel rides new model releases automatically. Pin a specific
version only when you need reproducibility; `squint-onboard` can bake a fixed (or
entirely different) roster into a project's squint shim or review docs when a repo
wants determinism. **Before falling back to these generic defaults, check for a
project-specific squint shim or repo review docs** for this PR's repo (exact models,
per-project overrides, effort, lens-to-model map) and prefer it when present.

The human can **override** the roster at invocation — swap models ("use grok and
deepseek too"), drop one, add a fourth, or reassign lenses. Honour it. Before
launching, confirm each chosen model is reachable (`which gemini codex claude`, or your
harness's model list); **report and skip any model that isn't available** rather than
silently dropping coverage. Prefer assigning each model a lens *different* from the
family you (the orchestrator) are running as, so the panel adds diversity rather than
echoing you.

## 2. Brief each panelist and launch (independent round)

For each model in the roster, launch one reviewer. **Pin it to that model** via your
harness if you can; otherwise invoke its CLI non-interactively with the checkout as
`cwd`. Into each reviewer's context inject, in this order:

1. **The shared reviewer brief** — `reviewer-brief.md` (sits next to this file). It is
   self-contained: a panelist has none of the squint suite, so the brief carries the
   doctrine, the propose-only rule, the severity taxonomy, and the exact finding format.
2. **Its role** — one paragraph: "You are the **<lens>** adversary. Hunt hardest in
   <lens>. Be adversarial: surface what a tired reviewer would miss. Assume the diff is
   guilty until proven innocent."
3. **The PR context** — checkout path, the diff command
   `git diff <base-remote>/<base>...HEAD`, `head_sha`, and the `behind_base` count (flag loudly
   if large — a stale branch is a top source of regressions).

Each reviewer returns findings **only** in the brief's format (`F<id>` / severity /
anchor `file:line @ sha` / evidence quote + why / proposed fix). Collect them per model.

## 3. Cross-examination (the adversarial core)

Now make the models argue. Give every panelist the **union** of all panelists'
findings (including the existing `review.md`) and two jobs:

- **Refute** — for each finding it did not author, try hard to show it is wrong,
  already handled, or not actually a problem. Default to "refuted" when the evidence is
  thin.
- **Reinforce / extend** — strengthen findings it believes, and add anything the first
  round missed now that it has seen the others' angles.

You (the orchestrator) are the judge. A finding **survives** when its evidence holds up
against the code and it is not refuted by a majority of the *other* panelists. Tag each
survivor with a confidence (`panel-consensus` if multiple models converged,
`panel-single` if only one stands by it after cross-exam). Drop the refuted ones, noting
why in case the user wants them back.

## 4. Fold survivors into the scratch

Append surviving findings to `<squint-state>/<owner>/<repo>/pr-<N>/review.md`, each tagged
`source: panel:<model>` (or `panel:consensus`), deduped against existing findings
(merge, don't duplicate — if the panel confirms an existing finding, raise its
confidence rather than adding a second entry). Bump `meta.json` `rounds`. Prefer a
native file-write tool over shell heredocs; destructive-command guards can
false-positive on finding prose containing strings like "git restore" / "rm -rf" — if a
write is blocked the path is still correct, retry via an alternate write mechanism.

## 5. Report and hand off

Report: which models actually ran (and any that were unavailable), the lens each took,
how many findings each proposed, how many survived cross-examination, and the consensus
blockers/majors. Then hand off to `squint-walkthrough` for the reviewer verdict — the panel
never posts.

## Overriding defaults

- **Roster:** name the models you want; they replace the defaults. Lenses follow the
  table unless you reassign them.
- **Skip cross-examination:** for a quick multi-model pass, run §2 only and fold all
  findings as `panel-single`. The cross-exam is what makes it adversarial, so keep it
  when depth is the goal.
- **More than three:** add slots; assign each a lens from `squint-deeper`'s rotation
  (concurrency, security, API contracts, tests/omissions, failure modes, performance,
  verification) so coverage stays diverse rather than redundant.
