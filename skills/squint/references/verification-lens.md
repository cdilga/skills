# Verification lens

Load this when `squint-deeper` chooses the verification lens or the user steers
toward testing.

Verify behavior, not implementation trivia. A missing test is a finding only
when it protects a meaningful risk. Match the tactic to the code shape, project
maturity, time budget, and existing tooling.

## Ladder

1. Existing focused checks: targeted tests, type checks, linters, CI failures.
2. Example/regression tests from the PR, bug report, issue, or finding.
3. Parameter and boundary tables: roles, states, null/empty/max, time zones,
   retries, flags, permission combinations.
4. Property checks: round-trip, idempotence, ordering, conservation,
   normalization, no-crash.
5. Metamorphic checks: related inputs where a relation must hold.
6. Differential checks: old/new path, reference library, previous API version.
7. Stateful/model-based checks for workflows, queues, retries, lifecycle states.
8. Fuzzing/corpus tests for parsers, serializers, query builders, protocols,
   file formats, user-controlled text, native boundaries.
9. Fault/concurrency injection: timeouts, partial failure, duplicates,
   reordering, cancellation, rollback.
10. Mutation-style reasoning: would the test fail if the operator/guard/branch
    were wrong?

## Fit matrix

- Pure transformation or validation: table, property, metamorphic, differential.
- Parser/serializer/wire format: round-trip, malformed corpus, fuzzing, goldens.
- Authorization/security gate: positive and negative permission matrix,
  tenant/user boundary checks.
- Migration/backfill: legacy fixtures, idempotence, partial-run resume,
  rollback/restore, volume.
- Queue/job worker: duplicate/out-of-order delivery, timeout, poison message,
  idempotence.
- Public API/SDK: compatibility, old clients, optional vs required fields,
  error-shape stability.
- State machine/workflow: transition table, impossible transitions, replay,
  concurrent actors.
- Search/ranking/LLM/heuristic output: curated evals, metamorphic relations,
  regression snapshots with tolerance, provenance checks.
- Performance-sensitive path: representative workload, query/allocation count,
  timeout budgets, cache correctness.

## Steps

1. Classify the changed-code shape and riskiest assumptions.
2. Identify the oracle: exact output, invariant, relation, persisted state,
   event, metric, schema, crash/sanitizer, or approved golden.
3. Check existing coverage and nearby tests for vacuous assertions.
4. Run only safe, useful checks; propose unsafe or heavy checks instead.
5. Recommend the smallest high-signal additions with setup, inputs, oracle, and
   why they catch the risk.
