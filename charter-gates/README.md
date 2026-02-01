# Charter Gates

Programmatic enforcement of experiment discipline for agent-driven development.

**"Should we build this at all?"**

## Quick Start

### Create a new product:
```bash
./charter-gates/scripts/init-product.sh my-product
cd my-product
# Fill out charter/charter.yaml FIRST
../charter-gates/scripts/preflight.sh .
```

### Check if you can work:
```bash
../charter-gates/scripts/preflight.sh .
# STATUS: CLEAR | BLOCKED | WARNING
```

## Architecture

```
deepcurrents/
├── charter-gates/           # Experiment discipline enforcement
│   ├── scripts/
│   │   ├── preflight.sh     # Gate check (run before work)
│   │   ├── validate-commit.sh
│   │   ├── validate.sh
│   │   ├── init-product.sh
│   │   └── scope-check.sh
│   ├── templates/
│   │   ├── charter.yaml
│   │   ├── kill-rubric.yaml
│   │   └── review.yaml
│   ├── hooks/
│   │   └── commit-msg
│   ├── contracts.yaml
│   └── agent-instructions.md
│
├── engineering-gates/       # Code quality enforcement
│   └── ...
│
└── product-*/               # Product repos
    ├── .claude/CLAUDE.md
    └── charter/
        ├── charter.yaml
        └── reviews/
```

## What This Enforces

| Gate | Question | Hard Block |
|------|----------|------------|
| Charter exists | Is there a hypothesis? | commit-msg hook |
| Assumptions defined | What are we testing? | commit-msg hook |
| Review current | Have we checked in? | preflight.sh |
| Not killed | Should we continue? | preflight.sh |
| In scope | Does this test an assumption? | agent instructions |

## Contracts

See `contracts.yaml` for stable interfaces:
- Preflight output format is stable
- Commit format is frozen
- Charter required fields are frozen

## Scope

Run `./scripts/scope-check.sh` to verify bounds:
- Max 15 files
- Max 5 scripts
- Max 5 templates
