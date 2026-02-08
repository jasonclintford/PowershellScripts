# PowerShell Security Audit Toolkit

This repository provides a container-friendly PowerShell toolkit for authorised security auditing, inventory, detection, and reporting tasks. Scripts follow consistent output conventions (JSON-first, with optional CSV/NDJSON/SARIF/HTML) and include safety banners to reinforce authorised-use only operations.

## Repository layout

```
common/          Shared helper module (logging, exports, retries, parallel helpers)
bootstrap/       Container setup, secrets vault, linting
network/         Reachability and port checks
dns/             DNS collection and comparison
http_tls/        HTTP headers, TLS posture, content hashing, redirects
host_audit/      Linux host configuration and identity audits
logs_detection/  Log parsing and detection helpers
integrity_ioc/   File integrity, IOC scanning, YARA/ClamAV wrappers
runtime/         Runtime snapshots and kernel posture
remote/          SSH-based fleet collection and drift checks
vuln_exposure/   CVE mapping, Trivy, SBOM, secrets scanning
threat_intel/    Reputation and IOC normalization helpers
reporting/       Case folder and report generation helpers
launcher/        Interactive CLI menu launcher
out/             Default output directory (generated)
```

## Common conventions

- **Authorised use only**: every script prints a banner and avoids intrusive actions by default.
- **Structured output**: JSON is the primary output format unless otherwise noted.
- **Dependency checks**: scripts that rely on Linux utilities validate availability before running.

## Getting started

From the repository root:

```bash
pwsh ./launcher/Launch.ps1
```

Or invoke a script directly, for example:

```bash
pwsh ./network/10-SubnetReachability.ps1 -Cidr 10.0.0.0/24 -Concurrency 200
pwsh ./dns/20-DnsRecordCollector.ps1 -Domains example.com,example.org -Resolver 1.1.1.1
pwsh ./http_tls/30-HttpHeaderBaseline.ps1 -Urls https://example.com
```

## Outputs

Scripts write to `out/` by default. You can override output paths in scripts that expose an `OutFile` parameter.

## Linting

```bash
pwsh ./bootstrap/00-LintAndFormat.ps1 -Path . -SarifOut out/pssa.sarif
```

## Notes

- The toolkit targets **Ubuntu 24.04** containers and PowerShell **7.4+**.
- Ensure optional utilities (e.g., `nmap`, `trivy`, `syft`, `gitleaks`) are installed before use.
