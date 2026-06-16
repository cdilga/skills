# Local validation during reviews

Load this reference when the user asks to test locally, when a finding depends on
runtime behavior, or when the repo's own instructions make local validation cheap
and relevant.

## Gates

- If the user says `static only`, `just analyse statically`, or `no live testing`,
  do not run tests, dev servers, migrations, seeders, browsers, or service calls.
- If the user says `test locally`, `run it`, `boot the app`, or similar, make a
  local validation plan and run it when safe.
- Otherwise use judgment: run cheap targeted checks when they are likely to
  falsify a risky assumption; skip heavy, flaky, credentialed, destructive, or
  environment-dependent checks and say why. Favour correctness and data collection
  while reducing cost.

## Safety

- Never point review validation at production.
- Prefer local fixtures, throwaway databases, temporary directories, and explicit
  test env vars.
- Avoid commands that mutate tracked files. If a normal test command generates
  files, note them and do not commit them.
- For concurrent reviews, use unique ports and temp dirs; do not kill processes
  you did not start.
- Record server PIDs, ports, and logs under the squint state dir. Clean up
  processes you started before finishing unless the user asks to keep them.

## Useful validation

Good local review validation includes:

- targeted unit/integration tests near the changed code
- type checks or linters that the repo says are meaningful
- local dev server plus one focused browser/API check for UI or workflow changes
- a small reproduction script using local data
- inspecting generated output or logs from the changed path

Keep the report honest: separate what you actually ran from what you recommend.
