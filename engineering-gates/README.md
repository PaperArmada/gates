# Engineering Gates

Programmatic enforcement of code quality for agent-driven development.

**"Is the code built correctly?"**

## Quick Start

### Check if you can commit:
```bash
../engineering-gates/scripts/preflight.sh .
# STATUS: PASS | FAIL
```

### Configure for your stack:
Create `engineering.yaml` in your product repo:
```yaml
stack: node-typescript  # or: python, go, rust
checks:
  lint: true
  types: true
  tests: true
  format: true
coverage_threshold: 80
```

## Architecture

```
deepcurrents/
├── charter-gates/           # Experiment discipline
├── engineering-gates/       # Code quality (this repo)
│   ├── scripts/
│   │   ├── preflight.sh     # Aggregated gate check
│   │   ├── check-lint.sh    # Lint wrapper
│   │   ├── check-types.sh   # Type check wrapper
│   │   ├── check-tests.sh   # Test + coverage wrapper
│   │   └── check-format.sh  # Format check wrapper
│   ├── hooks/
│   │   ├── pre-commit       # Block commits if checks fail
│   │   └── pre-push         # Block push if tests fail
│   ├── configs/
│   │   └── (baseline configs for common stacks)
│   ├── contracts.yaml
│   └── agent-instructions.md
│
└── product-*/
    ├── engineering.yaml     # Product's engineering config
    └── ...
```

## What This Enforces

| Gate | Question | Hard Block |
|------|----------|------------|
| Lint | Any lint errors? | pre-commit hook |
| Types | Type errors? | pre-commit hook |
| Format | Code formatted? | pre-commit hook |
| Tests | Tests passing? | pre-push hook |
| Coverage | Coverage threshold met? | pre-push hook |

## Contracts

See `contracts.yaml` for stable interfaces:
- Preflight output format is stable
- Check scripts return machine-readable status
- Exit codes are frozen
