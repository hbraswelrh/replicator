## Why

Replicator's CI pipeline runs `go test ./... -count=1 -race` but never
generates or enforces a coverage profile. This means a contributor could
delete a significant portion of the test suite and CI would still report
green. The constitution (Principle IV: Testability) is explicit:
"Coverage regressions MUST be treated as test failures."

The canonical org reference (`unbound-force/unbound-force/.github/workflows/
ci_local.yml`) enforces a global coverage floor and a package-level ratchet
for its most critical package. Replicator has no equivalent. Issue #24 tracks
this gap.

Current global coverage is 58.4%. Eleven packages already exceed 70% coverage
and are worth protecting. Without ratchets, that progress can erode silently.

Fixes: https://github.com/unbound-force/replicator/issues/24

## What Changes

1. **`.github/workflows/ci.yml`**: Add `-coverprofile=coverage.out` to the
   existing `Test` step. Add a new `Enforce Coverage Ratchets` step after
   `Test` that parses `go tool cover -func=coverage.out`, checks a global
   floor of 55%, and enforces per-package thresholds on 11 critical packages.
   CI fails with a `::error::` annotation if any ratchet is breached.

2. **`Makefile`**: Align the `test` target with CI by adding `-race` and
   `-coverprofile=coverage.out`. Add a `coverage` convenience target that runs
   tests and prints the full function-level coverage report, so developers can
   run the same checks locally before pushing.

3. **`AGENTS.md`**: Document the new `make coverage` target in the Commands
   section.

## Capabilities

### New Capabilities

- `ci/coverage-ratchets`: CI now generates a coverage profile on every run
  and enforces a global floor (55%) plus 11 package-level thresholds. Any
  regression below a threshold fails the `Build and Test` job.
- `make coverage`: Local convenience target that runs the full test suite
  with race detection and prints a function-level coverage report.

### Modified Capabilities

- `ci/build-and-test`: The existing `Test` step gains `-coverprofile=coverage.out`
  and `-race`. The job gains a new enforcement step after `Test`.
- `make test`: Gains `-race` and `-coverprofile=coverage.out` to match CI.

### Removed Capabilities

- None

## Impact

- `.github/workflows/ci.yml` -- `Test` step modified; `Enforce Coverage
  Ratchets` step added
- `Makefile` -- `test` target updated; `coverage` target added
- `AGENTS.md` -- Commands section updated
- `coverage.out` is already listed in `.gitignore` (line 17) -- no change
  needed
- PRs that drop coverage below any ratchet will fail CI; contributors will
  need to add tests before merging
- Release preflight already gates on `Build and Test` -- no changes to
  `release.yml`; coverage ratchet failures automatically block releases

## Constitution Alignment

Assessed against the Replicator constitution (`.specify/memory/constitution.md`),
which extends the Unbound Force org constitution v1.1.0.

### I. Autonomous Collaboration

**Assessment**: N/A

This change modifies CI workflow files and the Makefile only. No MCP tools,
tool outputs, inter-agent communication, or artifact schemas are affected.
The change is purely infrastructure-level and does not alter how heroes
collaborate through artifacts.

### II. Composability First

**Assessment**: PASS

The replicator binary remains independently installable and usable without
any external services. Coverage enforcement is a CI-only concern: `bc` and
`go tool cover` are standard Ubuntu and Go toolchain utilities that require
no additional dependencies. The Makefile `coverage` target works locally
without network access. Dewey integration and graceful degradation are
entirely unaffected.

### III. Observable Quality

**Assessment**: PASS

The enforcement step emits structured `::error::` GitHub Actions annotations
when a ratchet is breached, naming the specific package and the delta between
actual and required coverage. All other output is plain-text percentages
parseable by any consumer. The check runs within the existing `Build and Test`
job, so the release preflight's existing `REQUIRED_CHECKS` array continues to
gate releases on this check without modification.

### IV. Testability

**Assessment**: N/A

This change modifies GitHub Actions workflow files and the Makefile, which
cannot be tested in isolation (they require the GitHub Actions runtime or a
local shell respectively). No Go source code, package logic, or test isolation
patterns are modified. The enforcement shell script will be verified locally
by running `make coverage` and confirming thresholds pass before the PR is
merged.
