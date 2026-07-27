## Context

PR #32 (govulncheck CI addition) review surfaced four pre-existing repository
hygiene gaps, tracked as issue #33. Gap 1 (`.gitignore` for log files) was
resolved in PR #35. Three gaps remain: no Dependabot configuration, no
CODEOWNERS file, and no SECURITY.md. All three are configuration/documentation
additions with no production code impact.

The proposal's constitution alignment assessment found all four principles
either PASS or N/A -- these changes operate entirely at the GitHub platform
layer.

## Goals / Non-Goals

### Goals

- Add automated dependency update proposals via Dependabot for both GitHub
  Actions SHA pins and Go module dependencies, on a weekly schedule.
- Activate the existing `require_code_owner_reviews: true` branch protection
  rule by creating a CODEOWNERS file with `@unbound-force/overlords` as the
  default team.
- Establish a vulnerability disclosure process adapted from the
  `complytime/community` SECURITY.md template, using GitHub's private
  vulnerability reporting as the primary channel.

### Non-Goals

- Setting up a dedicated security email address for unbound-force (no such
  address exists; GitHub private reporting is sufficient).
- Adding golangci-lint or MegaLinter to CI (covered by issue #25).
- Modifying existing CI workflows (`ci.yml`, `release.yml`).
- Backport policy for security fixes (replicator is pre-1.0).

## Decisions

### D1: Dependabot ecosystems and schedule

**Decision**: Configure two ecosystems -- `github-actions` and `gomod` -- both
on a weekly schedule with `chore(deps):` commit message prefix.

**Rationale**: Weekly balances staying current with not generating excessive PR
noise. The `chore(deps):` prefix follows the project's conventional commits
convention. The `ci-release-preflight` design doc (D5) explicitly recommended
Dependabot with `package-ecosystem: github-actions` as a follow-up.

### D2: CODEOWNERS scope

**Decision**: Use `@unbound-force/overlords` as the team for all paths. Include
a `*` catch-all plus explicit entries for `.github/`, governance documents, and
agent configuration.

**Rationale**: The `*` catch-all ensures every PR triggers a code owner review,
which is what `require_code_owner_reviews: true` in `.github/settings.yml`
expects. Explicit entries for sensitive paths (`.github/`,
`.specify/memory/constitution.md`, `.opencode/`) serve as documentation of
which areas are considered governance-critical, even though they already match
the catch-all.

### D3: SECURITY.md template source

**Decision**: Adapt `complytime/community/SECURITY.md` as the template. Use
GitHub private vulnerability reporting as the sole reporting channel (omit
email). Include "What to include" guidance, public disclosure process, and
supported versions section.

**Rationale**: The complytime community policy is well-structured and covers
the essential sections. The `complyctl` version is too minimal (3 lines).
Omitting a security email avoids publishing a non-existent address.

## Risks / Trade-offs

- **Dependabot PR volume**: Weekly updates for two ecosystems may generate
  multiple PRs per week. Mitigation: Dependabot respects the default limit of
  5 open PRs per ecosystem. PRs can be batched or the schedule changed to
  `monthly` if volume is excessive.
- **CODEOWNERS catch-all blocking**: The `*` catch-all means every PR requires
  an `@unbound-force/overlords` approval. This could slow down solo
  contributors. Mitigation: The team already has this implicit via
  `required_approving_review_count: 1` -- CODEOWNERS just makes ownership
  explicit.
- **No security email fallback**: If GitHub's private vulnerability reporting
  is disabled or inaccessible, there is no alternative contact method.
  Mitigation: GitHub's feature is enabled by default for public repos and is
  the recommended approach for projects without dedicated security teams.
