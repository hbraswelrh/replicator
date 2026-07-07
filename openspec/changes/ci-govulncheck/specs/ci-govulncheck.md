## ADDED Requirements

### Requirement: CI vulnerability scanning

The CI pipeline MUST run `govulncheck ./...` on every push to `main` and every
pull request targeting `main`. The CI job MUST fail if `govulncheck` reports any
known vulnerabilities in dependencies reachable from the binary's call graph.

#### Scenario: Clean dependency tree

- **GIVEN** all Go dependencies are free of known vulnerabilities
- **WHEN** CI runs `govulncheck ./...`
- **THEN** the step exits with code 0 and CI proceeds to subsequent steps

#### Scenario: Vulnerable dependency detected

- **GIVEN** a Go dependency has a known vulnerability in a code path used by
  replicator
- **WHEN** CI runs `govulncheck ./...`
- **THEN** the step exits with a non-zero code, the `Build and Test` job fails,
  and the vulnerability details are visible in the CI log output

#### Scenario: Vulnerability in unused code path

- **GIVEN** a Go dependency has a known vulnerability but replicator does not
  call any affected functions
- **WHEN** CI runs `govulncheck ./...`
- **THEN** `govulncheck` reports the vulnerability as informational but does
  NOT fail the step (govulncheck's default behavior is call-graph-aware)

### Requirement: Govulncheck step ordering

The `govulncheck` step MUST run after `Vet` and before `Test` in the CI job.
This ensures vulnerabilities are detected early without delaying faster static
analysis checks.

#### Scenario: Step execution order

- **GIVEN** the CI workflow is triggered
- **WHEN** the `Build and Test` job executes
- **THEN** steps run in order: Checkout, Setup Go, Vet, Govulncheck, Test, Build

### Requirement: Release gated on vulnerability scan

The release preflight MUST NOT allow a release if the `Build and Test` CI check
has not passed. Since `govulncheck` is a step within the `Build and Test` job,
a vulnerability failure blocks the release through the existing preflight
mechanism.

#### Scenario: Release blocked by vulnerability

- **GIVEN** the most recent CI run on HEAD failed due to a `govulncheck` finding
- **WHEN** a release is triggered via `workflow_dispatch`
- **THEN** the preflight job fails with an error indicating the `Build and Test`
  check has not passed

#### Scenario: Release proceeds after vulnerability is resolved

- **GIVEN** a vulnerability was detected, the dependency was updated, and CI
  passed on the fix commit
- **WHEN** a release is triggered via `workflow_dispatch`
- **THEN** the preflight job succeeds and the release proceeds

### Requirement: Check name documentation

The CI check name (`Build and Test`) MUST be documented in `AGENTS.md` so that
agents and the release preflight can reference it consistently.

#### Scenario: Documented check name matches CI

- **GIVEN** the CI workflow defines a job named `Build and Test`
- **WHEN** an agent or the release preflight queries the check name
- **THEN** the documented name in `AGENTS.md` matches the actual CI job name

## MODIFIED Requirements

None. This change adds new CI capabilities without modifying existing
requirements.

## REMOVED Requirements

None. No existing requirements are removed by this change.
