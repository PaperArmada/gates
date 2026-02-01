# Charter Gate Enforcement

**This document is the canonical source of experiment discipline rules for agents.**

Product repos reference this file. If you're working in a product repo, these rules apply to you.

---

## Before ANY Work

1. Read `charter/charter.yaml` in the product repo
2. Run `../charter-gates/scripts/preflight.sh .`
3. Parse the output and check STATUS

```bash
# Example preflight output:
STATUS: CLEAR          # or BLOCKED or WARNING
OUTCOME: proceed       # or freeze or kill or unknown
REVIEW_STATUS: current # or overdue or unknown
ASSUMPTIONS: A1=untested,A2=untested,A3=untested
```

---

## Hard Blocks

You **MUST STOP** and surface an error if any of these are true:

| Condition | How to Check | Required Action |
|-----------|--------------|-----------------|
| Charter missing/incomplete | `preflight.sh` returns `STATUS: BLOCKED` | Fill out charter before any work |
| Past review date | `REVIEW_STATUS: overdue` | Complete review checkpoint first |
| Product killed | `OUTCOME: kill` | No work allowed. Discuss with owner. |
| Product frozen | `OUTCOME: freeze` | Only `fix(AX):` commits allowed |
| Out of scope | Work not in charter assumptions or in `non_goals` | Refuse the work |
| No assumption link | Feature work can't trace to A1, A2, or A3 | Clarify which assumption or refuse |

**When blocked, output this format:**
```
CHARTER BLOCK: [condition from table above]
Required action: [what must happen before work can continue]
```

---

## Commit Format

All commits must use conventional commit format with assumption references for feature work.

**Requires assumption (A1, A2, or A3):**
```
feat(A1): add user onboarding flow
fix(A2): handle empty response edge case
test(A1): add integration tests for auth
refactor(A3): simplify data pipeline
perf(A2): optimize query performance
```

**No assumption needed:**
```
chore: update dependencies
docs: add API documentation
ci: fix deployment workflow
build: configure bundler
style: format code
revert: revert previous commit
```

---

## Scope Discipline

**You should refuse work that:**
- Is listed in `non_goals` in the charter
- Cannot be connected to A1, A2, or A3
- Is "nice to have" but doesn't test an assumption
- Adds infrastructure not required by current assumptions

**When refusing, explain:**
```
This work is outside the current experiment scope.

Charter assumption A1: [statement]
Charter assumption A2: [statement]
Charter assumption A3: [statement]

The requested work does not test any of these assumptions.
```

---

## Review Checkpoint Protocol

When `next_review` date approaches or is passed:

1. **Stop all feature work**
2. Copy `../charter-gates/templates/review.yaml` to `charter/reviews/YYYY-MM-DD.yaml`
3. Fill out the review honestly
4. Update `charter/kill-rubric.yaml` with new `outcome`
5. Set new `next_review` date
6. Only resume work if `outcome: proceed`
