# cass First-Time Setup

Install: `curl -fsSL https://raw.githubusercontent.com/coding-agent-search/cass/main/install.sh | sh`
Or via Homebrew tap: `brew install Dicklesworthstone/tap/cass`

## 1. Build the index
```bash
cass index          # indexes all detected agent sessions (~1–5 min first time)
cass index --full   # force full rebuild if something looks stale
```
Progress is logged. Safe to interrupt and resume.

## 2. Install the semantic model (CRITICAL — do this or search quality is silently degraded)
```bash
cass models status          # check: ✗ onnx/model.onnx = NOT installed
cass model install          # downloads all-MiniLM-L6-v2 (~86MB)
cass models status          # verify ALL files show ✓
```
Without `onnx/model.onnx`, cass silently falls back to lexical-only search. You will not be told. Recall on conceptual queries will be much worse.

## 3. Verify health
```bash
cass health                 # fast liveness check
cass status --json          # structured: index freshness, db stats
cass diag --json            # detailed diagnostics (safer than doctor)
cass capabilities --json    # confirm features available
```

## 4. Known issues to be aware of (do NOT try to fix these)
- `cass doctor` falsely reports `fts_messages` missing — **known bug #117**. If `cass search` returns results, ignore it.
- `cass doctor --fix` **corrupts the DB** — do not run it. Use `cass diag` instead.
- `cass analytics` / `cass robot-docs` / `cass models` with no args → "Could not parse arguments" — **known bug #118**. Always pass a subcommand or `--help`.

## 5. Shell completions (optional)
```bash
cass completions zsh >> ~/.zshrc    # or bash/fish
```
