---
name: squint-onboard
description: "Manual onboarding for a repo's PR-review experience. Mine source history, design docs, prior agent/session history, architecture, PRs/issues, and review culture, then propose lightweight repo artifacts: lean AGENTS.md/docs, project-scoped <project>-squint-* shims, and GitHub-specific code-review/cloud-agent files only when requested. Read-only by default; propose before writing; keep team rollout low-friction. Re-run by hand when a repo drifts."
triggers:
  - squint-onboard
  - onboard this repo for review
  - set up review context for this repo
  - author or improve this repo's AGENTS.md
  - make this repo agent-ready
  - generate project review skills for this repo
  - deeply study this codebase before reviewing
  - first time reviewing in this repo
---

# squint-onboard — one study, lightweight repo artifacts

This is the heavyweight, manual member of the `squint` suite. You run it by hand
when *you* judge a repo is worth a deep, token-expensive study — and you re-run it
by hand when the repo has drifted. There is no cron, no sweep, no queue: **you are
the scheduler.**

The useful part is mining the repo's history, prior agent sessions, design
intent, architecture, and review culture. From that study, propose only the
artifacts that are worth the repo churn:

- **(a) Repo-readiness** — author or improve the root `AGENTS.md`, decompose depth
  into focused `docs/` files, and optionally add project-scoped skills.
  Generic; helps *every* agent that works in the repo, not just reviewers.
- **(b) Review-tailoring** — generate thin `<project>-squint-*` review shims so
  the generic `squint-kickoff` -> `squint-deeper` -> `squint-walkthrough` loop
  runs with this repo's preferred depth, checkout strategy, validation commands,
  and review context.

Default to the least invasive useful output. Do not turn a first onboarding into
a large standards PR unless the human wants that.

## Mode is judgment, not a flag

There is no hardcoded toggle. Infer intent from the request and the context:

- "author this repo's AGENTS.md" / "make this repo agent-ready" → leans (a).
- "set up review skills" / "generate the squint shims" -> leans (b).
- "onboard this repo" / "deeply study this before reviewing" / anything vague ->
  run the study and propose a small recommended set.

Ask the human to disambiguate only when it changes what you would write. Otherwise
produce a recommendation and wait for approval before writing.

Whatever you produce, the study should be sufficient to support the artifact you
recommend. Do not over-mine sources that are irrelevant to the requested outcome.

## Hard rules (non-negotiable)

1. **Read-only by default.** Discovery never edits the repo, tickets, docs, PRs, or
   issues. The *only* writes are the artifacts in Parts II/III — and each of those is
   **proposed and shown before it is written**, then written only on explicit human
   approval. You may run safe local builds/tests/linters when useful and allowed, and
   read-only `gh` queries; never `gh pr review` / `gh pr comment` / `gh pr edit` or any
   mutation.
2. **Propose, don't impose.** Every file you would create or change in the repo is
   shown to the human first — exact path, why it belongs, a concise draft, and what you
   deliberately left out. Proceed only on a yes.
3. **Summarize, don't dump.** Never copy raw ticket exports, chat logs, wiki pages,
   session transcripts, PR threads, or incident reports into committed files. Distill
   *durable* guidance and keep provenance links/identifiers instead.
4. **Protect sensitive material.** Redact secrets, customer data, credentials,
   incident-only detail, and private person-specific commentary. If unsure, keep it out
   of repo-committed output (working notes are fine).
5. **Degrade gracefully.** If a source or tool is missing, note it and continue. No
   single unavailable source fails the onboarding.

## Input

A project identifier — current repo, a GitHub URL, `owner/repo`, or a bare project name
— plus whatever steering the human gives ("focus on the payments migration path", "use
the ticketing and docs history if it's reachable", "this is a monorepo, the join-form
app lives under `apps/join`"). Honor steering as emphasis, not as license to skip the
structured pass.

If the project is genuinely ambiguous (which repo? which path in a monorepo?), ask one
concise clarifying question. Otherwise proceed.

**Project slug resolution.** Before generating any `<project>-squint-*` artifacts,
choose a short lowercase-hyphen project slug from the repo name or monorepo app
path. Ask only if the slug would be ambiguous.

---

# PART I — the repo study

Scope the study to the requested outcome. Use subagents only when available and
worth the cost; otherwise do a narrower serial pass. You are not just
cataloguing the repo, you are hunting for the bug classes and invariants that
future reviews must defend.

## Phase 0 — Identity, access, source inventory

```bash
gh auth status
gh api user --jq .login                                   # YOUR login — for history mining
gh api repos/<owner>/<repo> --jq '{permissions, default_branch, archived}'
```

Record your permission level (can you approve / request changes?) and whether you
appear in `CODEOWNERS` (`.github/CODEOWNERS`, `CODEOWNERS`, `docs/CODEOWNERS`) — note
which paths are yours.

Then inventory every available source **without assuming any vendor or CLI**. For each,
record availability (available | unavailable | not authorized | not relevant), the
generic access method, freshness/trust, and what it's useful for in reviews:

- repository metadata, history, branches, PRs, reviews, issues, labels, releases
- CI/build history, failing checks, flaky tests, deployment notes
- ticketing work items linked from branch names, commits, PRs, or issue text — only if
  a matching CLI/connector actually exists on this machine (`which …`); never invent one
- documentation: architecture docs, ADRs, runbooks, onboarding docs, incident/postmortem
  indexes, release-process pages
- local repo instruction files: `AGENTS.md` (root + nested), `CLAUDE.md`,
  `.github/copilot-instructions.md`, `.github/instructions/*`, `CONTRIBUTING.md`,
  `README.md`, ownership/template/test docs
- **prior agent/session history** — see Phase 2

## Phase 1 — Repo mechanics (the minute-one facts)

From a local clone (clone into a scratch checkout if there's none, or use a worktree if
the existing clone is dirty — never disturb uncommitted work):

- **Instruction files:** read the ones above and summarize the rules a reviewer must
  hold authors to. Deviations from the repo's own stated conventions are review findings.
- **Build/test/lint:** derive the *exact* commands (from instructions first, else
  `package.json` scripts / `Makefile` / `Cargo.toml` / `pyproject.toml` / CI workflows).
  If the human asked to test locally, or a cheap safe check is clearly high-value,
  load `references/local-validation.md` and run it. If the user asked for static
  analysis/no live testing, do not run runtime checks. Record cost as known,
  estimated, or not run. This block may feed AGENTS.md and project squint shims.
- **Churn / dragons:** where the bodies are buried —
  `git log --since=6.months --name-only --pretty=format: | sort | uniq -c | sort -rn | head -20`.

## Phase 2 — Mine prior agent/session history (tool-agnostic)

Use **whatever capability exists** to *search prior agent/session history for what was
tried, broken, or decided* in these files and subsystems — setup failures, hidden
commands, repeated misunderstandings, abandoned approaches, recurring foot-guns. This is
a **capability call, not a tool mandate.** Examples of how that capability might be
provided, none binding: a session-history search such as `cass`, your harness's own
transcript search, or grepping over local agent logs. Pick whatever is present; if none
is, note the gap and move on. **Never hardcode a specific tool.**

## Phase 3 — Mine the review culture and YOUR reviewer voice (gh)

```bash
gh search prs --repo <owner>/<repo> --reviewed-by @me --state all --limit 50 \
  --json number,title,url
# for a sample (10–20 PRs, most recent first):
gh api "repos/<owner>/<repo>/pulls/<N>/comments" --paginate \
  --jq '.[] | select(.user.login=="<you>") | {path, body}'
gh api "repos/<owner>/<repo>/pulls/<N>/reviews" --paginate \
  --jq '.[] | select(.user.login=="<you>") | {state, body}'
```

Distill: the **recurring themes** you flag (these become standing lenses for
`squint-kickoff`/`squint-deeper`), your **severity habits** (block vs let-slide), 3–5
**verbatim phrasings** (so `squint-walkthrough` drafts in your voice), and your rough
**verdict base rates** (keeps drafted verdicts calibrated to you).

If you've reviewed nothing here yet, mine the repo's culture instead — read the review
threads of the last ~10 merged PRs: what respected reviewers flag, what earns a change
request, what tone is normal. Mark it `inferred-from-repo, not yet personal`.

## Phase 4 — Failure-hunting fan-out

Don't merely map the architecture — **hunt the failure modes.** Use focused
subagents only when available and worth the cost; otherwise inspect the
high-signal slices serially. Return distilled findings (not raw dumps):

- **Architecture & boundaries:** major modules, data flows, ownership hints, the 3–5
  load-bearing files. Where do the dragons live (highest churn + most review contention)?
- **History of pain:** reverted PRs, hotfixes, incident-linked changes, PRs with long
  contentious review threads. Each one is a hint about a fragile invariant.
- **Invariants the code must preserve:** authorization, idempotency, data consistency,
  API/back-compat, privacy, auditability, money/state transitions. State each as a rule
  a reviewer can check.
- **Likely bug classes:** from the above, name the bug *classes* this repo is prone to
  (e.g. "migrations that forget rollback", "broad try/except swallowing errors", "shared
  cache mutated without a lock"). These seed the review lenses.
- **Design intent:** what the design docs / ADRs say the system is *supposed* to
  guarantee, vs what the code currently does. Gaps are review gold.

Keep a **source log** with provenance (source name, stable link/identifier, date,
one-line reason it mattered) so any fact can be re-checked later.

At the end of Part I you should have enough to propose a distilled architecture
map, risk/invariant register, likely bug classes, review culture, reviewer voice,
and build/test/lint block. Keep raw notes out of committed artifacts.

---

# PART II — REPO-READINESS output

Goal: leave the repo so any agent lands better, without turning onboarding into a
large process rewrite. Usually this means a lean root `AGENTS.md` plus a small
review context doc under `docs/`.

**Everything here is proposed and shown before writing (Hard Rule 2).**

## II.A — Author/improve the root AGENTS.md

The thesis: **`AGENTS.md` loads every turn, so it carries only behavior-changing
guardrails. Depth gets pushed into on-demand skills and cited `docs/` files.** Keep it
short and skimmable. Apply these portable principles:

1. **RULE 0 first — the user overrides this document.**
2. **Safety / irreversibility rules before architecture** (no-delete; no `rm -rf` /
   `git reset --hard` without same-message authorization) — they must survive skimming.
3. **Prohibitions as unhedged CAPS imperatives, each with a one-line WHY.** A rule
   without a why gets ignored or lawyered.
4. **Build/test/lint as a copy-paste block under a "(CRITICAL)" heading** — commands
   from Phase 1, clearly marking whether they were run or inferred.
5. **Code editing discipline** — only include rules that match this repo's actual
   workflow. Do not add "no compat shims" or similar broad rules unless the repo
   already wants that norm.
6. **Architecture as a terse Quick Reference**, with depth **cited to `docs/…` paths**,
   never inlined.
7. **Per-tool mini-template** for each real tool: purpose · 3–6 commands · 1–3 gotchas ·
   single entry-point.
8. **"Landing the Plane" completion checklist** at the end.
9. **Solve compaction with a re-read hook, not repetition** — a short note instructing the
   agent to re-read AGENTS.md after a context compaction.
10. **Thin `CLAUDE.md` that delegates** to AGENTS.md (or a `CLAUDE.md → AGENTS.md`
    symlink). One source of truth.

Skeleton (adapt headings to the repo; omit sections with no real content):

```
# AGENTS.md — <project>   > one line: what it is + who this doc is for
## RULE 0 — User overrides this document
## Hard Safety Rules            (no-delete; irreversible-git; each rule + 1 "why")
## Toolchain & Commands         (build/lint/test, copy-paste, "(CRITICAL)")
## Code Editing Discipline      (repo-specific editing rules)
## Architecture — Quick Reference   (terse; deep detail → cite docs/ path)
## Project-Specific Non-Negotiables (3–6 repo-unique constraints, from Part I)
## Per-Tool Reference           (purpose · commands · gotchas · entry-point)
## Landing the Plane            (session-completion checklist)
## (footer) Re-read this file after any context compaction.
```

**Decompose depth into `docs/`.** Anything beyond a Quick Reference — module
deep-dives, data-flow diagrams, invariant register, migration playbooks, review
style — becomes focused docs such as `docs/agents/reviewing.md` or
`docs/architecture/<topic>.md` that AGENTS.md cites by path.

**Do NOT cargo-cult Jeffrey Emanuel's idiosyncrasies.** His real files are the *craft*
model, not a template to copy literally. Specifically reject:
- "main only, never branch / never use worktrees" — that fits his swarm-on-one-repo
  model; most teams want branches and PRs. Use the repo's *actual* workflow.
- his large appendix documenting *his* personal toolchain (`br`/`bv`/UBS/`ntm`/Agent
  Mail). Replace with **this repo's** real tools, discovered in Part I.

If an `AGENTS.md` already exists, **improve in place** — merge generated sections, leave
hand-authored sections alone, and show a diff before writing.

## II.B — In-repo layout

Use the right path for each surface. Proposed artifacts are real committed files
unless the human explicitly chooses a local-only setup:

```
repo/
├── AGENTS.md
├── docs/agents/reviewing.md              # durable review context, optional
├── .agents/skills/                       # local CLI/OpenCode/Copilot CLI project skills
│   ├── <project>-squint-kickoff/SKILL.md
│   ├── <project>-squint-deeper/SKILL.md
│   └── <project>-squint-walkthrough/SKILL.md
├── .github/skills/code-review/SKILL.md   # GitHub.com Copilot code review, optional
├── .github/agents/deep-reviewer.agent.md # Copilot cloud custom agent, optional
└── .github/copilot-instructions.md       # optional thin pointer
```

Respect these gotchas:

- **SKILL.md frontmatter is portable.** `name` (lowercase-hyphen = dir name) +
  `description` are the key trigger metadata.
- **Nested `AGENTS.md` is NOT reliably portable** across surfaces → keep critical rules
  in the **root** `AGENTS.md`.
- **The `CLAUDE.md` trap:** OpenCode *ignores* `CLAUDE.md` when `AGENTS.md` exists;
  Copilot *merges* it. So make `CLAUDE.md` a thin delegate or a `CLAUDE.md → AGENTS.md`
  symlink — one source of truth.
- **GitHub.com code review:** use `.github/skills/code-review/SKILL.md` for
  review-specific skill context. Keep `.github/copilot-instructions.md` short
  because GitHub code review only reads a limited prefix.

---

# PART III — REVIEW-TAILORING output

Goal: make the generic `squint` loop richer and cheaper *for this repo* without
forking the procedure. Generate project-scoped shims only when they will reduce
future prompt burden.

**Everything here is proposed and shown before writing (Hard Rule 2).**

## III.A — Thin `<project>-squint-*` shims

For each generic verb the repo actually uses (`kickoff`, `deeper`, `walkthrough`,
optionally `cloud`), generate a `<project>-squint-<verb>` skill that is a thin
shim:

> Load this repo's `AGENTS.md` and `docs/agents/reviewing.md` if present, then run
> the generic `squint-<verb>` procedure with these project defaults.

The shim is not a copy of the procedure. It carries only project defaults:
preferred review depth, checkout strategy (`current-folder` vs worktree),
safe local validation commands, whether worktrees are preferred, known risky
subsystems, and optional panel roster. In a monorepo, use the app slug:
`join-form-squint-kickoff`, `admin-squint-kickoff`, etc.

## III.B — Durable review context

Put durable context in docs, not in a separate context skill:

- `docs/agents/reviewing.md` — concise review-relevant context: architecture map,
  build/test/CI commands, local validation safety notes, risk register, review
  lenses, reviewer voice, and links/provenance.
- `docs/architecture/*.md` or existing docs — deeper context only if needed.
- Optional model roster for `squint-panel` lives in the project shim or
  `docs/agents/reviewing.md`, not in the generic distributed skill.

## III.C — Distribution defaults

Project-specific artifacts should be real committed files so teammates and CI see
the same behavior. Do not create local symlinks by default.

| Artifact | Default |
|---|---|
| `<project>-squint-*` shims | real committed files under `.agents/skills/` |
| durable review context | real committed docs under `docs/agents/` |
| GitHub code review skill | real committed `.github/skills/code-review/SKILL.md` when enabled |
| Copilot cloud custom agent | real committed `.github/agents/*.agent.md` when enabled |
| generic `squint-*` | installed globally on each developer machine |

If the team already has a shared skills repo or bootstrap script, reference that
mechanism. Otherwise do not invent local-only symlink infrastructure during first
onboarding.

---

## Report

Return, concisely:

1. **Sources checked** and any access gaps (Part I inventory result).
2. **Strongest project-specific insights** — the architecture map's headline, the top
   risks/invariants, and the named likely-bug-classes seeded as review lenses.
3. **Your access level** + the test command and its cost.
4. **Reviewer voice** — the 3 strongest standing themes (or `inferred-from-repo` if you
   had no prior reviews here).
5. **Repo-readiness output** (if produced): the AGENTS.md you authored/improved, the
   `docs/` files you decomposed depth into, and any project skill scaffold — each
   shown and approved before writing.
6. **Review-tailoring output** (if produced): the `<project>-squint-*` shims,
   durable review docs, and any GitHub-specific code-review/cloud-agent files.
7. **What you deliberately produced or skipped** and why (the mode judgment) — and if you
   produced only one output, a one-line note that the deep pass is already paid for, so
   the other output is cheap to add on request.

Close with:

> Ready — `squint-kickoff <PR url>` (or `<project>-squint-kickoff <PR url>`) when the next
> review ping lands. Re-run `squint-onboard` by hand when this repo drifts.
