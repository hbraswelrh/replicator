---
tag: doctor-dewey-health-check
author: anonymous
category: gotcha
created_at: 2026-06-10T17:08:54Z
identity: doctor-dewey-health-check-20260610T170854-anonymous
tier: draft
---

When writing doctor health checks that probe MCP endpoints, always use the JSON-RPC 2.0 POST method via the existing memory.Client rather than raw HTTP GET. The MCP Streamable HTTP transport only accepts POST for JSON-RPC calls; a plain GET without SSE headers returns HTTP 400 or 405. The replicator project already has memory.NewClient(deweyURL).Health() which sends a proper JSON-RPC POST to dewey_health. Reusing this avoids protocol mismatch bugs and keeps Dewey connectivity logic in one place (DRY). This was the root cause of GitHub issue #16 where checkDewey() in internal/doctor/checks.go was sending GET against a POST-only endpoint.
