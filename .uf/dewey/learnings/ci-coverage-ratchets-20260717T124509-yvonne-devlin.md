---
tag: ci-coverage-ratchets
author: yvonne-devlin
category: gotcha
created_at: 2026-07-17T12:45:09Z
identity: ci-coverage-ratchets-20260717T124509-yvonne-devlin
tier: draft
---

In the replicator project, `internal/tools/*` packages (org, forge, comms, memory, registry) all sit at 0% coverage because they are thin MCP handler wrappers with no test files. When setting up global coverage ratchets, exclude these packages from per-package thresholds — their 0% coverage would force an impossibly low global floor or require exemptions. Instead, set the global floor conservatively (55% works for replicator's current 58.4% state) and track the low-coverage packages in a separate issue for test additions. The per-package ratchets should only target packages already above 70%.
