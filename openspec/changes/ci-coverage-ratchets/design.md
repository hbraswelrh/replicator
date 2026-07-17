## Context

Replicator's `ci.yml` runs `go test ./... -count=1 -race` but never generates
a coverage profile. The constitution (Principle IV: Testability) requires that
coverage regressions be treated as test failures. The canonical org reference
(`unbound-force/unbound-force/.github/workflows/ci_local.yml`) demonstrates
the accepted pattern: generate a profile with `-coverprofile`, parse it with
`go tool cover -func`, and enforce thresholds in shell using `bc -l` for
floating-point comparisons.

Current coverage baseline (measured 2026-07-17):

| Package | Coverage |
|---------|----------|
| `internal/memory` | 90.2% |
| `internal/query` | 88.6% |
| `internal/doctor` | 88.4% |
| `internal/forge` | 88.4% |
| `internal/stats` | 87.0% |
| `internal/comms` | 86.8% |
| `internal/org` | 86.5% |
| `internal/agentkit` | 85.7% |
| `internal/gitutil` | 84.3% |
| `internal/ui` | 81.2% |
| `internal/mcp` | 76.1% |
| `test/parity` | 64.8% |
| `internal/db` | 34.6% |
| `cmd/replicator` | 24.4% |
| `internal/config` | 0.0% |
| `internal/tools/*` | 0.0% |
| **Global** | **58.4%** |

## Goals / Non-Goals

### Goals

- Generate `coverage.out` on every CI run
- Enforce a global coverage floor of 55% (3.4pp below current, prevents major
  regressions without blocking PRs)
- Enforce package-level floors on the 11 packages already above 70%
- Align `make test` with CI (add `-race -coverprofile=coverage.out`)
- Add `make coverage` for local developer inspection

### Non-Goals

- Raising coverage on low-coverage packages (`tools/*`, `config`, `db`,
  `cmd/replicator`) — tracked by a separate issue
- Coverage badges, HTML reports, or PR comments — out of scope
- Changing the `release.yml` preflight — it already gates on `Build and Test`
- Setting ratchets at or near current values — ratchets are floors, not targets

## Decisions

### D1: Global threshold at 55%

Current global coverage is 58.4%. Setting the floor at 55% leaves a 3.4
percentage-point buffer. This is intentional: ratchets protect against
regressions, not enforce a target. As coverage improves through the related
issue, the threshold will be raised incrementally.

Setting the floor at 80% (the org canonical for `unbound-force/unbound-force`)
would require the low-coverage packages (`tools/*`, `config`, `db`) to be
addressed first, which is a separate workstream.

### D2: Package-level thresholds set 5–8pp below current values

| Package | Current | Threshold | Buffer |
|---------|---------|-----------|--------|
| `internal/memory` | 90.2% | 85% | 5.2pp |
| `internal/query` | 88.6% | 80% | 8.6pp |
| `internal/doctor` | 88.4% | 80% | 8.4pp |
| `internal/forge` | 88.4% | 80% | 8.4pp |
| `internal/stats` | 87.0% | 80% | 7.0pp |
| `internal/comms` | 86.8% | 80% | 6.8pp |
| `internal/org` | 86.5% | 80% | 6.5pp |
| `internal/agentkit` | 85.7% | 80% | 5.7pp |
| `internal/gitutil` | 84.3% | 80% | 4.3pp |
| `internal/ui` | 81.2% | 75% | 6.2pp |
| `internal/mcp` | 76.1% | 70% | 6.1pp |

Buffers are generous enough to survive minor refactoring but tight enough to
catch deliberate test deletion.

### D3: Excluded packages receive no ratchet

`internal/tools/*` (0%), `internal/config` (0%), `internal/db` (34.6%),
`cmd/replicator` (24.4%), and `test/parity` (64.8%) are excluded from
package-level ratchets. Including them would either require impossibly high
starting values or provide no protection. They are tracked for improvement
separately. The global 55% floor still catches catastrophic regressions across
the whole codebase.

### D4: Coverage parsing uses `go tool cover -func` + `bc -l`

The canonical pattern greps per-function lines by package path, extracts the
trailing percentage, and averages with `awk`. Floating-point comparison uses
`bc -l` which is available on `ubuntu-latest` by default. This is identical
to the approach in `unbound-force/unbound-force/ci_local.yml` and requires
no additional tooling.

```bash
# Global
GLOBAL_COV=$(go tool cover -func=coverage.out \
  | grep '^total:' \
  | awk '{print substr($3, 1, length($3)-1)}')

# Per-package (example: internal/org)
PKG_COV=$(go tool cover -func=coverage.out \
  | grep 'github.com/unbound-force/replicator/internal/org' \
  | awk '{print substr($3, 1, length($3)-1)}' \
  | awk '{t+=$1; c++} END {if(c>0) printf "%.1f", t/c; else print "0.0"}')
```

### D5: Makefile `test` gains `-race` and `-coverprofile`

The existing `test` target runs without `-race`, which diverges from CI. This
change aligns them. Developers running `make test` will now get race detection
and a `coverage.out` file as a side-effect. `coverage.out` is already in
`.gitignore`.

### D6: No changes to `release.yml`

The release preflight already gates on the `Build and Test` check name. Adding
the coverage enforcement step to that existing job means failures automatically
block releases with no further change needed.

## Risks / Trade-offs

**Risk**: `bc` is not installed on the CI runner.
**Mitigation**: `bc` is part of the `bc` package, installed by default on
`ubuntu-latest`. The canonical org workflows rely on it without an explicit
install step.

**Risk**: A legitimate refactoring removes a tested function, causing an
unexpected ratchet breach.
**Mitigation**: Thresholds are set well below current values. Intentional
coverage decreases should be accompanied by new tests; if a refactoring
genuinely reduces testable surface, the threshold can be updated in the same
PR.

**Risk**: `make test` generating `coverage.out` adds latency locally.
**Mitigation**: Negligible. Profile generation is I/O, not CPU. The file is
small and already gitignored.

**Risk**: A protected package is renamed or removed, causing its coverage
grep to match zero lines and the awk averaging to report 0.0%, which would
fail the ratchet with a confusing "0.0% < N%" error.
**Mitigation**: The enforcement script's awk snippet already handles the
zero-lines case explicitly (`else print "0.0"`). When renaming or removing
a protected package, the ratchet table in `ci.yml` MUST be updated in the
same PR to remove or rename the entry. This is a process constraint, not a
code constraint.
