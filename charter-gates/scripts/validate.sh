#!/bin/bash
# Governance validation script
# Run this to check if a product repo is in compliance.
#
# Usage: ./validate.sh [path-to-product-repo]
# If no path provided, uses current directory.

set -e

REPO_PATH="${1:-.}"
CHARTER_PATH="$REPO_PATH/governance/charter.yaml"
RUBRIC_PATH="$REPO_PATH/governance/kill-rubric.yaml"
REVIEWS_PATH="$REPO_PATH/governance/reviews"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo "========================================="
echo "Governance Validation"
echo "Repo: $REPO_PATH"
echo "========================================="
echo ""

# 1. Check charter exists
echo "Checking charter..."
if [ ! -f "$CHARTER_PATH" ]; then
    echo -e "${RED}FAIL${NC}: No charter.yaml found at $CHARTER_PATH"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}OK${NC}: Charter exists"

    # Check required fields are filled
    check_field() {
        local field=$1
        local value=$(grep "^$field:" "$CHARTER_PATH" | head -1 | sed "s/$field: *//" | tr -d '"')
        if [ -z "$value" ]; then
            echo -e "${RED}FAIL${NC}: Charter field '$field' is empty"
            ERRORS=$((ERRORS + 1))
        fi
    }

    check_field "  codename"
    check_field "jtbd"
    check_field "hypothesis"

    # Check at least one assumption is defined
    A1_STMT=$(grep -A1 "^  A1:" "$CHARTER_PATH" 2>/dev/null | grep "statement:" | sed 's/.*statement: *//' | tr -d '"')
    if [ -z "$A1_STMT" ]; then
        echo -e "${RED}FAIL${NC}: No assumptions defined (A1 statement empty)"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}OK${NC}: At least one assumption defined"
    fi

    # Check kill condition
    KILL_DATE=$(grep "^  date:" "$CHARTER_PATH" | head -1 | sed 's/.*date: *//' | tr -d '"')
    if [ -z "$KILL_DATE" ]; then
        echo -e "${YELLOW}WARN${NC}: Kill condition date not set"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

echo ""

# 2. Check if past review date
echo "Checking review status..."
if [ -f "$RUBRIC_PATH" ]; then
    NEXT_REVIEW=$(grep "^next_review:" "$RUBRIC_PATH" | sed 's/next_review: *//' | tr -d '"')
    if [ -n "$NEXT_REVIEW" ]; then
        TODAY=$(date +%Y-%m-%d)
        if [[ "$TODAY" > "$NEXT_REVIEW" ]]; then
            echo -e "${RED}FAIL${NC}: Past review date ($NEXT_REVIEW). Complete review before new work."
            ERRORS=$((ERRORS + 1))
        else
            echo -e "${GREEN}OK${NC}: Not past review date (next: $NEXT_REVIEW)"
        fi
    else
        echo -e "${YELLOW}WARN${NC}: No next_review date set in kill-rubric.yaml"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${YELLOW}WARN${NC}: No kill-rubric.yaml found"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""

# 3. Check for kill condition
echo "Checking kill status..."
if [ -f "$RUBRIC_PATH" ]; then
    OUTCOME=$(grep "^outcome:" "$RUBRIC_PATH" | sed 's/outcome: *//' | tr -d '"')
    if [ "$OUTCOME" = "kill" ]; then
        echo -e "${RED}FAIL${NC}: Product is marked KILL. No new feature work allowed."
        ERRORS=$((ERRORS + 1))
    elif [ "$OUTCOME" = "freeze" ]; then
        echo -e "${YELLOW}WARN${NC}: Product is FROZEN. Only maintenance allowed."
        WARNINGS=$((WARNINGS + 1))
    elif [ "$OUTCOME" = "proceed" ]; then
        echo -e "${GREEN}OK${NC}: Product status is PROCEED"
    else
        echo -e "${YELLOW}WARN${NC}: Product outcome not yet evaluated"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

echo ""

# 4. Check git hooks installed
echo "Checking enforcement..."
if [ -f "$REPO_PATH/.git/hooks/commit-msg" ]; then
    echo -e "${GREEN}OK${NC}: commit-msg hook installed"
else
    echo -e "${YELLOW}WARN${NC}: commit-msg hook not installed"
    echo "    Run: cp governance/hooks/commit-msg .git/hooks/ && chmod +x .git/hooks/commit-msg"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""
echo "========================================="
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}BLOCKED${NC}: $ERRORS error(s), $WARNINGS warning(s)"
    echo "Fix errors before proceeding with feature work."
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}CAUTION${NC}: $WARNINGS warning(s)"
    echo "Consider addressing warnings."
    exit 0
else
    echo -e "${GREEN}CLEAR${NC}: All governance checks passed"
    exit 0
fi
