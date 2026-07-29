#!/usr/bin/env bash
# qmd.sh — locked, scope-limited wrapper around the qmd CLI for this wiki.
#
# Why a wrapper: (1) concurrent agents corrupt qmd's SQLite vector index
# ("sqlite-vec probe failed (database is locked)"), so all access is serialized
# through a lock; (2) every search is auto-scoped to this wiki's collections so an
# agent can't accidentally query unrelated indexes.
#
# Usage: scripts/qmd.sh {status|update|search|query|vsearch|get|multi-get|ls|raw} [args]
#   update       run after every editing session (qmd update + embed)
#   search ...   lexical/hybrid search, scoped to the collections below
#   raw ...      escape hatch: pass args straight to qmd (still under the lock)
set -euo pipefail

# ── Customize for this wiki ─────────────────────────────────────────────────────
INDEX_NAME="${QMD_INDEX_NAME:-my-wiki}"
# One collection per wiki area. Never add raw/personal, the repo root, or the
# generated context packs — the index would poison itself on its own output.
COLLECTIONS=(wiki-index wiki-log topics questions source-summaries raw-sources)
# ────────────────────────────────────────────────────────────────────────────────

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
LOCK_FILE="${QMD_LOCK_FILE:-${TMPDIR:-/tmp}/${INDEX_NAME}-qmd.lock}"

if ! command -v qmd >/dev/null 2>&1; then
  echo "qmd not found. Install: npm install -g @tobilu/qmd" >&2
  exit 127
fi

cmd="${1:-status}"; shift || true

# Serialize through the lock (macOS: lockf; Linux: flock). Re-exec once with the
# lock held; QMD_LOCK_HELD prevents infinite recursion.
if [[ -z "${QMD_LOCK_HELD:-}" ]]; then
  if command -v lockf >/dev/null 2>&1; then
    exec env QMD_LOCK_HELD=1 lockf -k "$LOCK_FILE" "$SCRIPT_PATH" "$cmd" "$@"
  elif command -v flock >/dev/null 2>&1; then
    exec env QMD_LOCK_HELD=1 flock "$LOCK_FILE" "$SCRIPT_PATH" "$cmd" "$@"
  else
    echo "warning: no lockf/flock; proceeding unserialized" >&2
  fi
fi

collection_flags() {
  local flags=()
  for c in "${COLLECTIONS[@]}"; do flags+=(-c "$c"); done
  printf '%s\n' "${flags[@]}"
}

case "$cmd" in
  status)
    qmd --index "$INDEX_NAME" status ;;
  update)
    qmd --index "$INDEX_NAME" update
    qmd --index "$INDEX_NAME" embed --max-docs-per-batch 50 ;;
  search|query|vsearch)
    mapfile -t cflags < <(collection_flags) 2>/dev/null || cflags=($(collection_flags))
    qmd --index "$INDEX_NAME" "$cmd" "$@" "${cflags[@]}" ;;
  get|multi-get|ls)
    qmd --index "$INDEX_NAME" "$cmd" "$@" ;;
  raw)
    qmd --index "$INDEX_NAME" "$@" ;;
  *)
    echo "unknown subcommand: $cmd" >&2
    echo "usage: $0 {status|update|search|query|vsearch|get|multi-get|ls|raw} [args]" >&2
    exit 2 ;;
esac
