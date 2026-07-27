# Replicator Security Policy

This policy describes the Replicator project's security and disclosure
information.

## Reporting a Vulnerability

To report a vulnerability, either:

1. **(Preferred)** Report it on GitHub directly by following the procedure
   described
   [here](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)
   and:

   - Navigate to the Security tab on the repository
   - Click on "Advisories"
   - Click on "Report a vulnerability"
   - Detail the issue (see below for examples of useful information to
     include)

2. If private vulnerability reporting is unavailable, open a
   [GitHub issue](https://github.com/unbound-force/replicator/issues) with the
   label `security` and include only a high-level summary -- do not include
   exploit details in public issues.

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
