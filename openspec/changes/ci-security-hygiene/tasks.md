<!--
  [P] marks tasks eligible for parallel execution.
  Add [P] when a task: (a) touches different files from
  other [P] tasks in the group, (b) has no dependency
  on prior tasks in the group, (c) can safely execute
  without ordering constraints.
  Do NOT add [P] when tasks modify the same file --
  parallel workers will cause merge conflicts.
  Tasks without [P] run sequentially first, then [P]
  tasks run in parallel.
-->

## 1. Add Repository Configuration Files

All three files are independent -- different paths, no shared state.

- [x] 1.1 [P] Create `.github/dependabot.yml` with `github-actions` and
  `gomod` ecosystems, weekly schedule, `chore(deps):` commit prefix.
  Ref: design D1, spec "Dependabot Configuration".

- [x] 1.2 [P] Create `.github/CODEOWNERS` with `*` catch-all for
  `@unbound-force/overlords`, plus explicit entries for `.github/`,
  `.specify/memory/constitution.md`, and `.opencode/`.
  Ref: design D2, spec "Code Ownership".

- [x] 1.3 [P] Create `SECURITY.md` at repo root, adapted from
  `complytime/community` template. Include: reporting via GitHub private
  vulnerability reporting, what-to-include checklist, public disclosure
  process, supported versions (pre-1.0, main branch only), acknowledgments.
  Ref: design D3, spec "Security Policy".

## 2. Verification

- [x] 2.1 Run `make check` to confirm no regressions (CI parity gate).

- [x] 2.2 Verify constitution alignment: confirm no new runtime dependencies,
  no tool interface changes, no production code modifications. All four
  principles assessed as PASS or N/A in proposal.

<!-- spec-review: passed -->
<!-- code-review: passed -->
