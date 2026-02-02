# Gates Repository

This is the **gates** monorepo containing enforcement toolkits for agent-driven development.

## Repository Structure

This is a monorepo with subdirectories for each gate type. To see current structure:

```bash
tree -L 2 --dirsfirst
```

Each subdirectory (`charter-gates/`, `engineering-gates/`) has its own CLAUDE.md with specific guidance for that module.

---

## Workflow Practices

### Before Starting Work on a Ticket

**Always comment on the GitHub issue before beginning work.** This signals to other agents and humans that the ticket is actively being worked on.

```bash
gh issue comment <number> --body "Starting work on this issue."
```

This prevents:
- Duplicate effort from parallel agents
- Conflicts from simultaneous changes
- Wasted work on already-in-progress features

### Commit Format

This repo uses conventional commits:

```
feat: add new capability
fix: correct a bug
docs: documentation only
refactor: code change that doesn't add features or fix bugs
chore: maintenance tasks
```

No assumption references (A1, A2, etc.) - those are for product repos, not governance repos.

---

## Dogfooding Gates

This repo should practice what it preaches. Current self-enforcement:

- **Scope constraints**: Run `./charter-gates/scripts/scope-check.sh` before adding files
- **Commit discipline**: Use conventional commits
- **Issue workflow**: Comment before working, reference issues in commits

Future consideration: Apply engineering-gates checks to this repo's own scripts.

---

## Adding New Gates

When proposing a new gate type (beyond charter and engineering):

1. Open an issue describing the gate's purpose
2. Define what question it answers (like "Should we build this?" or "Is it built correctly?")
3. Draft the contracts.yaml interface first
4. Keep scope minimal - gates are enforcement, not features
