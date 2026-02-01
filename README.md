# Gates

Programmatic enforcement for agent-driven development.

Gates provides hard enforcement for two critical questions:
- **Charter Gates**: "Should we build this at all?" - Experiment discipline
- **Engineering Gates**: "Is it built correctly?" - Code quality

## Why Gates?

When agents write code, they need more than prompts and hopes. They need hard blocks they cannot bypass. Gates provides:

- **Machine-readable status** - Scripts return structured output agents can parse
- **Git hooks** - Hard blocks at commit and push time
- **Stable contracts** - Interfaces that won't break between versions

## Quick Start

```bash
# Clone the repo
git clone https://github.com/paperarmada/gates.git

# Create a new product
./gates/charter-gates/scripts/init-product.sh my-product

# Check if you can work
cd my-product
../gates/charter-gates/scripts/preflight.sh .
../gates/engineering-gates/scripts/preflight.sh .
```

## Architecture

```
gates/
├── charter-gates/           # Experiment discipline
│   ├── scripts/             # preflight.sh, validate-commit.sh, etc.
│   ├── templates/           # charter.yaml, kill-rubric.yaml
│   ├── hooks/               # commit-msg
│   └── agent-instructions.md
│
└── engineering-gates/       # Code quality
    ├── scripts/             # preflight.sh, check-*.sh
    ├── hooks/               # pre-commit, pre-push
    └── agent-instructions.md
```

## Documentation

- [Charter Gates README](./charter-gates/README.md)
- [Engineering Gates README](./engineering-gates/README.md)
- [Charter Gates Agent Instructions](./charter-gates/agent-instructions.md)
- [Engineering Gates Agent Instructions](./engineering-gates/agent-instructions.md)

## License

MIT
