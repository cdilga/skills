# The defaults — a proven private-wiki stack

Load this file only when the user has explicitly asked for "the defaults", "the usual
setup", or "like parent-wiki". It records a configuration that ran well in production
as a private household planning wiki. It is opinionated and embeds trade-offs (notably:
sensitive data lives in the repo, gated at export time, and context packs get uploaded
to chat LLMs). Applying it without the interview is fine *only because the user asked*.

## Stack summary

| Concern | Choice |
|---|---|
| Format | Plain markdown; no site generator, no build, no publishing |
| Editor | VS Code + Foam (`foam.foam-vscode`); Obsidian-compatible |
| VCS | git; **no public remote, ever** (private remote acceptable if user wants backup) |
| Search | [qmd](https://github.com/tobi/qmd) (`npm install -g @tobilu/qmd`) behind a locked wrapper script |
| Access story | Concatenated single-file "context packs" uploaded to a chat LLM project |
| Sensitivity | `personal/` axis in both layers; three independent gates (see below) |
| CI / hooks | None. Discipline lives in AGENTS.md prose, checked by lint passes |

## Layout

```
<name>-wiki/
├── AGENTS.md            # schema (authored per schema-authoring.md)
├── CLAUDE.md -> AGENTS.md
├── README.md            # short human entry point
├── .gitignore           # commits everything incl. personal/; ignores editor noise only
├── .vscode/             # settings.json + extensions.json (below)
├── scripts/
│   ├── bundle.sh        # copy from assets/, set WIKI_NAME + section list
│   └── qmd.sh           # copy from assets/, set index name + collections
├── raw/
│   ├── inbox/           # un-ingested drops
│   ├── sources/<topic>/ # YYYY-MM-DD-kebab-slug.source.md capture cards
│   ├── assets/          # downloaded images/attachments
│   └── personal/        # sensitive originals (PDFs, screenshots, records)
└── wiki/
    ├── index.md         # file-by-file catalog; read first
    ├── log.md           # append-only journal
    ├── _templates/      # one per page type (copy from assets/templates/)
    ├── <type-dirs>/     # e.g. topics/ cases/ people/ questions/ sources/
    └── personal/        # synthesized notes about the household specifically
```

Default page types — tuned for a *decision-under-external-rules* wiki (benefits, tax,
immigration, contracts). Reuse only if the new domain is the same shape; otherwise
derive types per the interview:

`topic` (Summary / Current Rules / How It Connects / For Us / Open Questions / Sources) ·
`case` (Purpose / Known Context / Decision Model / Context Needed / Working Plan /
Risks / Sources — the two middle sections as tables, which turns the page into a live
worklist) · `person` · `question` · `source-summary` (Source / Why It Matters / Key
Extracted Facts / Pages Updated).

Naming: wiki pages are Title Case with real spaces (`wiki/topics/Some Topic.md` —
editor-friendly; all scripts must handle spaces). Source summaries append the capture
date. Raw captures are `YYYY-MM-DD-kebab-slug.source.md` under a kebab-case topic dir.

Links: wikilinks with explicit path *and* alias — `[[topics/Some Topic|Some Topic]]` —
so links survive file moves and read well in plain text. Raw binaries are referenced as
backticked paths, not links.

## The three sensitivity gates

The clever part of this stack: **sensitivity is orthogonal, and each gate is tuned
independently.**

1. **git** commits *everything*, including `personal/` — the most valuable data is
   exactly what most needs backup and versioning. This only works with the no-public-
   remote rule, so state both in the same breath in AGENTS.md.
2. **Search** indexes `wiki/personal/` (synthesized notes are useful in queries) but
   **never** `raw/personal/` originals, the repo root, or generated packs.
3. **Export**: `bundle.sh` builds two packs — `CONTEXT-PACK.full.md` (everything) and
   `CONTEXT-PACK.share.md` (personal layer stripped; raw personal binaries appear only
   as a filename manifest with "ask us to upload it directly").

Editor search follows the same split (`.vscode/settings.json` excludes `raw/personal`).

## Scripts

Copy from this skill's `assets/`, then personalize the marked variables at the top of
each. Both are written for filenames with spaces and set `-euo pipefail`.

- **`bundle.sh`** — concatenates the wiki into one markdown file in a fixed section
  order (schema → index → pages by type → source summaries → raw cards → personal, the
  last only in full mode), each file preceded by a `<!-- FILE: path -->` marker. It
  prepends a system-prompt header that tells the receiving chat LLM its role, the
  epistemic-separation rule, and that dates may be stale. Prints a word count on build.
  Rationale (from Karpathy's pattern): for a small corpus, one file uploaded to a fresh
  chat beats RAG and beats hosting. **Regenerate and commit both packs after every
  editing session.**
- **`qmd.sh`** — a wrapper around the qmd CLI that (a) serializes all access through a
  lock file, because concurrent agents corrupt the SQLite vector index
  (`sqlite-vec probe failed (database is locked)` is the tell), and (b) auto-scopes
  every search to the wiki's named collections so agents can't accidentally query
  someone's whole home directory. Subcommands: `status`, `update` (run after every
  editing session), `search`/`query`/`vsearch`, `get`/`multi-get`/`ls`, and `raw` as
  the escape hatch.

qmd setup: create a named index, add one collection per wiki area (index, log, each
page-type dir, raw sources — *not* `raw/personal/`, *not* the repo root), and attach a
natural-language description to each collection URI via `qmd context add` so search
results explain themselves. Record the recreate-from-scratch recipe in a `tools/`
README — indexes get rebuilt more often than you'd think.

## Editor config

`.vscode/extensions.json`: `foam.foam-vscode`, `yzhang.markdown-all-in-one`,
`davidanson.vscode-markdownlint`.

`.vscode/settings.json`:

```json
{
  "files.exclude": { "**/.DS_Store": true },
  "markdown.validate.enabled": true,
  "editor.wordWrap": "on",
  "search.exclude": { "raw/personal/**": true }
}
```

`.gitignore` — deliberately tiny, with the reasoning as a comment at the top (this repo
*commits* its data; the gitignore's job is only editor noise):

```
# This repository intentionally commits everything, including personal/ —
# the exposure boundary is enforced at the remote and at export, not here.
# Do not push to a public remote. See AGENTS.md.
.obsidian/workspace.json
.obsidian/workspace-mobile.json
.trash/
.DS_Store
*.swp
*.swo
```

## Assembly order

1. Scaffold layout above; symlink `CLAUDE.md`; write AGENTS.md per
   `schema-authoring.md`, including the tooling section with the exact `scripts/qmd.sh`
   and `scripts/bundle.sh` commands and the indexing scope rules.
2. Copy `assets/templates/*` into `wiki/_templates/` (rename/adjust to the chosen page
   types); copy and personalize both scripts; `chmod +x` them.
3. Install qmd if missing; create index + collections + context descriptions; run
   `scripts/qmd.sh update`.
4. First `bundle.sh` run in both modes; commit everything including the packs.
