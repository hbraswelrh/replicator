---
tag: ci-coverage-ratchets
author: yvonne-devlin
category: gotcha
created_at: 2026-07-17T12:45:20Z
identity: ci-coverage-ratchets-20260717T124520-yvonne-devlin
tier: draft
---

The spec review council caught an important edge case that the initial spec missed: when a protected package is renamed or removed, its coverage grep pattern matches zero lines, causing the awk averaging to produce 0.0%, which then fails the ratchet with a confusing "0.0% < N%" error. The mitigation is both a process constraint (the ratchet table in ci.yml MUST be updated in the same PR as any package rename) and a code safeguard (the awk snippet uses `END {if(c>0) printf "%.1f", t/c; else print "0.0"}` to handle the zero-lines case explicitly). The adversary reviewer also identified the `GLOBAL_COV` empty-string silent-pass edge case — when `bc -l` receives an empty string from `echo " < 55.0"`, it may error on stderr but exit 0, causing the arithmetic evaluation to silently pass. The fix is a simple `[ -z "$GLOBAL_COV" ]` guard after extraction.
