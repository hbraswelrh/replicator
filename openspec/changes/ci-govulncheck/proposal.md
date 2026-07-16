## Why

Replicator has no security scanning in its CI pipeline. Issue #15 identified
this gap, and issue #23 specifically tracks adding `govulncheck` to scan for
known vulnerabilities in Go dependencies. The existing CI workflow
(`.github/workflows/ci.yml`) runs `go vet`, `go test`, and `go build` but
performs no vulnerability analysis.

The canonical org reference (`unbound-force/unbound-force`) runs OSV-Scanner
and Trivy source scans via `ci_security.yml`. At minimum, replicator should
run `govulncheck` -- the official Go vulnerability scanner maintained by the
Go team -- as part of CI.

The release preflight (added in the `ci-release-preflight` change) was
explicitly designed to be extended with a security scan check once one exists.
Adding `govulncheck` to CI closes that gap.

Fixes: https://github.com/unbound-force/replicator/issues/23
Parent: https://github.com/unbound-force/replicator/issues/15

## What Changes

1. **`.github/workflows/ci.yml`**: Add a `govulncheck` step that runs
   `govulncheck ./...` after the existing `Vet` step. The step installs
   `govulncheck` via `go install golang.org/x/vuln/cmd/govulncheck@latest`
   and scans all packages. CI fails if known vulnerabilities are found.

2. **Release gating**: Since `govulncheck` runs as a step within the existing
   `Build and Test` job, no changes to `release.yml` are needed. If
   `govulncheck` fails, the `Build and Test` job fails, and the release
   preflight already blocks the release through its existing
   `REQUIRED_CHECKS` array.

3. **Documentation**: Update `AGENTS.md` to document that the `Build and Test`
   CI check now includes `govulncheck` vulnerability scanning.

## Capabilities

### New Capabilities

- `ci/govulncheck`: Automated vulnerability scanning of Go dependencies
  using the official `govulncheck` tool, integrated into the CI pipeline.

### Modified Capabilities

- `release/preflight`: No direct changes needed. The preflight already
  gates releases on the `Build and Test` check, which now includes
  `govulncheck` as a step. Vulnerability failures block releases
  through the existing mechanism.

### Removed Capabilities

- None

## Impact

- `.github/workflows/ci.yml` -- new `govulncheck` step added
- `.github/workflows/release.yml` -- no changes needed; the existing
  preflight already gates on `Build and Test`
- CI will now fail on PRs and pushes to main if `govulncheck` detects
  known vulnerabilities in dependencies
- Releases will be blocked if the security scan has not passed on HEAD

## Constitution Alignment

Assessed against the Replicator constitution (`.specify/memory/constitution.md`),
which extends the Unbound Force org constitution v1.1.0.

### I. Autonomous Collaboration

**Assessment**: N/A

This change modifies CI/CD workflow files only. No MCP tools, inter-agent
communication, or tool outputs are affected. The change is purely
infrastructure-level and does not alter how heroes collaborate through
artifacts.

### II. Composability First

**Assessment**: PASS

The binary remains independently installable and usable without any external
services. `govulncheck` is a CI-only tool that does not affect the standalone
functionality of the replicator binary. Dewey integration and graceful
degradation are unaffected.

### III. Observable Quality

**Assessment**: PASS

`govulncheck` produces structured output identifying specific CVEs, affected
packages, and call stacks. CI step output is visible in GitHub Actions logs
with clear pass/fail status. The check name is documented so the release
preflight can query it via the Checks API, maintaining machine-parseable
quality signals.

### IV. Testability

**Assessment**: N/A

This change modifies GitHub Actions workflow files which cannot be tested in
isolation (they require the GitHub Actions runtime). No Go source code, tests,
or testable components are modified. Post-merge verification will be performed
by observing the new `govulncheck` step in CI runs.
