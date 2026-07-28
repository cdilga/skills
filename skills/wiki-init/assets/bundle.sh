#!/usr/bin/env bash
# bundle.sh — concatenate the wiki into single-file context packs.
#
# Rationale: for a corpus of tens of thousands of words, one markdown file uploaded
# into a fresh chat (ChatGPT Project / Claude Project) is the cheapest access story —
# no RAG, no hosting. Build two packs: full (everything) and share (personal stripped).
#
# Usage: scripts/bundle.sh [--share]
# Regenerate BOTH packs and commit them after every editing session.
set -euo pipefail
cd "$(dirname "$0")/.."

# ── Customize for this wiki ─────────────────────────────────────────────────────
WIKI_NAME="my-wiki"                 # used in filenames and the pack header
WIKI_ROLE="our planning assistant"  # who the receiving chat LLM should be
# Sections emitted in order: "BANNER TITLE|directory" (all *.md, sorted, READMEs skipped)
SECTIONS=(
  "TOPICS|wiki/topics"
  "QUESTIONS|wiki/questions"
  "SOURCE SUMMARIES|wiki/sources"
  "RAW SOURCE CARDS|raw/sources"
)
PERSONAL_NOTES_DIR="wiki/personal"    # emitted in full mode only; "" if no personal axis
PERSONAL_EVIDENCE_DIR="raw/personal"  # manifest-only in full mode; "" if none
# ────────────────────────────────────────────────────────────────────────────────

MODE=full
[[ "${1:-}" == "--share" ]] && MODE=share
OUT="CONTEXT-PACK.${MODE}.md"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

emit() { # emit <relative-path>
  local f="$1"
  [[ -f "$f" ]] || return 0
  printf '\n\n---\n\n<!-- FILE: %s -->\n\n' "$f" >>"$TMP"
  cat "$f" >>"$TMP"
}

emit_dir() { # emit_dir <directory> — handles spaces in filenames
  local d="$1"
  [[ -d "$d" ]] || return 0
  find "$d" -name '*.md' -not -name 'README.md' -print0 | sort -z |
    while IFS= read -r -d '' f; do emit "$f"; done
}

banner() { printf '\n\n# ======== %s ========\n' "$1" >>"$TMP"; }

# Pack header: a system prompt for the receiving chat LLM.
cat >>"$TMP" <<EOF
You are ${WIKI_ROLE}. The text below is a personal, LLM-maintained wiki
("${WIKI_NAME}"), generated $(date +%Y-%m-%d), mode=${MODE}.

- Answer using ONLY the information below plus clearly-labelled general knowledge.
  Cite the page heading you used.
- Keep three things separate and labelled: (1) official/external rules, (2) facts we
  gave you, (3) your own inferences.
- This is planning support, not professional advice. Facts were captured on the dates
  shown and may be stale. Dates are YYYY-MM-DD; "today" is around the generated date.
EOF

banner "SCHEMA / CONVENTIONS"; emit "AGENTS.md"
banner "INDEX";                emit "wiki/index.md"
for entry in "${SECTIONS[@]}"; do
  banner "${entry%%|*}"; emit_dir "${entry#*|}"
done

if [[ "$MODE" == "full" ]]; then
  if [[ -n "$PERSONAL_NOTES_DIR" ]]; then
    banner "ACCESS-CONTROLLED NOTES"; emit_dir "$PERSONAL_NOTES_DIR"
  fi
  if [[ -n "$PERSONAL_EVIDENCE_DIR" && -d "$PERSONAL_EVIDENCE_DIR" ]]; then
    banner "ACCESS-CONTROLLED EVIDENCE FILES (manifest only)"
    {
      printf '\nThese binary documents exist locally but cannot be inlined as text.\n'
      printf 'If we ask about one, ask us to upload it directly.\n\n'
      find "$PERSONAL_EVIDENCE_DIR" -type f \
        \( -name '*.pdf' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' \) \
        -print0 | sort -z | while IFS= read -r -d '' f; do printf -- '- `%s`\n' "$f"; done
    } >>"$TMP"
  fi
fi

mv "$TMP" "$OUT"
trap - EXIT
WORDS=$(wc -w <"$OUT" | tr -d ' ')
echo "Wrote $OUT ($WORDS words, mode=$MODE)"
