# Engineering Gate Enforcement

**This document is the canonical source of code quality rules for agents.**

Product repos reference this file. If you're working in a product repo, these rules apply to you.

---

## Before ANY Commit

1. Run `../engineering-gates/scripts/preflight.sh .`
2. Parse the output and check STATUS

```bash
# Example preflight output:
STATUS: PASS           # or FAIL
LINT: pass             # or fail or skip
TYPES: pass            # or fail or skip
TESTS: pass            # or fail or skip
FORMAT: pass           # or fail or skip
COVERAGE: 85%          # if tests ran
```

---

## Hard Blocks

You **MUST FIX** issues before committing if any of these are true:

| Condition | How to Check | Required Action |
|-----------|--------------|-----------------|
| Lint errors | `LINT: fail` | Fix lint errors |
| Type errors | `TYPES: fail` | Fix type errors |
| Format issues | `FORMAT: fail` | Run formatter |
| Tests failing | `TESTS: fail` | Fix failing tests |
| Coverage below threshold | `COVERAGE: NN%` below threshold | Add tests |

**When blocked, output this format:**
```
ENGINEERING BLOCK: [condition from table above]
Required action: [what must happen before commit]
```

---

## Workflow

### Before writing code:
```bash
# Check current state
../engineering-gates/scripts/preflight.sh .
```

### Before each commit:
```bash
# Run checks
../engineering-gates/scripts/preflight.sh .

# If FAIL, fix issues first
# If PASS, proceed with commit
```

### The hooks will enforce this:
- **pre-commit**: Blocks if lint, types, or format fail
- **pre-push**: Blocks if tests fail or coverage is below threshold

---

## Fix Commands by Stack

### Node/TypeScript
```bash
# Lint
npm run lint          # check
npm run lint:fix      # auto-fix

# Types
npm run typecheck     # or: npx tsc --noEmit

# Format
npm run format        # or: npx prettier --write .

# Tests
npm test
```

### Python
```bash
# Lint
ruff check .          # or: flake8 .
ruff check . --fix    # auto-fix

# Types
mypy .                # or: pyright .

# Format
ruff format .         # or: black .

# Tests
pytest
pytest --cov          # with coverage
```

### Go
```bash
# Lint + Format
go fmt ./...
golangci-lint run

# Tests
go test ./...
go test -cover ./...
```

---

## Configuration

Products can customize checks via `engineering.yaml`:

```yaml
stack: node-typescript    # auto-detected if omitted

checks:
  lint: true
  types: true
  tests: true
  format: true

coverage_threshold: 80    # 0 = no threshold

# Optional overrides
lint_config: .eslintrc.custom.js
test_command: npm run test:ci
```

---

## When Checks Are Skipped

A check returns `skip` when:
- The stack doesn't support it (e.g., types for plain JavaScript)
- The product disabled it in `engineering.yaml`
- Required tooling is not installed

Skipped checks don't block commits.

---

## Integration with Charter Gates

Both gate systems apply:

1. **Charter gates** answer: "Should we build this?" (run at session start)
2. **Engineering gates** answer: "Is it built correctly?" (run before commits)

A typical workflow:
```bash
# Start of session
../charter-gates/scripts/preflight.sh .     # Check experiment status

# Before each commit
../engineering-gates/scripts/preflight.sh . # Check code quality
```
