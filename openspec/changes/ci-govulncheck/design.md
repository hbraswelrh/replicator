## Context

Replicator's CI pipeline (`.github/workflows/ci.yml`) runs `go vet`, `go test`,
and `go build` but has no security vulnerability scanning. Issue #23 tracks
adding `govulncheck` -- the official Go vulnerability scanner maintained by the
Go security team -- to CI.

The release preflight (`release.yml`, added by the `ci-release-preflight` change)
was explicitly designed with an extensible `REQUIRED_CHECKS` array. Decision D5
in that change's design document notes: "When govulncheck is added (issue #23),
the preflight can be extended to verify it." This change fulfills that plan.

The canonical org reference (`unbound-force/unbound-force`) runs security scans
via a separate `ci_security.yml` workflow. For replicator's current scale
(single binary, modest dependency tree), adding `govulncheck` as a step within
the existing `ci.yml` is sufficient. A separate workflow can be introduced later
if additional scanners (OSV-Scanner, Trivy) are added.

## Goals / Non-Goals

### Goals

- Add a `govulncheck` step to `ci.yml` that fails CI when known vulnerabilities
  are found in dependencies.
- Document the check name so the release preflight can reference it.
- Extend the release preflight's `REQUIRED_CHECKS` to include the security
  scan check, gating releases on vulnerability-free dependencies.

### Non-Goals

- Adding OSV-Scanner or Trivy source scans -- those can follow if needed.
- Creating a separate `ci_security.yml` workflow -- not warranted for a single
  scanner at current scale.
- Adding `govulncheck` to the `Makefile` -- CI is the enforcement point; local
  usage is optional and left to developers.
- Modifying Go source code, tests, or the replicator binary.

## Decisions

### D1: Add govulncheck as a step in ci.yml, not a separate workflow

The canonical reference uses a dedicated `ci_security.yml` for security scans.
However, replicator has a single CI workflow with one job (`Build and Test`).
Adding `govulncheck` as a step within this job keeps CI simple and avoids a
separate workflow that would need its own `actions/checkout` and
`actions/setup-go` steps (duplicating setup time).

The step runs after `Vet` and before `Test`:

```yaml
- name: Govulncheck
  run: |
    go install golang.org/x/vuln/cmd/govulncheck@latest
    govulncheck ./...
```

This ordering means vulnerabilities are caught early (before the slower test
suite runs), while still benefiting from the Go toolchain already being set up.

**Trade-off**: If a separate `Security` check name is later needed (e.g., for
branch protection or release preflight granularity), the step would need to be
extracted into its own job. This is a straightforward refactor.

### D2: Install govulncheck via go install at latest

Using `go install golang.org/x/vuln/cmd/govulncheck@latest` ensures the
scanner always uses the most current vulnerability database definitions.
Unlike application dependencies, pinning the scanner version provides no
reproducibility benefit -- the vulnerability database is inherently
time-varying.

**Alternative considered**: Using the `golang/govulncheck-action` GitHub
Action. Rejected because:
- It adds another third-party action to pin and maintain.
- The `go install` + `govulncheck` approach is simpler and uses the same
  Go toolchain already set up by `actions/setup-go`.
- Direct invocation gives clearer control over flags and output.

### D3: Extend release preflight REQUIRED_CHECKS

The release preflight in `release.yml` verifies CI passed before allowing a
release. The `REQUIRED_CHECKS` array currently contains only `"Build and Test"`.
Since `govulncheck` runs as a step within the `Build and Test` job (not a
separate job), the check name remains `"Build and Test"` -- no change is needed
to the preflight's `REQUIRED_CHECKS` array.

If `govulncheck` fails, the `Build and Test` job fails, and the preflight
already blocks the release. This is the simplest integration path.

**Consequence**: The preflight does not distinguish between a test failure and a
vulnerability failure. Both block the release equally, which is the desired
behavior.

### D4: No Makefile changes

The `Makefile` currently defines `make check` as `vet + test`. Adding
`govulncheck` to the Makefile is tempting for local developer convenience, but:
- CI is the enforcement point for security scanning.
- Developers can run `govulncheck ./...` directly when needed.
- Adding it to `make check` would slow down the local development loop for a
  check that primarily matters at PR/release time.

If local scanning is later desired, a separate `make vuln` target can be added.

## Risks / Trade-offs

- **CI time increase**: `go install govulncheck@latest` adds ~5-10 seconds for
  download/install, plus ~5-15 seconds for scanning. Total CI impact is modest
  (~10-25 seconds) since the Go module cache is warm from `actions/setup-go`.

- **False positives from transitive dependencies**: `govulncheck` analyzes call
  graphs and only reports vulnerabilities in code paths actually used by the
  binary. This significantly reduces false positives compared to dependency-only
  scanners. However, if a transitive dependency has a vulnerability in a code
  path replicator uses, CI will fail even if the vulnerability is not
  exploitable in practice. The fix is to update the dependency or, as a last
  resort, document the exception.

- **Network dependency**: `go install govulncheck@latest` requires network
  access to download the tool and vulnerability database. GitHub-hosted runners
  have reliable network access, so this is low risk. If a network issue causes
  intermittent failures, retrying the CI job resolves it.

- **No version pinning**: Using `@latest` means the scanner version can change
  between CI runs. This is intentional -- newer versions have better detection.
  If a specific version introduces a regression, it can be pinned temporarily.

- **Gatekeeping note**: This change modifies CI configuration, which falls under
  the Gatekeeping Value Protection constraint in AGENTS.md. Adding a new
  security check (govulncheck) is an improvement to CI gates, not a relaxation.
  The proposal's constitution alignment confirms this is PASS for Observable
  Quality (machine-parseable vulnerability output with clear pass/fail status).
