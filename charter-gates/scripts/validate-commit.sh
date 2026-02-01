#!/bin/bash
# Commit message validation script
# Called by thin wrapper hooks in product repos.
#
# Usage: validate-commit.sh <commit-msg-file> [charter-path]
# Exit codes: 0 = allow, 1 = reject
#
# Interface version: 1 (see contracts.yaml)

set -e

COMMIT_MSG_FILE="$1"
CHARTER_PATH="${2:-charter/charter.yaml}"

if [ -z "$COMMIT_MSG_FILE" ] || [ ! -f "$COMMIT_MSG_FILE" ]; then
    echo "Usage: validate-commit.sh <commit-msg-file> [charter-path]"
    exit 1
fi

COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Skip merge commits and empty messages
if echo "$COMMIT_MSG" | grep -qE "^Merge "; then
    exit 0
fi

# Types that REQUIRE assumption reference
REQUIRES_ASSUMPTION="^(feat|fix|test|refactor|perf)\("

# Types that DON'T require assumption reference
NO_ASSUMPTION_REQUIRED="^(chore|docs|ci|build|style|revert):"

# Valid patterns
VALID_WITH_ASSUMPTION="^(feat|fix|test|refactor|perf)\(A[1-3]\): .+"
VALID_WITHOUT_ASSUMPTION="^(chore|docs|ci|build|style|revert): .+"

# Check if commit requires assumption
if echo "$COMMIT_MSG" | grep -qE "$REQUIRES_ASSUMPTION"; then
    if ! echo "$COMMIT_MSG" | grep -qE "$VALID_WITH_ASSUMPTION"; then
        echo "CHARTER BLOCK: Invalid commit format"
        echo ""
        echo "Feature work must reference a charter assumption."
        echo ""
        echo "Your commit: $COMMIT_MSG"
        echo ""
        echo "Required format: type(A1|A2|A3): description"
        echo "Examples:"
        echo "  feat(A1): add user authentication"
        echo "  fix(A2): handle edge case in parser"
        echo ""
        exit 1
    fi

    # Extract assumption and verify it exists in charter
    ASSUMPTION=$(echo "$COMMIT_MSG" | grep -oE 'A[1-3]' | head -1)

    if [ -f "$CHARTER_PATH" ]; then
        STATEMENT=$(grep -A1 "^  $ASSUMPTION:" "$CHARTER_PATH" 2>/dev/null | grep "statement:" | sed 's/.*statement: *//' | tr -d '"' | tr -d "'")

        if [ -z "$STATEMENT" ]; then
            echo "CHARTER BLOCK: Assumption $ASSUMPTION not defined"
            echo ""
            echo "The assumption referenced in your commit has no statement in the charter."
            echo "Charter path: $CHARTER_PATH"
            echo ""
            echo "Required action: Fill out $ASSUMPTION in charter/charter.yaml before this commit."
            exit 1
        fi
    else
        echo "CHARTER BLOCK: No charter found"
        echo ""
        echo "Cannot validate assumption reference without a charter."
        echo "Expected: $CHARTER_PATH"
        echo ""
        echo "Required action: Initialize charter/charter.yaml"
        exit 1
    fi

elif echo "$COMMIT_MSG" | grep -qE "$VALID_WITHOUT_ASSUMPTION"; then
    exit 0

else
    echo "CHARTER BLOCK: Invalid commit format"
    echo ""
    echo "Commit message does not follow conventional commit format."
    echo ""
    echo "Your commit: $COMMIT_MSG"
    echo ""
    echo "Valid formats:"
    echo "  feat(A1): description     (feature testing assumption 1)"
    echo "  fix(A2): description      (fix related to assumption 2)"
    echo "  chore: description        (no assumption needed)"
    echo "  docs: description         (no assumption needed)"
    echo ""
    exit 1
fi

exit 0
