# Charter Gates Repository

This is the **charter-gates** toolkit. It enforces experiment discipline for the deepcurrents portfolio.

**If you're working in a product repo, read `agent-instructions.md` instead.**

---

## What This Repo Is

Enforcement for the question: **"Should we build this at all?"**

- Scripts that validate experiment gates
- Templates for charters and rubrics
- Contracts defining stable interfaces

## What This Repo Is NOT

- Engineering/code quality enforcement (see `../engineering-gates/`)
- A place for product code
- A place for shared libraries

---

## Scope Constraints

Before adding anything, ask: **"Does this enforce experiment discipline?"**

If no → it doesn't belong here.

**Hard limits (from contracts.yaml):**
- Max 15 files total
- Max 5 scripts
- Max 5 templates

Run `./scripts/scope-check.sh` to verify compliance.

---

## Directory Structure

```
charter-gates/
├── scripts/
│   ├── preflight.sh        # Pre-work gate check
│   ├── validate-commit.sh  # Commit message validation
│   ├── validate.sh         # Full compliance report
│   ├── init-product.sh     # New product scaffolding
│   └── scope-check.sh      # Self-check
├── templates/
│   ├── charter.yaml
│   ├── kill-rubric.yaml
│   ├── review.yaml
│   └── infra-boundaries.yaml
├── hooks/
│   └── commit-msg
├── contracts.yaml
├── agent-instructions.md
├── CLAUDE.md
└── README.md
```

---

## Commit Format

This repo uses conventional commits without assumption references:

```
feat: add scope-check script
fix: handle empty charter fields in preflight
docs: update contracts.yaml
chore: clean up unused code
```
