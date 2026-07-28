---
name: wiki-tend
description: >-
  Health-check and maintain an existing *-wiki (an LLM-maintained markdown knowledge
  base with an AGENTS.md schema, raw/ sources, and a wiki/ synthesis layer). Use
  whenever the user asks to lint, audit, health-check, clean up, or "tend" their wiki,
  says it feels stale or messy, wants the index/log/search rebuilt, or wants to evolve
  the wiki's schema or add tooling (search, export packs) to a wiki that has outgrown
  its setup. Not for creating a new wiki (use wiki-init) and not for ordinary ingest or
  queries — those follow the wiki's own AGENTS.md.
triggers:
  - lint my wiki
  - wiki health check
  - tend the wiki
  - wiki feels stale
  - clean up the wiki
  - rebuild the index
  - update the context pack
---

# wiki-tend

A wiki stays trustworthy only if something periodically checks it against reality.
Ingest and query keep the wiki *growing*; this skill keeps it *true*. Nothing here is
CI — in this pattern, discipline lives in prose and is enforced by exactly this kind of
pass.

## Orient first

The wiki's own `AGENTS.md` outranks this skill on every specific: page types, section
layouts, tooling commands, scope rules. Read it, then `wiki/index.md`, then the tail of
`wiki/log.md` (`grep "^## \[" wiki/log.md | tail -5`) to learn what happened recently
and what the last lint pass already found. If the wiki has its own lint checklist, run
that one — the checklist below fills gaps, it doesn't override.

## The lint pass

Work through three lenses. For each finding, record: the file, what's wrong, and the
proposed fix. Fix mechanical problems directly; queue judgment calls for the user.

**Content — is it still true?**
- Dated facts about the changing external world that are old enough to re-verify;
  check the live source for anything rules-dependent and note the new access date.
- Contradictions between pages (the most valuable catch — a flagged contradiction beats
  a silent one, and a resolved one beats both).
- LLM inference presented as fact, or user-specific assumptions stated as general
  truth — the epistemic-separation rule applied retroactively.
- Claims whose source was later superseded in the log but whose pages never caught up.

**Structure — can it be navigated?**
- `wiki/index.md` diffed against the actual file tree: unlisted pages, entries pointing
  at moved or deleted files.
- Broken wikilinks; orphan pages with no inbound links.
- Concepts mentioned across several pages that deserve their own page but don't have
  one (these become the wiki's roadmap).
- Frontmatter drift: `type:` values outside the schema's documented enum, missing
  `updated:` dates. Drift means either fix the page or grow the enum in `AGENTS.md` —
  never leave the two disagreeing silently.
- Planning wikis only: active case/plan pages with no next action.

**Machinery — do the moving parts still work?**
- Log format drift (entries not matching `## [YYYY-MM-DD] kind | title`, or ordering
  that contradicts the schema's append rule).
- Search index freshness: run the wiki's update command (e.g. `scripts/qmd.sh update`)
  and confirm the collections still match the directory layout — a renamed page-type
  directory silently empties its collection.
- Export packs (if any) regenerated in every mode and committed; confirm the share
  variant still strips everything the exposure boundary says it must. This check is
  load-bearing: it is the last gate before sensitive data leaves the repo.
- Scripts still run (`bash -n` at minimum); anything indexing or bundling generated
  artifacts (the packs themselves, the repo root) gets scoped back out.

## Close the loop

A lint pass that only produces a chat message evaporates. Before finishing:

1. Apply the mechanical fixes; list the judgment calls for the user with your
   recommendation each.
2. File gaps as question pages (or the wiki's equivalent) so they're queryable, not
   just mentioned.
3. Update `wiki/index.md` if anything moved.
4. Append a `lint` entry to `wiki/log.md`: what was checked, what was found, what was
   fixed, what was deferred. Findings deferred without a trail are findings lost.
5. Rebuild search index and export packs if the wiki has them, and commit.

## Evolving the schema

Recurring friction is a schema bug, not an agent failure. If the same problem shows up
across lint passes — a page type that keeps drifting, a workflow step everyone skips, a
convention nobody follows — change `AGENTS.md`: amend the rule, or delete it if it
never earned its keep. Record the change as a log entry that names what it supersedes.
The schema was born minimal on purpose; passes like this are how it grows.

Domain-specific rules stay quarantined in the schema's final section, so the portable
part stays portable.

## Growth thresholds

Signs the wiki has outgrown its setup, and the cheap next step for each:

- **Queries miss pages the index lists** → add local search. See
  `../wiki-init/references/defaults.md` for the proven qmd setup (named index,
  per-area collections, and the locking wrapper that prevents concurrent-agent index
  corruption) and `../wiki-init/assets/qmd.sh` for the script to copy.
- **The user wants the wiki on their phone or in a chat project** → add a bundle
  script; `../wiki-init/assets/bundle.sh` is the template. Sensitive wikis need the
  two-pack (full/share) split and an explicit exposure decision first.
- **A hub page answers three unrelated question families** → split it, leave the hub
  as a signpost, update index and inbound links in the same pass.
- **The orientation map in `AGENTS.md` no longer matches what the wiki knows** →
  rewrite it. It's a cache; refreshing it is expected, not churn.
