---
tag: ci-coverage-ratchets
author: yvonne-devlin
category: pattern
created_at: 2026-07-17T12:45:05Z
identity: ci-coverage-ratchets-20260717T124505-yvonne-devlin
tier: draft
---

When adding coverage ratchets to a Go CI pipeline, the canonical pattern uses `go tool cover -func=coverage.out` piped through `grep` and `awk` for per-package averaging, with `bc -l` for floating-point threshold comparisons. A `declare -A THRESHOLDS` associative array makes the per-package loop clean and maintainable. The critical guard to add before any parsing is `[ ! -s coverage.out ]` (file exists and non-empty), followed by a second guard checking if the extracted `GLOBAL_COV` variable is empty — this catches corrupted profiles that pass the size check but produce no `total:` line from `go tool cover`. Setting initial thresholds 5–8 percentage points below the current measured coverage gives a useful regression floor without requiring immediate test additions for low-coverage packages.
