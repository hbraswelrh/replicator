## Why

The `checkDewey()` function in `internal/doctor/checks.go` sends an HTTP GET
to the Dewey MCP endpoint (`http://localhost:3333/mcp/`). The MCP Streamable
HTTP transport only accepts POST for JSON-RPC calls; a plain GET without SSE
headers returns HTTP 400 or 405. This causes the doctor check to report a
spurious warning ("Dewey returned HTTP 400") even when Dewey is healthy and
running.

Fixes: https://github.com/unbound-force/replicator/issues/16

## What Changes

Replace the raw `http.Client.Get()` call in `checkDewey()` with a call to the
existing `memory.NewClient(deweyURL).Health()` method, which sends a proper
JSON-RPC 2.0 POST to the `dewey_health` endpoint. Update tests to use a
JSON-RPC-aware mock server instead of a simple HTTP handler.

## Capabilities

### New Capabilities

- None

### Modified Capabilities

- `doctor/checkDewey`: Uses JSON-RPC POST via `memory.Client.Health()` instead
  of raw HTTP GET, correctly probing the Dewey MCP endpoint.

### Removed Capabilities

- None

## Impact

- `internal/doctor/checks.go` — `checkDewey()` function rewritten to use
  `memory.Client`.
- `internal/doctor/checks_test.go` — Dewey-related tests updated with
  JSON-RPC mock handlers.
- No changes to the `memory` package itself; it already has the correct
  `Health()` implementation.

## Constitution Alignment

Assessed against the Replicator constitution (`.specify/memory/constitution.md`),
which extends the Unbound Force org constitution v1.1.0.

### I. Autonomous Collaboration

**Assessment**: PASS

The doctor check continues to produce self-describing JSON results with name,
status, message, and duration. No inter-tool coupling is introduced — the
`memory.Client` is used as a standalone HTTP client, not as a runtime
dependency on another tool.

### II. Composability First

**Assessment**: PASS

Dewey remains optional. The check still returns "warn" (not "fail") when Dewey
is unreachable. The `memory.UnavailableError` is used to detect connection
failures, preserving graceful degradation.

### III. Observable Quality

**Assessment**: PASS

All doctor check results remain machine-parseable JSON. The fix eliminates a
false-positive warning, improving the accuracy of the doctor report output.

### IV. Testability

**Assessment**: PASS

Tests use `httptest.NewServer` with JSON-RPC mock handlers — no external
services required. The existing `db.OpenMemory()` pattern for database tests
is unchanged.
