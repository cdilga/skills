# Authoring the wiki's AGENTS.md

The schema file is the wiki's operating system. Every future session — any model, any
harness — reads it first and behaves accordingly. Write it for a competent agent with
zero context: assume intelligence, supply the schema.

Two style rules before the spine:

- **Explain why, don't just command.** "Do not rewrite raw source files after ingest —
  corrections happen by superseding, so the source layer stays trustworthy" outlives
  "NEVER edit raw/". Agents follow reasoning further than they follow capitals.
- **Start minimal, co-evolve.** Ship the smallest schema that covers the workflows, and
  treat every future friction as a schema bug: fix the schema, log the supersession.
  The schema is grown through use, not designed complete.

## The spine

Order matters — orientation before rules, rules before workflows, domain quirks last so
they never contaminate the general structure.

1. **Title + role split.** One paragraph: what this wiki is for, and the division of
   labor ("The human curates sources, asks questions, and corrects priorities. The LLM
   maintains the markdown knowledge base.").
2. **Security/exposure callout** (if the wiki holds anything sensitive). A blockquote
   stating the exposure boundary and what enforces it — e.g. "never push to a public
   remote", or "the share export strips `personal/`". Put it high; it's the one rule
   with irreversible failure.
3. **Symlink callout.** "`CLAUDE.md` and `AGENTS.md` are the same file (CLAUDE.md is a
   symlink). Edit AGENTS.md." Documenting this *inside* the file is what prevents an
   agent from forking the two.
4. **Orientation map** ("read each run"). What the wiki can answer right now, the top
   questions it exists for, and arrows to the go-to pages. This section is rewritten as
   the wiki grows — it's a cache, and it's allowed to be one.
5. **Operating principles.** ~5–8 bullets. The non-negotiables usually include:
   epistemic separation (external rules vs. user-provided facts vs. LLM inference,
   visibly distinct); every extracted fact carries its capture date; raw is immutable —
   supersede, don't edit; file reusable answers back into the wiki; ask before creating
   new page types.
6. **Directory map.** One line per directory. Boring, load-bearing.
7. **Page conventions.** The frontmatter block (see below), the wikilink style, file
   naming, and the preferred sections per page type (mirroring `_templates/`).
8. **Ingest workflow.** Numbered steps (adapt the skeleton below).
9. **Query workflow.** Numbered steps.
10. **Lint workflow.** The health checklist (the wiki-tend skill runs against this).
11. **Tooling** (only if any exists). Exact commands, what to run after edits, and
    scope rules — especially what must *not* be indexed or bundled.
12. **Domain rules — quarantined last.** Anything specific to the subject matter
    (jurisdiction quirks, a project's deadlines, one topic's special handling) lives in
    its own final section, so the rest of the schema stays portable and a future
    "start a similar wiki" can copy everything above it.

## Frontmatter convention

Keep one block, documented once in the schema, used by every page:

```yaml
---
type: <one of the wiki's page types, plus: index | log>
status: draft | active | stable | needs-review
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: []
sources: []   # paths, URLs, or prose provenance — mixed is fine, but say so
---
```

The `type` enum is a contract: the lint workflow checks pages against it, so adding a
type means updating the schema and a template, not just typing a new word.

## Workflow skeletons

Adapt the nouns; keep the shape.

**Ingest** — the property that matters: one source may touch many pages, and every step
that maintains navigation (index, log, cross-links) is explicit, because those are the
steps that get skipped when they're implicit.

1. Read this schema and `wiki/index.md` to orient.
2. Inspect the source. If it makes claims about the changing external world, verify
   against the live official source and record the access date.
3. Register the source in `raw/` (sensitive material goes to the personal axis, if the
   wiki has one). Raw files are immutable from here on.
4. Write or update a source-summary page: why it matters, key extracted facts (dated),
   which pages it updates.
5. Update every affected page — a single source can touch many.
6. Cross-link concepts, entities, dates, decisions, and **contradictions** (a flagged
   contradiction is more valuable than a silent overwrite).
7. Update `wiki/index.md`.
8. Append a log entry.

**Query**

1. Orient via the index (and search tooling, if any) before deep reads.
2. Read the pages that matter; verify live sources when the answer depends on rules
   that may have changed.
3. Answer with citations to page headings, keeping external rules / user facts /
   inference visibly separate.
4. If the answer produced reusable analysis, offer to file it back as a page.

**Lint** — run periodically; the wiki-tend skill drives this. Check: stale dated facts;
contradictions between pages; unmarked assumptions; orphan pages with no inbound
links; concepts mentioned repeatedly without their own page; broken wikilinks; index
entries that don't match reality; frontmatter outside the documented enum; log format
drift; and (for planning wikis) active pages that lack a next action. Findings append
to the log; gaps become question pages.

## Log convention

Append-only journal at `wiki/log.md`. Entry heading format:

```
## [YYYY-MM-DD] <kind> | <title>
```

with a small closed set of kinds (e.g. `setup | ingest | update | lint | tooling`).
State in the schema whether new entries are appended at the bottom (recommended — it's
what "append" means and what `tail` expects). The log records supersessions explicitly:
when a decision or doc changes, the entry names what it replaces.
