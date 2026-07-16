<!--
  [P] marks tasks eligible for parallel execution.
  Add [P] when a task: (a) touches different files from
  other [P] tasks in the group, (b) has no dependency
  on prior tasks in the group, (c) can safely execute
  without ordering constraints.
  Do NOT add [P] when tasks modify the same file --
  parallel workers will cause merge conflicts.
  Tasks without [P] run sequentially first, then [P]
  tasks run in parallel.
-->

## 1. Add govulncheck to CI

- [x] 1.1 Add a `Govulncheck` step to `.github/workflows/ci.yml` after the
  `Vet` step and before the `Test` step. The step MUST run
  `go install golang.org/x/vuln/cmd/govulncheck@latest` then
  `govulncheck ./...`. Verify step ordering matches the spec:
  Checkout, Setup Go, Vet, Govulncheck, Test, Build.

  **Files**: `.github/workflows/ci.yml`

## 2. Documentation

- [x] 2.1 [P] Update `AGENTS.md` to document that the existing `Build and
  Test` CI check now includes `govulncheck` vulnerability scanning as a
  step. No new check name is introduced -- govulncheck runs within the
  existing job. Add a note under the Commands section or CI-related
  documentation.

  **Files**: `AGENTS.md`

## 3. Verification

- [x] 3.1 Verify constitution alignment: confirm the change satisfies the
  proposal's constitution assessment (N/A for Autonomous Collaboration,
  PASS for Composability First, PASS for Observable Quality, N/A for
  Testability). Verify no MCP tools, binary behavior, or test isolation
  are affected.

- [x] 3.2 Run `govulncheck ./...` locally to confirm the current dependency
  tree is clean and the new CI step will pass. If vulnerabilities are found,
  document them and update dependencies before merging.

- [x] 3.3 Verify the CI workflow YAML is valid by reviewing step names, `run:`
  blocks, and indentation. Confirm the step is within the existing
  `build-and-test` job (not a separate job).
<!-- spec-review: passed -->
<!-- code-review: passed -->
