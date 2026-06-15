## Context

The `checkDewey()` function in `internal/doctor/checks.go` uses a raw HTTP GET
to probe the Dewey MCP endpoint. The MCP Streamable HTTP transport only accepts
POST for JSON-RPC calls. This causes a false-positive warning even when Dewey
is healthy.

The codebase already has a correct JSON-RPC health probe in
`internal/memory/proxy.go` — `Client.Health()` sends a JSON-RPC 2.0 POST to
the `dewey_health` method. The doctor check should reuse this.

## Goals / Non-Goals

### Goals

- Eliminate the false-positive Dewey warning by using a proper JSON-RPC POST
  health probe.
- Reuse the existing `memory.Client.Health()` method — no new HTTP client code.
- Maintain the existing pass/warn semantics (Dewey is optional, failure is a
  warning).
- Update tests to verify JSON-RPC POST behavior.

### Non-Goals

- Refactoring the `memory.Client` API or changing its timeout configuration.
- Adding new doctor checks or changing check ordering.
- Modifying the `checkDewey` function signature or `CheckResult` struct.

## Decisions

### D1: Reuse `memory.Client` instead of crafting a standalone POST

The `memory.Client` already has `Health()` which sends a correct JSON-RPC 2.0
POST. Introducing a second HTTP client or a manual POST would violate DRY and
risk divergence. This aligns with **Composability First** — reusing existing
components rather than duplicating logic.

### D2: Treat all `Health()` errors uniformly as warnings

The `memory.Client.Health()` method returns `*memory.UnavailableError` when
Dewey is unreachable (connection refused, timeout) and a generic error for
JSON-RPC failures. Since both cases produce the same `Status: "warn"` outcome
(Dewey is always optional), `checkDewey` treats any error from `Health()`
uniformly without distinguishing error types via `errors.As`. This keeps the
implementation simple and aligns with **Composability First** — Dewey failure
is always a warning, never a blocker.

### D3: Accept default 10-second timeout for doctor context

The `memory.Client` uses a 10-second timeout by default. For the doctor check,
we create a `memory.NewClient()` and accept the default timeout since the
doctor is not latency-sensitive and consistency with other memory operations
is more valuable than saving 5 seconds in the worst case.

## Risks / Trade-offs

- **Import coupling**: `internal/doctor` now imports `internal/memory`. This is
  acceptable because the doctor's purpose is to check component health, and
  `memory` is the component that owns the Dewey connection logic. The coupling
  is directional (doctor depends on memory, not the reverse).
- **Test complexity**: JSON-RPC mock handlers are slightly more complex than a
  bare HTTP 200 handler. This is a worthwhile trade-off for test accuracy — the
  tests now verify the actual protocol used in production.
