---
name: squint-onboard
description: "Heavy, manual, deliberately expensive onboarding for a repo's PR-review experience. ONE shared deep pass — mining source history, work history, design docs, prior agent/session history, architecture, PRs/issues, and the repo's review culture (gh), with subagents and a structured failure-hunting process — feeds TWO kinds of output from the same paid-for research. (a) REPO-READINESS: author/improve a lean root AGENTS.md and a decomposed docs/ set, plus the cross-tool .agents/skills/ scaffold both Copilot CLI and OpenCode read. (b) REVIEW-TAILORING: generate thin <team>-squint-* shims and <team>-ctx* context skills so the generic squint review loop runs richer and cheaper. Read-only by default; propose, never impose. Bias strongly toward producing BOTH outputs — the deep pass is already paid for. Re-run by hand when a repo drifts."
triggers:
  - squint-onboard
  - onboard this repo for review
  - set up review context for this repo
  - author or improve this repo's AGENTS.md
  - make this repo agent-ready
  - generate team review skills for this repo
  - deeply study this codebase before reviewing
  - first time reviewing in this repo
---

# squint-onboard — one deep pass, two kinds of output

This is the heavyweight, manual member of the `squint` suite. You run it by hand
when *you* judge a repo is worth a deep, token-expensive study — and you re-run it
by hand when the repo has drifted. There is no cron, no sweep, no queue: **you are
the scheduler.**

The expensive part — deeply mining the repo's history, its prior agent sessions,
its design intent, its architecture, and its review culture — is done **once**, as a
single shared pass. Two different artifacts get *written* at the end:

- **(a) Repo-readiness** — author or improve the root `AGENTS.md`, decompose depth
  into focused `docs/` files, and stand up the cross-tool `.agents/skills/` scaffold.
  Generic; helps *every* agent that works in the repo, not just reviewers.
- **(b) Review-tailoring** — generate thin `<team>-squint-*` review shims and
  `<team>-ctx*` context skills so the generic `squint-kickoff` → `squint-deeper` →
  `squint-walkthrough` loop runs richer and cheaper for this repo.

Because the deep pass is the cost, the marginal cost of the *second* output is small.
**Bias strongly toward doing both.**

## Mode is YOUR judgment, not a flag

There is no `--mode` switch, no subcommand keyword, no hardcoded toggle. **You, the
loading agent, infer intent** from the request and the context:

- "author this repo's AGENTS.md" / "make this repo agent-ready" → leans (a).
- "set up review skills for my team" / "generate the squint shims" → leans (b).
- "onboard this repo" / "deeply study this before reviewing" / anything vague → **both.**

**Default to both.** You have already paid for the deep pass; producing the second
output is cheap relative to that. Ask the human to disambiguate **only** when intent
is genuinely unclear *and* the difference actually changes what you'd do. Do not
manufacture a fork where none is needed.

Whatever you produce, the **shared deep pass (Part I) runs in full regardless of
mode** — it is the foundation for either output.

## Hard rules (non-negotiable)

1. **Read-only by default.** Discovery never edits the repo, tickets, docs, PRs, or
   issues. The *only* writes are the artifacts in Parts II/III — and each of those is
   **proposed and shown before it is written**, then written only on explicit human
   approval. You may run builds/tests/linters (they don't mutate tracked files) and
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

**Team-name resolution.** If the team is not obvious from the request or context, ask the
human for it before generating any `<team>-*` artifacts.

---

# PART I — the shared deep pass (always runs)

This is the expensive, manual heart of the skill. **Spawn subagents** for the
fan-out legs so the breadth doesn't blow your context, and run a **structured
failure-hunting process** — you are not just cataloguing the repo, you are hunting for
the bug classes and invariants that future reviews must defend.

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
  RUN the test command once to learn its cost — record "fast (~30s)" vs "heavy (~10m,
  prefer targeted runs)". This block is copy-pasted verbatim into the AGENTS.md
  Toolchain section and the `<team>-ctx*` skills.
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

## Phase 4 — Failure-hunting fan-out (spawn subagents)

Don't merely map the architecture — **hunt the failure modes.** Spawn focused subagents
over the high-signal slices and have each return distilled findings (not raw dumps):

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

At the end of Part I you hold: a distilled architecture map, a risk/invariant register,
a named set of likely bug classes, the repo's review culture + your reviewer voice, and
the exact build/test/lint block. **This is the shared substrate for both outputs.**

---

# PART II — REPO-READINESS output

Goal: leave the repo so that *any* agent (reviewer or not) on *any* surface (Copilot CLI,
OpenCode, CI) lands well. Two pieces: a lean root `AGENTS.md` (with depth decomposed into
`docs/`), and the cross-tool `.agents/skills/` scaffold.

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
4. **Build/test/lint as a copy-paste block under a "(CRITICAL)" heading** — the verbatim
   commands from Phase 1, so no agent guesses them.
5. **No file proliferation, no `_v2`, no compat shims** — stated inline because it shapes
   every edit an agent makes.
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
## Code Editing Discipline      (edit-in-place; no _v2; no compat shims)
## Architecture — Quick Reference   (terse; deep detail → cite docs/ path)
## Project-Specific Non-Negotiables (3–6 repo-unique constraints, from Part I)
## Per-Tool Reference           (purpose · commands · gotchas · entry-point)
## Landing the Plane            (session-completion checklist)
## (footer) Re-read this file after any context compaction.
```

**Decompose depth into `docs/`.** Anything beyond a Quick Reference — module deep-dives,
data-flow diagrams, the full invariant register, migration playbooks — becomes a focused
`docs/<topic>.md` file that AGENTS.md *cites by path*. Push the failure-hunting output
from Part I into these docs; keep AGENTS.md lean.

**Do NOT cargo-cult Jeffrey Emanuel's idiosyncrasies.** His real files are the *craft*
model, not a template to copy literally. Specifically reject:
- "main only, never branch / never use worktrees" — that fits his swarm-on-one-repo
  model; most teams want branches and PRs. Use the repo's *actual* workflow.
- his large appendix documenting *his* personal toolchain (`br`/`bv`/UBS/`ntm`/Agent
  Mail). Replace with **this repo's** real tools, discovered in Part I.

If an `AGENTS.md` already exists, **improve in place** — merge generated sections, leave
hand-authored sections alone, and show a diff before writing.

## II.B — Cross-tool in-repo layout

Both Copilot CLI and OpenCode natively read root `AGENTS.md` and both scan
`.agents/skills/` (and `.claude/skills/`). Set up **one layout, near-zero duplication**:

```
repo/
├── AGENTS.md                       # BOTH tools read natively (CLI + CI). The keystone.
├── .agents/skills/                 # BOTH tools scan for checked-in skills
│   ├── <team>-squint-kickoff/SKILL.md
│   ├── <team>-ctx/SKILL.md
│   └── <team>-ctx-<project>/SKILL.md
└── .github/copilot-instructions.md # OPTIONAL, Copilot-only — keep a 1-line "See AGENTS.md."
```

Respect these gotchas:

- **SKILL.md frontmatter is portable.** `name` (lowercase-hyphen = dir name) +
  `description` are identical across both tools → author once.
- **Nested `AGENTS.md` is NOT reliably portable** across surfaces → keep critical rules
  in the **root** `AGENTS.md`.
- **The `CLAUDE.md` trap:** OpenCode *ignores* `CLAUDE.md` when `AGENTS.md` exists;
  Copilot *merges* it. So make `CLAUDE.md` a thin delegate or a `CLAUDE.md → AGENTS.md`
  symlink — one source of truth.
- **`.github/copilot-instructions.md`** is only for Copilot surfaces that don't honor
  AGENTS.md (github.com Chat / code review). Keep it a thin pointer ("See AGENTS.md."),
  never a duplicate body.

---

# PART III — REVIEW-TAILORING output

Goal: make the generic `squint` loop richer and cheaper *for this repo* — **without
forking the procedure.** You generate two things: thin review **shims** and **context**
skills. The procedure lives once in the generic `squint-<verb>` skills; tailoring binds
context + overrides.

**Everything here is proposed and shown before writing (Hard Rule 2).**

## III.A — Thin `<team>-squint-*` shims (NOT forks)

For each generic verb the team uses (`kickoff`, `deeper`, `walkthrough`, `cloud`),
generate a `<team>-squint-<verb>` skill that is a **thin shim**:

> Load `<team>-ctx` (+ the resolved project ctx), then run the generic
> `squint-<verb>` procedure with these team overrides.

It is **not** a copy of the procedure — it references the generic skill and carries only
the bindings and the handful of team tweaks. No procedure duplication. The prefix stops
at **team, not project**: `<team>-squint-kickoff <url>` resolves the project at runtime
from the PR's repo/path against each context skill's `repos:` / `paths:` frontmatter, so
join-form-vs-full-app (two repos, or one monorepo split by path) is handled by **context
resolution, not by more name segments.**

## III.B — `<team>-ctx` and `<team>-ctx-<project>` context skills

- **`<team>-ctx`** — team-wide, lives-once facts: shared review doctrine, severity
  taxonomy, the team's reviewer-voice patterns, cross-repo conventions.
- **`<team>-ctx-<project>`** — per-project context distilled from Part I: architecture
  map (or a pointer to `docs/`), build/test/CI block, domain invariants, risk register,
  the project's review lenses, and a standing pre-diff checklist. It opens with **"load
  `<team>-ctx` first"** — referencing, not copying.

Both carry **`repos:` / `paths:` frontmatter** so the shims can resolve the right
project context at runtime from a PR URL.

**`<team>-ctx` first-creation (bootstrap).** Check whether `~/.agents/skills/<team>-ctx/`
already exists. If it **does**, symlink it into this project repo's `.agents/skills/` —
later repos reuse the existing team context. If it does **not**, generate it from the
shared deep pass (Part I), write `~/.agents/skills/<team>-ctx/SKILL.md`, then symlink it
in. So the first repo onboarded for a team *creates* `<team>-ctx`; every later repo
*reuses* it.

## III.C — Committed vs symlinked, and the link manifest

Apply the policy by artifact type:

| Artifact | In a project repo | Symlink? |
|---|---|---|
| `<team>-squint-*` shims | **real committed files** (must travel to CI/teammates) | No |
| `<team>-ctx-<project>` (project context) | **real committed file** | No |
| `<team>-ctx` (team-shared, used by many repos) | lives once canonically, needed in N repos | **Yes — symlinked** |
| generic `squint-*` | already global via `~/.agents/skills` | Optional |

Rule of thumb: **project-unique artifacts are real committed files; only shared,
lives-once, needed-in-many-places artifacts are symlinked.**

For the symlinked `<team>-ctx`:

1. **Per-project LINK MANIFEST** — a **committed** file at the repo root,
   `.agents/squint-links.md`, one entry per symlink: `target → source`, purpose, and a
   `local-only` flag. The symlinks themselves are local-only/gitignored, but the manifest
   that documents them is committed, so CI and teammates know which local links to recreate
   (the CI-doesn't-get-symlinks fallback below).
2. **Idempotent re-link step** — re-running onboarding re-asserts links with the same
   collision logic as `install.sh`: quiet if already correct, warn on a foreign clobber,
   skip real dirs. A per-project mini-installer.
3. **Gitignored, never committed** — a symlink into `~/.agents/skills/...` won't resolve
   elsewhere, so add it to `.gitignore` / `.git/info/exclude`.

**State the CI caveat explicitly in the notes:** symlinks do NOT travel to CI or to
teammates. For shared team context, record the chosen fallback — *either* CI runs an
install step (or clones a team-skills repo), *or* that one shared file is committed as a
real copy into each repo and **re-synced on every re-onboard**. Symlink = zero drift but
local-only; committed copy = travels but you re-sync it. **Document which choice this
project made.**

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
   `docs/` files you decomposed depth into, and the `.agents/skills/` scaffold — each
   shown and approved before writing.
6. **Review-tailoring output** (if produced): the `<team>-squint-*` shims and
   `<team>-ctx*` context skills generated, plus the LINK MANIFEST and the committed-vs-
   symlinked / CI fallback choice for `<team>-ctx`.
7. **What you deliberately produced or skipped** and why (the mode judgment) — and if you
   produced only one output, a one-line note that the deep pass is already paid for, so
   the other output is cheap to add on request.

Close with:

> Ready — `squint-kickoff <PR url>` (or `<team>-squint-kickoff <PR url>`) when the next
> review ping lands. Re-run `squint-onboard` by hand when this repo drifts.
