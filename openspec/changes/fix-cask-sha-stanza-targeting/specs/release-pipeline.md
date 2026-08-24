## ADDED Requirements

### Requirement: Stanza-targeted SHA patching

The `publish-cask` job MUST patch the `sha256` value belonging to the
`darwin_arm64` stanza and MUST NOT modify the `sha256` value of any other
stanza.

The job MUST require exactly one `url` directive whose quoted URL contains
`darwin_arm64`. Its immediately preceding line MUST be a `sha256` directive,
because the generated cask emits each stanza in that shape. Comments and
other non-URL occurrences of `darwin_arm64` MUST NOT affect target selection.

#### Scenario: Cask in the expected layout
- **GIVEN** a cask where each stanza emits `sha256` before `url`
- **AND** the `darwin_arm64` stanza carries a stale pre-signing checksum
- **WHEN** the patch step runs with the computed darwin SHA
- **THEN** the `darwin_arm64` stanza's `sha256` MUST be replaced with the
  computed SHA
- **AND** the `linux_amd64` and `linux_arm64` stanzas' `sha256` values MUST
  be left unchanged

#### Scenario: No sha256 line precedes a darwin_arm64 reference
- **GIVEN** a cask in which no `sha256` line appears before any
  `darwin_arm64` reference
- **WHEN** the patch step runs
- **THEN** the job MUST fail with an `::error::` annotation
- **AND** the cask file MUST NOT be pushed to the Homebrew tap

#### Scenario: Cask contains no darwin_arm64 stanza
- **GIVEN** a cask with no `darwin_arm64` reference
- **WHEN** the patch step runs
- **THEN** the job MUST fail with an `::error::` annotation rather than
  emitting the cask unchanged

#### Scenario: Cask contains a stray darwin_arm64 comment
- **GIVEN** a cask with exactly one `darwin_arm64` URL stanza
- **AND** a later comment also contains the text `darwin_arm64`
- **WHEN** the patch step runs
- **THEN** the comment MUST NOT affect target selection
- **AND** only the URL stanza's preceding `sha256` MUST be patched

#### Scenario: Cask contains multiple darwin_arm64 URL stanzas
- **GIVEN** a cask with more than one URL directive containing
  `darwin_arm64`
- **WHEN** the patch step runs
- **THEN** the job MUST fail with an `::error::` annotation
- **AND** the cask file MUST NOT be pushed to the Homebrew tap

#### Scenario: Computed SHA is empty
- **GIVEN** the SHA computation step produced an empty value
- **WHEN** the patch step runs
- **THEN** the job MUST fail with an `::error::` annotation before
  attempting to patch

### Requirement: Release manifest checksum validation

Before cask patching, the `publish-cask` job MUST confirm that the SHA-256
computed from the downloaded darwin archive equals the same archive's entry
in the release's regenerated `checksums.txt`. A missing, duplicate, or
mismatched manifest entry MUST fail the job before the SHA is exposed to the
patch step.

#### Scenario: Downloaded archive matches the release manifest
- **GIVEN** the downloaded darwin archive's computed SHA equals its entry in
  `checksums.txt`
- **WHEN** the SHA computation step completes
- **THEN** it MUST expose the validated SHA to the patch step

#### Scenario: Downloaded archive does not match the release manifest
- **GIVEN** the downloaded darwin archive's computed SHA differs from its
  entry in `checksums.txt`
- **WHEN** the SHA computation step runs
- **THEN** the job MUST fail with an `::error::` annotation
- **AND** the cask MUST NOT be patched or pushed

#### Scenario: Manifest entry is missing or duplicated
- **GIVEN** `checksums.txt` contains zero or more than one entry for the
  downloaded darwin archive
- **WHEN** manifest validation runs
- **THEN** the job MUST fail with an `::error::` annotation
- **AND** the cask MUST NOT be patched or pushed

### Requirement: Automated cask integrity regression tests

The repository MUST contain dependency-free fixture tests for the exact
integrity script invoked by `publish-cask`, and the `Build and Test` CI job
MUST execute them on pull requests.

#### Scenario: Pull request changes release integrity logic
- **GIVEN** a pull request changes the cask patcher, its workflow invocation,
  or its fixtures
- **WHEN** the `Build and Test` job runs
- **THEN** it MUST execute the cask integrity regression tests

#### Scenario: Shipped v0.5.0 regression fixture
- **GIVEN** the clean v0.5.0 GoReleaser cask template and an archive whose
  manifest checksum matches
- **WHEN** the integrity script runs
- **THEN** it MUST update only the darwin checksum
- **AND** both Linux checksums MUST remain byte-for-byte unchanged

#### Scenario: Malformed cask or manifest fixture
- **GIVEN** a missing or duplicate darwin URL, reordered sha256 and URL
  directives, a stray darwin comment, or a missing, duplicate, or mismatched
  manifest entry
- **WHEN** the regression suite runs
- **THEN** each valid layout MUST produce the expected cask
- **AND** each invalid layout or manifest MUST fail closed without modifying
  the original cask

## MODIFIED Requirements

### Requirement: SHA verification before tap push

Previously: the `publish-cask` job verified that the patched cask file
contained the computed SHA, using a file-wide search. That search accepted a
cask in which the SHA had been written to the wrong stanza.

The `publish-cask` job MUST verify that the computed SHA is carried by the
`sha256` line associated with the `darwin_arm64` stanza. A match anywhere
else in the file MUST NOT satisfy this requirement. If verification fails,
the job MUST fail with an `::error::` annotation and MUST NOT push to the
Homebrew tap.

The verification MUST compare the SHA as a literal string, not as a regular
expression pattern.

#### Scenario: SHA patched into the darwin_arm64 stanza
- **GIVEN** the cask has been patched and the `darwin_arm64` stanza carries
  the computed SHA
- **WHEN** the verification step runs
- **THEN** verification MUST succeed AND the push to the tap MUST proceed

#### Scenario: SHA present but in the wrong stanza
- **GIVEN** the computed SHA appears in the cask on the `linux_amd64`
  stanza's `sha256` line
- **AND** the `darwin_arm64` stanza carries a different value
- **WHEN** the verification step runs
- **THEN** verification MUST fail with an `::error::` annotation
- **AND** the push to the tap MUST NOT proceed

#### Scenario: SHA absent from the cask
- **GIVEN** the computed SHA does not appear anywhere in the patched cask
- **WHEN** the verification step runs
- **THEN** verification MUST fail with an `::error::` annotation
- **AND** the push to the tap MUST NOT proceed

## REMOVED Requirements

None.
