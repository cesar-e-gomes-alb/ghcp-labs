# Security Scan Report

**Target:** `lab07/requirements.txt`
**Scan date:** 2026-06-19
**Method:** Manual advisory review (CVE cross-reference). Validate with `pip-audit` for authoritative results.

## Summary

| Metric | Value |
|--------|-------|
| Packages scanned | 4 |
| Packages pinned | 1 (`requests`) |
| Packages unpinned | 3 (`pytest`, `bcrypt`, `pyyaml`) |
| Total findings | 6 |

### Counts by severity

| Severity | Count |
|----------|-------|
| CRITICAL | 3 |
| HIGH | 1 |
| MEDIUM | 1 |
| LOW | 1 |

> Note: CRITICAL/HIGH counts for `pyyaml` are conditional — they apply only if the unpinned dependency resolves to a version below the fixed release. Pinning to a current version closes them.

## Findings

| # | Package | Current Version | CVE ID | Severity | Recommended Action |
|---|---------|-----------------|--------|----------|--------------------|
| 1 | requests | 2.18.0 | CVE-2018-18074 | HIGH | Upgrade to `requests>=2.32.0`. Fixes `Authorization` header leak on cross-host redirect. |
| 2 | requests | 2.18.0 | CVE-2023-32681 | MEDIUM | Covered by upgrade to `requests>=2.32.0`. Fixes `Proxy-Authorization` header leak via HTTPS proxy. |
| 3 | pyyaml | unpinned | CVE-2020-14343 | CRITICAL | Pin `pyyaml>=6.0`; use `yaml.safe_load()`. Prevents arbitrary code execution via `yaml.load`/`full_load` (< 5.4). |
| 4 | pyyaml | unpinned | CVE-2020-1747 | CRITICAL | Covered by pinning `pyyaml>=6.0`. RCE in PyYAML < 5.3.1. |
| 5 | pyyaml | unpinned | CVE-2017-18342 | CRITICAL | Covered by pinning `pyyaml>=6.0`. `yaml.load` RCE in PyYAML < 5.1. |
| 6 | pytest | unpinned | CVE-2022-42969 (transitive `py`) | LOW | Pin `pytest>=8.0` to pull a patched `py`/replacement. ReDoS in the `py` library; dev/test scope only. |

### Notes by package

- **requests (pinned, 2.18.0):** Confirmed exposure to both CVEs above. Also pulls outdated transitive `urllib3`. HIGH priority.
- **pyyaml (unpinned):** Risk realized only if resolved version is below the fix. Treat as CRITICAL until pinned to `>=6.0` and `safe_load()` is enforced.
- **pytest (unpinned):** No CVEs in `pytest` itself; risk is the legacy `py` dependency. Low impact (test-time only).
- **bcrypt (unpinned):** No notable CVEs in `bcrypt`. Risk is reproducibility, not a known vulnerability. Pin and ensure work factor `rounds>=12` in code.

## Remediation Plan

### 1. Pin and upgrade dependencies
Replace `requirements.txt` with exact, current versions:

```text
pytest==8.4.1
bcrypt==4.3.0
pyyaml==6.0.2
requests==2.32.4
```

> Confirm the latest patch versions on PyPI before committing.

### 2. Enforce safe coding patterns
- Use `yaml.safe_load()` everywhere; never `yaml.load()` with the default loader.
- Verify `bcrypt` hashing uses `rounds>=12`.

### 3. Validate
- Run `pip-audit` (or `safety check`) against the pinned file for authoritative CVE results.
- Regenerate the SBOM so every component carries a version.

### 4. Prevent regressions
- Add `pip-audit` to CI to fail builds on known vulnerabilities.
- Adopt a dependency-update bot (Dependabot / Renovate) to keep pins current.
