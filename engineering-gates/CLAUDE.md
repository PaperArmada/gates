# Engineering Gates Repository

This is the **engineering-gates** toolkit. It enforces code quality for the deepcurrents portfolio.

**If you're working in a product repo, read `agent-instructions.md` instead.**

---

## What This Repo Is

Enforcement for the question: **"Is the code built correctly?"**

- Scripts that wrap standard tools (eslint, tsc, pytest, etc.)
- Hooks that block commits/pushes when checks fail
- Machine-readable output for agent consumption

## What This Repo Is NOT

- Experiment discipline (see `../charter-gates/`)
- Reimplementations of standard tools
- A place for product code

---

## Design Principles

1. **Wrap, don't reimplement** - Use standard tools, provide consistent interface
2. **Machine-readable output** - Agents parse STATUS: PASS/FAIL
3. **Hard blocks via hooks** - Agents cannot bypass
4. **Stack detection** - Automatically detect Node, Python, Go, etc.

---

## Directory Structure

```
engineering-gates/
├── scripts/
│   ├── preflight.sh        # Run all checks, aggregate results
│   ├── check-lint.sh       # Lint check wrapper
│   ├── check-types.sh      # Type check wrapper
│   ├── check-tests.sh      # Test + coverage wrapper
│   └── check-format.sh     # Format check wrapper
├── hooks/
│   ├── pre-commit          # Lint + types + format
│   └── pre-push            # Tests + coverage
├── configs/
│   └── (baseline configs)
├── contracts.yaml
├── agent-instructions.md
├── CLAUDE.md
└── README.md
```

---

## Commit Format

This repo uses conventional commits without assumption references:

```
feat: add Python stack detection
fix: handle missing package.json gracefully
docs: update contracts
chore: clean up unused code
```
