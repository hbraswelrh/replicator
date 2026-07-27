## Why

PR #32 review identified several pre-existing security and CI hygiene gaps
(tracked as issue #33). One gap (`.uf/replicator/*.log` not in `.gitignore`)
was already fixed in PR #35. Three gaps remain:

1. No `dependabot.yml` for automated GitHub Actions SHA and Go module updates.
2. No `CODEOWNERS` file, making the `require_code_owner_reviews: true` setting
   in `.github/settings.yml` a no-op.
3. No `SECURITY.md` vulnerability disclosure policy.

These are incremental hardening items -- configuration and documentation files
only, no production code changes.

## What Changes

### New Capabilities
- `dependabot`: Automated weekly PRs for GitHub Actions SHA updates and Go
  module dependency updates via `.github/dependabot.yml`.
- `code-ownership`: Code owner review enforcement via `.github/CODEOWNERS`,
  assigning `@unbound-force/overlords` as default owners with explicit
  protection for `.github/`, `.specify/memory/constitution.md`, and `.opencode/`.
- `security-policy`: Vulnerability disclosure process via `SECURITY.md`,
  adapted from the `complytime/community` security policy template.

### Modified Capabilities
- None.

### Removed Capabilities
- None.

## Impact

- `.github/dependabot.yml` -- new file; will generate automated PRs on a
  weekly schedule for `github-actions` and `gomod` ecosystems.
- `.github/CODEOWNERS` -- new file; activates the existing
  `require_code_owner_reviews: true` branch protection rule. All PRs will
  require approval from `@unbound-force/overlords`.
- `SECURITY.md` -- new file at repo root; provides vulnerability reporting
  instructions via GitHub's private vulnerability reporting feature.
- No production code, test code, or CI workflow changes.

## Constitution Alignment

Assessed against the Replicator constitution (`.specify/memory/constitution.md`),
which extends the Unbound Force org constitution v1.1.0.

### I. Autonomous Collaboration

**Assessment**: N/A

This change adds repository configuration and documentation files. It does not
affect tool interfaces, MCP protocol interactions, or inter-agent communication.

### II. Composability First

**Assessment**: PASS

Dependabot, CODEOWNERS, and SECURITY.md are GitHub platform features that
operate independently. None introduce mandatory dependencies on external
services. The replicator binary remains independently installable and usable.

### III. Observable Quality

**Assessment**: N/A

This change does not affect tool responses, JSON output shapes, or
machine-parseable output. Dependabot PRs are observable through GitHub's
standard PR workflow.

### IV. Testability

**Assessment**: N/A

No production code or test code is modified. The files added are static
configuration and documentation with no runtime behavior to test.
