#!/usr/bin/env bash
set -euo pipefail

error() {
  echo "::error::$*" >&2
  exit 1
}

if [ "$#" -ne 3 ]; then
  error "Usage: $0 <darwin-archive> <checksums.txt> <cask-file>"
fi

ARCHIVE=$1
CHECKSUMS=$2
CASK_FILE=$3

[ -f "$ARCHIVE" ] || error "Darwin archive not found: $ARCHIVE"
[ -f "$CHECKSUMS" ] || error "Release manifest not found: $CHECKSUMS"
[ -f "$CASK_FILE" ] || error "Cask file not found: $CASK_FILE"

ARCHIVE_SHA=$(sha256sum "$ARCHIVE" | awk '{ print $1 }')
[[ "$ARCHIVE_SHA" =~ ^[0-9a-f]{64}$ ]] || \
  error "Computed SHA is not a valid 64-character hex string"

ARCHIVE_NAME=$(basename "$ARCHIVE")
mapfile -t MANIFEST_SHAS < <(
  awk -v archive="$ARCHIVE_NAME" '$2 == archive { print $1 }' "$CHECKSUMS"
)

if [ "${#MANIFEST_SHAS[@]}" -ne 1 ]; then
  error "Release manifest must contain exactly one entry for $ARCHIVE_NAME"
fi
if [ "${MANIFEST_SHAS[0]}" != "$ARCHIVE_SHA" ]; then
  error "Release manifest SHA does not match downloaded darwin_arm64 archive"
fi

PATCHED_FILE=$(mktemp "${CASK_FILE}.patched.XXXXXX")
trap 'rm -f "$PATCHED_FILE"' EXIT

awk -v arm64="$ARCHIVE_SHA" '
  { lines[NR] = $0 }
  /^[[:space:]]*url "[^"]*darwin_arm64[^"]*"/ {
    count++
    candidate = NR - 1
    if (lines[candidate] ~ /^[[:space:]]*sha256 "[0-9a-f]+"[[:space:]]*$/) {
      target = candidate
    }
  }
  END {
    if (count != 1 || !target) {
      printf "::error::Cask layout changed: found %d darwin_arm64 URL stanza(s); exactly one immediately preceded by sha256 is required\n", count + 0 > "/dev/stderr"
      exit 1
    }
    sub(/sha256 "[^"]*"/, "sha256 \"" arm64 "\"", lines[target])
    for (i = 1; i <= NR; i++) {
      print lines[i]
    }
  }
' "$CASK_FILE" > "$PATCHED_FILE"

if ! awk -v arm64="$ARCHIVE_SHA" '
  { lines[NR] = $0 }
  /^[[:space:]]*url "[^"]*darwin_arm64[^"]*"/ {
    count++
    if (lines[NR - 1] !~ ("^[[:space:]]*sha256 \"" arm64 "\"[[:space:]]*$")) {
      bad = 1
    }
  }
  END { exit (count == 1 && !bad) ? 0 : 1 }
' "$PATCHED_FILE"; then
  error "SHA verification failed: darwin_arm64 stanza does not carry the computed SHA"
fi

mv "$PATCHED_FILE" "$CASK_FILE"
echo "Cask patched successfully with darwin_arm64 SHA: $ARCHIVE_SHA"
