## ADDED Requirements

### Requirement: Dependabot Configuration

The repository MUST have a `.github/dependabot.yml` file that configures
automated dependency update proposals for both `github-actions` and `gomod`
package ecosystems.

Each ecosystem entry MUST specify:
- `package-ecosystem` identifying the dependency type
- `directory` set to `"/"` (repository root)
- `schedule.interval` set to `"weekly"`
- `commit-message.prefix` set to `"chore(deps):"` to follow conventional
  commits convention

#### Scenario: Dependabot proposes GitHub Actions update

- **GIVEN** a `.github/dependabot.yml` exists with `github-actions` ecosystem
- **WHEN** a pinned GitHub Action in `.github/workflows/` has a newer version
- **THEN** Dependabot opens a PR updating the SHA pin and version comment

#### Scenario: Dependabot proposes Go module update

- **GIVEN** a `.github/dependabot.yml` exists with `gomod` ecosystem
- **WHEN** a Go module dependency in `go.mod` has a newer version
- **THEN** Dependabot opens a PR updating `go.mod` and `go.sum`

### Requirement: Code Ownership

The repository MUST have a `.github/CODEOWNERS` file that assigns code
ownership to the `@unbound-force/overlords` team.

The file MUST include:
- A `*` catch-all pattern assigning `@unbound-force/overlords` as default
  owners for all files
- An explicit `.github/` entry for CI/CD workflows and GitHub configuration
- An explicit `.specify/memory/constitution.md` entry for governance documents
- An explicit `.opencode/` entry for agent configuration

#### Scenario: PR triggers code owner review

- **GIVEN** a `.github/CODEOWNERS` file exists with a `*` catch-all pattern
- **WHEN** a contributor opens a PR modifying any file
- **THEN** GitHub requests a review from `@unbound-force/overlords`

#### Scenario: Branch protection enforces code owner approval

- **GIVEN** `.github/settings.yml` sets `require_code_owner_reviews: true`
- **AND** a `.github/CODEOWNERS` file defines owners
- **WHEN** a PR is submitted without code owner approval
- **THEN** the PR cannot be merged

### Requirement: Security Policy

The repository MUST have a `SECURITY.md` file at the repository root that
documents the vulnerability disclosure process.

The file MUST include:
- Instructions for reporting vulnerabilities via GitHub's private vulnerability
  reporting feature
- Guidance on what information to include in a vulnerability report (affected
  versions, reproduction steps, consequences, severity assessment)
- A public disclosure policy describing how fixed vulnerabilities are
  communicated
- A supported versions section describing the project's version and patching
  policy

The file SHOULD reference the `complytime/community` security policy as the
source template in an acknowledgments section.

#### Scenario: Security researcher finds vulnerability

- **GIVEN** a `SECURITY.md` exists at the repository root
- **WHEN** a security researcher discovers a vulnerability
- **THEN** they can follow the documented process to report it privately via
  GitHub's security advisories feature

#### Scenario: GitHub surfaces security policy

- **GIVEN** a `SECURITY.md` exists at the repository root
- **WHEN** a user navigates to the repository's Security tab
- **THEN** GitHub displays the security policy content
