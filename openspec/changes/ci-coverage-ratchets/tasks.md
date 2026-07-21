<!--
  [P] marks tasks eligible for parallel execution.
  Add [P] when a task: (a) touches different files from
  other [P] tasks in the group, (b) has no dependency
  on prior tasks in the group, (c) can safely execute
  without ordering constraints.
  Do NOT add [P] when tasks modify the same file —
  parallel workers will cause merge conflicts.
  Tasks without [P] run sequentially first, then [P]
  tasks run in parallel.
-->

## 1. Update CI Workflow

- [x] 1.1 In `.github/workflows/ci.yml`, add `-coverprofile=coverage.out`
  to the `Test` step's `run:` command. The full command MUST be:
  `go test ./... -count=1 -race -coverprofile=coverage.out`. Verify step
  ordering remains: Checkout → Setup Go → Vet → Govulncheck → Test → Enforce
  Coverage Ratchets → Build.

  **Files**: `.github/workflows/ci.yml`

- [x] 1.2 In `.github/workflows/ci.yml`, add an `Enforce Coverage Ratchets`
  step after the `Test` step and before the `Build` step. The step MUST:
  (a) first verify `coverage.out` exists and is non-empty — if missing or
  empty, emit `::error::No coverage profile found` and `exit 1` immediately,
  (b) extract global coverage from `go tool cover -func=coverage.out | grep
  '^total:'`, (c) compare against 55.0% using `bc -l`, (d) emit a
  `::error::` annotation and `exit 1` if below threshold, (e) iterate over
  all 11 package-level thresholds from design.md D2, compute each package's
  average function coverage by grepping `github.com/unbound-force/replicator/<pkg>`
  lines and averaging with `awk`, (f) emit a `::error::` annotation and
  `exit 1` for any breach, (g) print a summary line for each package whether
  passing or failing, (h) print "All coverage ratchets passed." on success.

  **Files**: `.github/workflows/ci.yml`

## 2. Update Makefile

- [x] 2.1 [P] In `Makefile`, update the `test` target to run:
  `go test ./... -count=1 -race -coverprofile=coverage.out`. Add `-race` and
  `-coverprofile=coverage.out` to the existing command. This aligns `make test`
  with CI.

  **Files**: `Makefile`

- [x] 2.2 [P] In `Makefile`, add a `coverage` target after `test`:
  ```
  coverage:
  	go test ./... -count=1 -race -coverprofile=coverage.out
  	go tool cover -func=coverage.out
  ```
  Add `coverage` to the `.PHONY` line.

  **Files**: `Makefile`

## 3. Documentation

- [x] 3.1 [P] Update `AGENTS.md` Commands table to add the `make coverage`
  target with description "Run tests with race detection and print coverage
  report".

  **Files**: `AGENTS.md`

## 4. Verification

- [x] 4.1 Run `make coverage` locally and confirm: (a) global coverage
  reported is ≥ 55%, (b) all 11 package thresholds are satisfied, (c)
  `coverage.out` is produced and not tracked by git.

- [x] 4.2 Manually execute the enforcement shell script logic from task 1.2
  against the generated `coverage.out` and confirm all ratchets pass with
  current coverage baseline (global 58.4%, all packages above their floors).

- [x] 4.3 Verify the updated `ci.yml` YAML is valid: step names are correct,
  `run:` blocks are properly indented, enforcement step is inside the
  `build-and-test` job, and step order matches the spec.

- [x] 4.4 Verify constitution alignment: confirm Composability First (PASS —
  no new external dependencies, `bc` is standard on ubuntu-latest),
  Observable Quality (PASS — `::error::` annotations are machine-readable),
  Autonomous Collaboration (N/A — no MCP tool changes), Testability
  (N/A — CI YAML is not unit-testable in isolation).

<!-- spec-review: passed -->

<!-- code-review: passed -->
