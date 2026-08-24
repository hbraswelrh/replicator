## Context

`fix-homebrew-sha-mismatch` extracted Homebrew publishing into a dedicated
`publish-cask` job to close a TOCTOU/skip gap between macOS signing and tap
publication. That restructuring is correct and stays.

Inside that job, the "Patch cask with actual SHA" step rewrites the
`darwin_arm64` checksum, because signing replaces the darwin archive after
GoReleaser has already computed and templated its SHA. The step's awk
assumed a cask layout that does not hold.

`openspec/changes/fix-homebrew-sha-mismatch/tasks.md` task 1.5 recorded the
assumption explicitly:

> the awk pattern assumes the `sha256` directive follows the line containing
> `darwin_arm64` — this structural assumption is validated by the grep step

Both halves are false. GoReleaser emits `sha256` **before** `url`, and the
grep validated nothing about position. This change supersedes that
assumption rather than editing the historical record of a change that has
already shipped.

## Goals / Non-Goals

### Goals
- The `darwin_arm64` stanza carries the SHA of the actual darwin artifact
- No other stanza is modified by the patch step
- A cask layout that violates the step's structural assumption fails the
  job loudly instead of producing a silently wrong cask
- Verification is strong enough to reject the exact corruption that shipped

### Non-Goals
- Repairing the already-published v0.5.0 cask in the tap
- Patching linux checksums (GoReleaser's template values are correct; the
  release asset was verified clean)
- Changes to the job graph, permissions, secrets, or `sign-macos`
- Changes to `.goreleaser.yaml`
- darwin_amd64 support (excluded via `ignore:` in `.goreleaser.yaml`)

## Decisions

**D1: Require strict generated adjacency.** Match exactly one `url`
directive whose quoted value contains `darwin_arm64`, and require its
immediately preceding line to be a `sha256` directive. Patch only that line.
This avoids carrying a stale checksum candidate across stanza boundaries and
prevents comments or trailing text from changing the target. If GoReleaser
changes the generated shape, fail closed rather than guessing.

**D2: Fail loudly when the stanza count or target is invalid.** If there is
not exactly one `darwin_arm64` URL stanza, or if no `sha256` line precedes
it, the awk exits non-zero with an `::error::` annotation rather than
emitting the file unchanged. The previous behaviour delegated this case
entirely to the grep, which was not equipped to catch it. Under
`set -euo pipefail` the non-zero exit aborts the step before the patched
file is moved into place; an EXIT trap removes the partial output file.

**D3: Verify inside exactly one URL stanza, not across the file.**
Verification walks the cask and asserts that exactly one `darwin_arm64` URL
stanza exists and that its preceding `sha256` line carries the computed
SHA. A file-wide `grep` cannot distinguish
"correct" from "written to the wrong stanza" — which is precisely why the
corrupt v0.5.0 cask cleared the gate. This closes the previously unmet
requirement from `fix-homebrew-sha-mismatch`.

**D4: Compare the SHA as a literal string.** Extract the quoted value from
the structurally validated `sha256` line, normalize its surrounding syntax,
and compare it to the computed SHA using awk string equality. The value is
never interpreted as a regular-expression pattern.

**D5: Supersede rather than rewrite.** The false assumption in
`fix-homebrew-sha-mismatch/tasks.md` stays as-is. That change is an accurate
record of what was implemented and shipped in v0.5.0; correcting it in place
would erase the provenance of this defect. The spec delta in this change
supersedes it.

**D6: Cross-check the release manifest before patching.** The archive SHA
computed by `publish-cask` must equal the same archive's entry in the
release's `checksums.txt`. The `sign-macos` job regenerates and re-uploads
that manifest after replacing the signed archive, so it is an independent
integrity check that does not share the cask parser's structural assumption.

**D7: Extract one tested integrity script.** Put archive hashing, manifest
validation, cask patching, and post-patch verification in
`.github/scripts/patch-homebrew-cask.sh`. The release workflow checks out the
repository and invokes that script instead of embedding untestable awk.
Fixture tests in `.github/scripts/patch-homebrew-cask_test.sh` exercise the
same file CI and release use; the normal `Build and Test` job runs them on
every pull request.

## Risks / Trade-offs

**Risk: still structurally coupled to cask layout.** D1 intentionally assumes
GoReleaser's generated `sha256`-then-`url` adjacency. Reordering, inserted
lines, or duplicate darwin URLs fail closed. Fully layout-independent Ruby
parsing is disproportionate for a generated file; strict adjacency is easier
to audit and safer than a permissive heuristic.

**Risk: verification and patch share a cask-layout assumption.** Both use
the same "exactly one darwin URL with a preceding `sha256`" rule, so the
post-patch verifier is not fully independent of the patcher. It detects the
known wrong-stanza regression and rejects duplicate or comment-only
`darwin_arm64` mentions, but cannot prove arbitrary Ruby structure. D6
provides an independent check that the SHA itself matches the release
manifest; it does not validate cask placement.

**Trade-off: repository checkout in `publish-cask`.** The job previously
needed no checkout because all inputs came from release assets. D7 adds a
pinned `actions/checkout` step so the job can execute the same tested script
as CI. The job retains `contents: read`, and the small checkout cost is
accepted in exchange for durable regression coverage.
