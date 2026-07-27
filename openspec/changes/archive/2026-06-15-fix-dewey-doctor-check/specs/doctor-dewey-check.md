## ADDED Requirements

None.

## MODIFIED Requirements

### Requirement: Dewey Health Check Protocol

The `checkDewey()` function MUST probe the Dewey MCP endpoint using a JSON-RPC
2.0 POST request via `memory.NewClient(deweyURL).Health()`, instead of an HTTP
GET.

Previously: `checkDewey()` used `http.Client.Get(deweyURL)` to probe the
endpoint, which is incompatible with the MCP Streamable HTTP transport.

The function MUST return a `CheckResult` with:
- `Status: "pass"` when `Health()` returns `nil`.
- `Status: "warn"` when `Health()` returns any error (Dewey is optional).

The function MUST NOT return `Status: "fail"` for Dewey — Dewey is an optional
dependency.

#### Scenario: Dewey is healthy and reachable

- **GIVEN** Dewey is running and accepting JSON-RPC requests at the configured
  URL
- **WHEN** `checkDewey(deweyURL)` is called
- **THEN** the result has `Status: "pass"` and `Message` contains "Dewey is
  reachable"

#### Scenario: Dewey is not running

- **GIVEN** no service is listening at the configured Dewey URL
- **WHEN** `checkDewey(deweyURL)` is called
- **THEN** the result has `Status: "warn"` and `Message` contains "not
  reachable"

#### Scenario: Dewey returns a server error

- **GIVEN** the Dewey endpoint returns an HTTP error status (e.g., 500)
- **WHEN** `checkDewey(deweyURL)` is called
- **THEN** the result has `Status: "warn"` and `Message` describes the error

### Requirement: Dewey Health Check Tests

All Dewey-related test mock servers MUST accept HTTP POST with
`Content-Type: application/json` and return valid JSON-RPC 2.0 responses.

Previously: Test mocks returned bare HTTP 200 responses to GET requests.

#### Scenario: Healthy mock server

- **GIVEN** a test mock server that accepts POST and returns
  `{"jsonrpc":"2.0","result":{},"id":1}`
- **WHEN** `checkDewey(mockURL)` is called
- **THEN** the result has `Status: "pass"`

#### Scenario: Error mock server

- **GIVEN** a test mock server that returns HTTP 500 to any request
- **WHEN** `checkDewey(mockURL)` is called
- **THEN** the result has `Status: "warn"`

## REMOVED Requirements

None.
