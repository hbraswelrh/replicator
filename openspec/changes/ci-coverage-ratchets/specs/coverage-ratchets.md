## ADDED Requirements

### Requirement: CI Coverage Profile Generation

The CI `Test` step MUST generate a coverage profile by passing
`-coverprofile=coverage.out` to `go test`. The profile MUST cover all
packages (`./...`).

#### Scenario: Test step generates coverage profile

- **GIVEN** a CI run triggered by a push or pull request to `main`
- **WHEN** the `Test` step executes
- **THEN** a `coverage.out` file is produced in the working directory
  containing coverage data for all packages

---

### Requirement: Coverage Profile Guard

Before parsing any coverage data, the `Enforce Coverage Ratchets` step
MUST verify that `coverage.out` exists and is non-empty. If the file is
missing or empty, the step MUST emit a `::error::` annotation stating that
no coverage profile was found and exit with a non-zero status. This guard
ensures a clear, actionable failure message if the `Test` step produced no
output (e.g., due to a build error that is otherwise suppressed).

#### Scenario: Coverage profile is missing

- **GIVEN** the `Test` step did not produce `coverage.out`
- **WHEN** the `Enforce Coverage Ratchets` step begins
- **THEN** the step emits a `::error::` annotation stating the profile is
  missing and exits with a non-zero status before attempting any threshold
  checks

---

### Requirement: Global Coverage Floor Enforcement

CI MUST enforce a global coverage floor of 55%. If the measured global
coverage falls below 55%, the `Build and Test` job MUST fail with a
descriptive `::error::` annotation.

#### Scenario: Global coverage meets threshold

- **GIVEN** a `coverage.out` profile has been generated
- **WHEN** the `Enforce Coverage Ratchets` step runs and global coverage
  is 55.0% or above
- **THEN** the global check passes and execution continues

#### Scenario: Global coverage breaches threshold

- **GIVEN** a `coverage.out` profile has been generated
- **WHEN** the `Enforce Coverage Ratchets` step runs and global coverage
  is below 55.0%
- **THEN** the step emits a `::error::` annotation identifying the actual
  coverage and the 55% threshold, and exits with a non-zero status

---

### Requirement: Package-Level Coverage Ratchets

CI MUST enforce per-package coverage floors for the following packages.
If any package's average function coverage falls below its threshold, the
`Build and Test` job MUST fail with a descriptive `::error::` annotation
naming the package.

| Package | Threshold |
|---------|-----------|
| `internal/memory` | 85% |
| `internal/query` | 80% |
| `internal/doctor` | 80% |
| `internal/forge` | 80% |
| `internal/stats` | 80% |
| `internal/comms` | 80% |
| `internal/org` | 80% |
| `internal/agentkit` | 80% |
| `internal/gitutil` | 80% |
| `internal/ui` | 75% |
| `internal/mcp` | 70% |

#### Scenario: Package coverage meets threshold

- **GIVEN** a `coverage.out` profile has been generated
- **WHEN** the `Enforce Coverage Ratchets` step evaluates a package and
  its average function coverage is at or above the package threshold
- **THEN** that package's check passes

#### Scenario: Package coverage breaches threshold

- **GIVEN** a `coverage.out` profile has been generated
- **WHEN** the `Enforce Coverage Ratchets` step evaluates a package and
  its average function coverage is below the package threshold
- **THEN** the step emits a `::error::` annotation identifying the package,
  its actual coverage, and its required threshold, and exits with a non-zero
  status

---

### Requirement: `make coverage` Local Target

The `Makefile` MUST provide a `coverage` target that runs the full test suite
with race detection and a coverage profile, then prints the function-level
coverage report to stdout. Developers SHOULD use this target to validate
ratchets locally before pushing.

#### Scenario: Developer runs `make coverage`

- **GIVEN** a developer is working locally with Go and the test suite present
- **WHEN** the developer runs `make coverage`
- **THEN** all tests execute with `-race -coverprofile=coverage.out` and
  `go tool cover -func=coverage.out` output is printed to stdout

## MODIFIED Requirements

### Requirement: `make test` Race Detection and Coverage

Previously: `go test ./... -count=1` (no race detection, no coverage).

The `make test` Makefile target MUST run `go test ./... -count=1 -race
-coverprofile=coverage.out` to align with CI. Race detection MUST be
enabled. A coverage profile MUST be generated as a side-effect.

#### Scenario: Developer runs `make test`

- **GIVEN** a developer runs `make test`
- **WHEN** the command executes
- **THEN** all tests run with race detection enabled and `coverage.out`
  is produced in the working directory

## REMOVED Requirements

None.
