---
name: wiki-init
description: >-
  Initialize a new *-wiki — a git repo of markdown that the LLM builds and maintains
  while the human curates sources, asks questions, and corrects priorities. Use whenever
  the user wants to start a knowledge base, research wiki, personal or household wiki,
  book/course/project companion wiki, "second brain", or says anything like "a wiki like
  parent-wiki", even if they don't use the word "wiki". Co-designs the wiki from first
  principles by default; applies the battle-tested defaults only when the user explicitly
  asks for "the defaults". Not for docs sites meant for human authorship or publishing,
  and not for maintaining a wiki that already exists (use wiki-tend for that).
triggers:
  - new wiki
  - start a wiki
  - knowledge base
  - research wiki
  - second brain
  - like parent-wiki
  - set up a wiki for
  - track everything about
---

# wiki-init

You are about to build the thing that makes future sessions smart: a **persistent,
compounding knowledge base** that an LLM maintains and a human directs.

## The pattern

Most LLM-plus-documents setups are RAG: retrieve chunks, answer, forget. Nothing
accumulates — every subtle question re-derives the synthesis from scratch. A *-wiki
refuses that. When a source arrives, the LLM reads it once and **integrates** it:
updates entity pages, revises summaries, flags contradictions, adds cross-links. The
synthesis is compiled once and kept current. Explorations compound too — a good answer
gets filed back as a page instead of dying in chat history.

Three layers, with different mutability rules:

1. **`raw/`** — the human's curated sources. **Immutable after ingest.** Corrections
   happen by adding a superseding source and noting it in the log, never by editing
   history. This is what makes the wiki trustworthy as a source of truth.
2. **`wiki/`** — the LLM-owned synthesis. Freely created, rewritten, split, merged,
   cross-linked. The human reads it; the LLM writes it.
3. **The schema** — an `AGENTS.md` at the repo root that tells every future session how
   the wiki is structured and what the workflows are. **This file is the real
   deliverable of wiki-init.** It is what turns a generic chatbot into a disciplined
   wiki maintainer. Everything else is directories.

The division of labor: the human curates, questions, and decides what matters. The LLM
does all the bookkeeping — summarizing, cross-referencing, filing, index maintenance —
because bookkeeping is why humans abandon wikis and why LLMs don't.

## Two paths in

**First principles (the default).** Run the interview below and co-design a wiki shaped
by the user's actual domain. Do this even if the user seems in a hurry — the interview
is short, and a wiki shaped like someone else's domain quietly rots. Do not impose
tooling, page types, or scripts from the defaults file; let the domain demand them.

**"Use the defaults."** Only when the user explicitly asks for the defaults / the
parent-wiki setup / "your usual stack": read `references/defaults.md` and scaffold it
directly. That file records a proven private-household configuration (plain markdown +
Obsidian/Foam, qmd search behind a locked wrapper, single-file context packs as the
access story). It works instantly, but it embeds real trade-offs the user should have
chosen — which is exactly why it isn't the default path.

## The decisions that matter

Interview the user on these. Each is a genuine fork, and the answer shapes the schema.
If the user has already answered one in their request, don't re-ask it.

1. **What questions should this wiki answer?** Not "what is it about" — what will the
   user actually ask it in three months? This drives everything else. Write the top
   three questions into the schema's orientation section so future sessions know the
   point of the wiki.

2. **Page types.** Derive a small set (4–7) from the domain rather than copying anyone
   else's enum. A regulatory/planning wiki wants `topic / case / person / question /
   source-summary`; a book wiki wants `character / place / theme / chapter`; a research
   wiki wants `concept / paper / claim / open-question`. Every type gets a section
   template, so a type that has no natural sections is probably not a real type.

3. **Sensitivity and exposure boundary.** Where is the line between shareable and not,
   and what enforces it? The proven pattern is sensitivity as an *orthogonal axis* — a
   `personal/` subdirectory inside both `raw/` and `wiki/` — with independent gates
   (what git commits, what search indexes, what any export includes). If nothing is
   sensitive, skip the axis entirely. If anything is, make the user choose the boundary
   explicitly: private-only repo, private repo + sanitized export, or public. Never
   default to exposing.

4. **Access story.** Where will the user actually read and query this — an editor with
   a wiki extension (Obsidian/Foam), a phone chat, a published site? This decides
   whether you need an export/bundle step at all. For a corpus under ~50k words, one
   concatenated markdown file uploaded to a chat project beats any hosting or RAG
   setup: cheapest possible "make it accessible".

5. **Search.** Start with none. A maintained `index.md` (read the index, then drill in)
   works to hundreds of pages, and premature search infrastructure is maintenance debt.
   Note in the schema when to graduate: when the agent starts missing relevant pages
   that the index lists, add local search (see `references/defaults.md` for the qmd
   setup, including the concurrency locking it turned out to need).

6. **Naming and linking.** Pick one convention and write it down: wikilink style (with
   explicit path and alias so links survive moves), file naming for pages vs. raw
   source captures (date-prefixed slugs for captures pay off), and whether page names
   use spaces (editor-friendly, shell-hostile — any script must handle them).

7. **Epistemic separation.** How will pages keep three things visibly distinct:
   official/external rules, facts the user provided, and the LLM's own inferences?
   This is the single highest-value convention in the pattern. The proven move is a
   dedicated "for us" section on every general page — external truth above, household
   application below — plus a rule that every extracted fact carries its capture date.

## Scaffold

Once the decisions are made:

1. `git init` a new repo named `<domain>-wiki`. Confirm the remote posture matches the
   exposure decision before anything sensitive lands (no remote, private remote, or
   public — in that order of caution).
2. Create the layers: `raw/` (with an `inbox/` for un-ingested drops), `wiki/` with
   `index.md`, `log.md`, `_templates/`, and one subdirectory per page type. Add a
   `personal/` axis in both layers only if decision 3 called for it. Put a one-line
   README in each directory saying what belongs there — future sessions and the user
   both navigate by them.
3. Author `AGENTS.md` following `references/schema-authoring.md`. Symlink `CLAUDE.md`
   to it and say so inside the file, so no agent ever forks the two.
4. Write a `_templates/` file per page type, and the frontmatter block into the schema.
5. Seed `wiki/index.md` (even nearly empty — the habit matters more than the content)
   and open `wiki/log.md` with a dated `setup` entry recording every decision made and
   every assumption taken. This entry is the wiki's birth certificate; the first lint
   pass will check reality against it.
6. Commit. Then, if the user has a first source ready, run the schema's ingest workflow
   on it immediately — the first ingest is the best test the schema gets.

Keep the initial scaffold minimal. Every file you create is a promise future sessions
must keep; a small schema that grows through use beats a grand one that drifts.

## If the user can't be interviewed

When running non-interactively, or the user has said "just set it up": make the minimal
sensible choice for each decision, lean toward *less* (no search tooling, no export
step, no sensitivity axis unless the domain obviously needs one), and record every
assumption in the `setup` log entry as an explicit list titled "Assumptions to revisit".
A wrong guess recorded in the log costs one correction; a wrong guess baked silently
into the schema costs the wiki its trustworthiness.

## Hard-won pitfalls

Learned from a wiki that ran long enough to expose them:

- **Never index or bundle generated artifacts.** If you add search or an export pack,
  exclude the pack files and the repo root from indexing, or the index poisons itself
  with its own output.
- **Frontmatter enums drift silently.** Nothing validates `type:` fields, so the lint
  workflow in the schema must include "check frontmatter against the documented enum".
- **"Append-only" needs a definition.** Specify the log entry format
  (`## [YYYY-MM-DD] <kind> | <title>`) *and* whether new entries go top or bottom,
  or the log ends up unsorted. Keeping the format greppable
  (`grep "^## \[" log.md | tail -5`) makes the log a tool, not a diary.
- **Provenance wants structure.** A `sources:` list that mixes file paths, URLs, and
  prose descriptions is fine — but say so in the schema, so pages stay consistent.
- **Spaces in filenames break naive shell loops.** If page names use spaces, every
  script uses `while IFS= read -r` / `find -print0`, never `for f in $(...)`.
- **The index goes stale by hand.** Make "update `index.md`" an explicit numbered step
  of the ingest workflow, and make "diff index against reality" a lint check.

## References

- `references/schema-authoring.md` — read when writing the new wiki's `AGENTS.md`: the
  section spine, frontmatter conventions, and the ingest/query/lint workflows to adapt.
- `references/defaults.md` — read **only** when the user explicitly asks for the
  defaults: the full proven stack, with install commands and the bundled assets to copy.
- `assets/` — default scripts (`bundle.sh`, `qmd.sh`) and page templates, used by the
  defaults path; also worth mining for patterns when a co-designed wiki later needs an
  export or search story.

After the wiki exists, day-to-day operation belongs to the wiki's own `AGENTS.md`, and
periodic health checks belong to the **wiki-tend** skill.
