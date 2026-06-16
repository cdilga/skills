# Onboarding Study

Load when `squint-onboard` needs repo context, history, review culture, or likely
bug classes. Study only what can change the requested output.

## Sources

- Existing instructions/docs: `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`,
  `.github/instructions/*`, `CONTRIBUTING.md`, `README.md`, ownership/test docs.
- Mechanics: build/lint/test commands from instructions first, then package files
  and CI. Run safe checks only when useful or requested; see `local-validation.md`.
- History: churn hotspots, reverted PRs, hotfixes, incident-linked commits, long
  review threads.
- Review culture: recent reviews by the requesting reviewer, else recent merged
  PR threads.
- Prior agent/session history: any available search capability; skip if absent.
- Trackers/docs only when the repo points to them and access exists. Keep high
  value durable docs by summary/link; do not turn onboarding into a copied
  knowledge base.

## Useful Commands

```bash
gh auth status
gh api user --jq .login
gh api repos/<owner>/<repo> --jq '{permissions, default_branch, archived}'
git log --since=6.months --name-only --pretty=format: | sort | uniq -c | sort -rn | head -20
gh search prs --repo <owner>/<repo> --reviewed-by @me --state all --limit 50 --json number,title,url
```

## Distill

- commands and whether they were run, inferred, heavy, flaky, or unsafe
- ownership/CODEOWNERS paths and review authority
- architecture map and load-bearing modules
- risk/invariant register
- likely bug classes and review lenses
- review voice and verdict habits
- source log with stable links/identifiers
