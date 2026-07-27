# Replicator Security Policy

This policy describes the Replicator project's security and disclosure
information.

## Reporting a Vulnerability

To report a vulnerability, either:

1. **(Preferred)** Report it privately through GitHub's built-in
   [security advisory reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability):

   - Navigate to the Security tab on the repository
   - Click on "Advisories"
   - Click on "Report a vulnerability"
   - Detail the issue (see below for examples of useful information to include)

2. Send an email to
   [`unbound-force-maintainers@googlegroups.com`](mailto:unbound-force-maintainers@googlegroups.com)
   detailing the issue and impacted project(s).

**Do not open public issues for security vulnerabilities.** Public issues risk
exposing exploit details before a fix is available.

### What to Include

Make sure to include all the details that might help maintainers better
understand and prioritize the vulnerability:

- Versions of Replicator used
- Detailed list of steps to reproduce the vulnerability
- Consequences of the vulnerability
- Severity you feel should be attributed to the vulnerability
- Screenshots or logs (redact any sensitive information)

## Public Disclosure

Vulnerabilities once fixed will be shared publicly as a GitHub
[security advisory](https://docs.github.com/en/code-security/security-advisories/repository-security-advisories/about-repository-security-advisories)
and mentioned in the fixed version's release notes.

## Supported Versions

Replicator is currently pre-1.0. Security fixes are applied to the `main`
branch only. There is no backporting commitment at this time.

Once the project reaches 1.0, this section will be updated with a formal
version support policy.

| Version | Supported |
|---------|-----------|
| `main` (pre-1.0) | Yes |

## Acknowledgments

This policy was adapted from the
[ComplyTime community security policy](https://github.com/complytime/community/blob/main/SECURITY.md).
