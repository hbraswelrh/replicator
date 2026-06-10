---
tag: testing-json-rpc-mocks
author: anonymous
category: pattern
created_at: 2026-06-10T17:09:00Z
identity: testing-json-rpc-mocks-20260610T170900-anonymous
tier: draft
---

When writing test mocks for JSON-RPC endpoints in the replicator project, the mock handler should validate protocol conformance — not just return a canned response. Specifically: (1) validate HTTP method is POST, (2) validate Content-Type is application/json, (3) validate the jsonrpc field is "2.0", and (4) validate a method field is present. This provides regression protection against the exact class of bug being tested (protocol mismatch). The divisor-testing reviewer flagged shallow mocks as a HIGH finding during code review, requiring a second iteration to add these assertions. Always match assertion depth across related test functions — if TestCheckGit asserts Name, Status, Message, and Duration, then TestCheckDewey should assert the same fields.
