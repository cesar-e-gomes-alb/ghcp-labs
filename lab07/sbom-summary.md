# SBOM Summary — lab07

**Format:** CycloneDX 1.6  
**Generated:** 2026-06-19  
**Source:** `requirements.txt`  
**Total dependencies:** 3

## Dependency Inventory

| Package | Installed Version | Latest Version | Category | Status |
|---------|:-----------------:|:--------------:|----------|--------|
| `pytest` | 9.0.3 | 9.1.1 | Testing | ⚠️ Outdated |
| `bcrypt` | 5.0.0 | 5.0.0 | Security / Cryptography | ✅ Current |
| `pyyaml` | 6.0.3 | 6.0.3 | Data Serialization / Configuration | ✅ Current |

## Category Breakdown

| Category | Count | Packages |
|----------|:-----:|----------|
| Testing | 1 | `pytest` |
| Security / Cryptography | 1 | `bcrypt` |
| Data Serialization / Configuration | 1 | `pyyaml` |

## Findings

### Outdated Packages (1)

- **pytest 9.0.3** — version 9.1.1 is available. Update with:
  ```bash
  pip install --upgrade pytest
  ```

### Unpinned Versions

`requirements.txt` does not pin any package versions, which risks reproducibility and supply chain drift. Recommended practice:

```text
pytest==9.1.1
bcrypt==5.0.0
pyyaml==6.0.3
```

Run `pip freeze > requirements.txt` after updating to lock current versions.
