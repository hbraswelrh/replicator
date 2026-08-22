## Why

`brew install unbound-force/tap/replicator` is broken at v0.5.0 on **both**
macOS arm64 and Linux amd64. The `publish-cask` job patches the wrong
stanza's `sha256` line in the Homebrew cask.

GoReleaser emits each cask stanza as `sha256` **then** `url`, so the
`darwin_arm64` marker appears *after* the sha256 line it belongs to. The
current `awk` scans *forward* from the marker for the next `sha256`, which
belongs to the following (`linux_amd64`) stanza. The result is that darwin
keeps its stale pre-signing checksum while linux_amd64 is overwritten with
darwin's.

Observed in the published v0.5.0 cask, against the release's own
`checksums.txt`:

| Cask line | Stanza | Published SHA | Actual artifact SHA |
|---|---|---|---|
| 7 | `darwin_arm64` | `ea3278e2…` | `33683ca5…` — stale |
| 14 | `linux_amd64` | `33683ca5…` (darwin's) | `db3f96fc…` — clobbered |
| 18 | `linux_arm64` | `d35cf511…` | `d35cf511…` — correct |

The `replicator.rb` release asset is clean for both linux stanzas, so the
corruption is introduced by the patch step and exists only in the tap.

This defect escaped detection because the verification guard is a file-wide
`grep -q "sha256 \"$ARM64_SHA\""`. The darwin SHA *was* present in the file
— on the wrong line — so the grep passed and the corrupt cask shipped.
`fix-homebrew-sha-mismatch` already specified that verification MUST confirm
the SHA is "in the correct context (associated with the `darwin_arm64`
section)"; that requirement was never met by the implementation.

This is a distinct defect from the one fixed by `fix-homebrew-sha-mismatch`
(issue #81). That change correctly extracted `publish-cask` to close a
TOCTOU/skip gap. The extraction is sound; the awk targeting inside it is not.

Fixes: https://github.com/unbound-force/replicator/issues/87

## What Changes

Four changes to the release pipeline:

1. **Independent manifest check.** Confirm the SHA computed from the
   downloaded darwin archive matches the darwin entry in the release's
   regenerated `checksums.txt` before exposing it to the patch step.
2. **Stanza-targeted patching.** Require exactly one `url` directive whose
   quoted value contains `darwin_arm64`, require its immediately preceding
   line to be a `sha256` directive, and patch exactly that line. Fail with an
   error annotation when the count or adjacency differs.
3. **Context-aware verification.** Replace the file-wide `grep` with a check
   that the computed SHA sits inside the `darwin_arm64` stanza, satisfying
   the existing (unmet) spec requirement.
4. **Durable regression coverage.** Extract the integrity logic into a
   checked-in script used by the release workflow, add fixture-based shell
   tests for the shipped corruption and malformed layouts/manifests, and run
   those tests in pull-request CI.

## Capabilities

### New Capabilities
- `stanza-targeted cask patching`: the patch step resolves exactly one
  `darwin_arm64` URL stanza's own `sha256` line and fails loudly when the
  cask layout does not match its structural assumption.
- `release-manifest checksum validation`: the downloaded darwin archive's
  computed SHA must match the release manifest before cask patching.

### Modified Capabilities
- `SHA verification before tap push`: verification becomes stanza-aware, so
  a SHA written into the wrong stanza is rejected rather than accepted.

### Removed Capabilities
- None

## Impact

- **Files**: `.github/workflows/release.yml` invokes the checked-in patcher;
  `.github/workflows/ci.yml` runs its regression tests; `.github/scripts/`
  contains the patcher, tests, and cask fixture. No job graph or permission
  changes.
- **Users**: Homebrew install works for macOS arm64 and Linux amd64 from the
  next release onward. Because the job re-downloads `replicator.rb` from the
  release on every run, the next release regenerates the cask from a clean
  template and self-heals both platforms.
- **v0.5.0**: remains broken in the tap until a subsequent release or a
  manual tap correction. Out of scope for this change.
- **No Go source code changes.** CI's `Build and Test` job is unaffected.

## Constitution Alignment

Assessed against the Replicator project constitution
(`.specify/memory/constitution.md`).

### I. Autonomous Collaboration

**Assessment**: N/A

This change modifies a single CI workflow step. No MCP tools, tool output
shapes, or inter-agent communication paths are affected.

### II. Composability First

**Assessment**: PASS

Replicator MUST be independently installable. A cask carrying mismatched
checksums breaks the Homebrew distribution channel outright. This change
restores it for both affected platforms, and does so on the signed and
unsigned paths alike, since the patch step is common to both.

### III. Observable Quality

**Assessment**: PASS

The failure mode this change addresses was *silent*: a mispatch produced a
passing gate and a broken install discovered only by end users. Both the
patch and the verification now emit `::error::` annotations and fail the
job at release time, moving detection from the user to the pipeline.

### IV. Testability

**Assessment**: PASS

The integrity logic is a checked-in script with dependency-free fixture
tests executed by pull-request CI. Coverage includes the real v0.5.0
template, unchanged Linux checksums, missing and duplicate darwin stanzas,
reordered directives, stray comments, and missing, duplicate, or mismatched
manifest entries.
