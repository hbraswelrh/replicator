## 1. Update `checkDewey()` Implementation

- [x] 1.1 In `internal/doctor/checks.go`, add import for `github.com/unbound-force/replicator/internal/memory`.
- [x] 1.2 Replace the `http.Client.Get(deweyURL)` call in `checkDewey()` with `memory.NewClient(deweyURL).Health()`. Use `errors.As` to detect `*memory.UnavailableError` for the unreachable case. Return `Status: "warn"` for any error, `Status: "pass"` on success.
- [x] 1.3 Remove the `net/http` import from `checks.go` if no longer used by any function in the file.

## 2. Update Tests

- [x] 2.1 In `internal/doctor/checks_test.go`, create a `jsonRPCHandler` helper that returns an `http.HandlerFunc` accepting POST requests and responding with `{"jsonrpc":"2.0","result":{},"id":1}`.
- [x] 2.2 Update `TestCheckDewey_Healthy` to use the JSON-RPC mock handler.
- [x] 2.3 Update `TestCheckDewey_HTTPError` to use a handler that returns HTTP 500 on POST.
- [x] 2.4 Update `TestRun_AllChecks` and `TestCheckResult_StatusValues` mock servers to use the JSON-RPC handler.
- [x] 2.5 Verify `TestCheckDewey_Unreachable` still works (it uses a bad address, no mock changes needed).

## 3. Verification

- [x] 3.1 Run `make check` and confirm all tests pass with zero failures.
- [x] 3.2 Verify constitution alignment: doctor output remains machine-parseable JSON (Observable Quality), Dewey failure remains a warning not an error (Composability First), tests use `httptest.NewServer` with no external services (Testability).
<!-- spec-review: passed -->
<!-- code-review: passed -->
