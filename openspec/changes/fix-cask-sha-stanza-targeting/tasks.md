<!--
  [P] marks tasks eligible for parallel execution.
  Add [P] when a task: (a) touches different files from
  other [P] tasks in the group, (b) has no dependency
  on prior tasks in the group, (c) can safely execute
  without ordering constraints.
  Do NOT add [P] when tasks modify the same file —
  parallel workers will cause merge conflicts.
  Tasks without [P] run sequentially first, then [P]
  tasks run in parallel.
-->

## 1. Implement tested cask integrity patching

- [ ] 1.1 Add `.github/scripts/patch-homebrew-cask.sh` to compute the
  downloaded archive SHA, require exactly one matching release-manifest
  entry, patch exactly one darwin URL stanza's immediately preceding
  `sha256`, and verify the result.

- [ ] 1.2 Make every invalid input fail closed with an `::error::`
  annotation, preserve the original cask on failure, and remove temporary
  output on every exit path.

- [ ] 1.3 Update `publish-cask` to check out the repository with the existing
  verified, SHA-pinned `actions/checkout` reference, download the archive,
  manifest, and cask, then invoke the checked-in script.

## 2. Add automated regression coverage

- [ ] 2.1 Add the clean v0.5.0 GoReleaser cask template as a test fixture.

- [ ] 2.2 Add dependency-free shell tests covering: successful patch with
  both Linux checksums unchanged; missing darwin URL; URL-before-sha256;
  stray darwin comment; duplicate darwin URL; missing, duplicate, and
  mismatched manifest entries; and preservation of the original cask on
  every invalid case.

- [ ] 2.3 Add the shell regression suite to the `Build and Test` CI job.

## 3. Documentation

- [x] 3.1 [P] Update `CHANGELOG.md`: correct the Unreleased entry that
  claims the Homebrew SHA mismatch is fixed (it shipped broken in v0.5.0)
  and add an entry for the stanza-targeting fix.

## 4. Verification

- [ ] 4.1 Run the checked-in cask integrity regression suite.

- [ ] 4.2 Confirm the new verifier rejects the corrupt v0.5.0 cask that the
  previous file-wide `grep` accepted.

- [ ] 4.3 Run `actionlint` with ShellCheck integration over both workflows
  and the checked-in integrity scripts.

- [ ] 4.4 Run `make check` and `make check-coverage` to confirm no incidental
  Go breakage.

- [ ] 4.5 Verify constitution alignment: Composability First (Homebrew
  install works on both affected platforms from the next release),
  Observable Quality (mispatches fail in PR CI and at release time), and
  Testability (the exact production script has dependency-free fixture
  coverage executed by CI).
