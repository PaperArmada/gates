#!/bin/bash
# Engineering gates scope check
# Verifies the engineering-gates repo stays within its defined bounds.
#
# Usage: ./scope-check.sh
# Exit codes: 0 = within bounds, 1 = exceeded bounds

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINEERING_GATES="$(dirname "$SCRIPT_DIR")"

# Bounds
MAX_FILES=15
MAX_SCRIPTS=6
MAX_HOOKS=3

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

VIOLATIONS=0

echo "========================================="
echo "Engineering Gates Scope Check"
echo "========================================="
echo ""

# Count files (excluding .git and hidden files)
TOTAL_FILES=$(find "$ENGINEERING_GATES" -type f -not -path '*/.git/*' -not -name '.*' | wc -l)
echo -n "Total files: $TOTAL_FILES / $MAX_FILES "
if [ "$TOTAL_FILES" -gt "$MAX_FILES" ]; then
    echo -e "${RED}EXCEEDED${NC}"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}OK${NC}"
fi

# Count scripts
SCRIPT_COUNT=$(find "$ENGINEERING_GATES/scripts" -type f -name "*.sh" 2>/dev/null | wc -l)
echo -n "Scripts: $SCRIPT_COUNT / $MAX_SCRIPTS "
if [ "$SCRIPT_COUNT" -gt "$MAX_SCRIPTS" ]; then
    echo -e "${RED}EXCEEDED${NC}"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}OK${NC}"
fi

# Count hooks
HOOK_COUNT=$(find "$ENGINEERING_GATES/hooks" -type f 2>/dev/null | wc -l)
echo -n "Hooks: $HOOK_COUNT / $MAX_HOOKS "
if [ "$HOOK_COUNT" -gt "$MAX_HOOKS" ]; then
    echo -e "${RED}EXCEEDED${NC}"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}OK${NC}"
fi

echo ""

# Check for scope violations
echo "Checking for scope violations..."

# Look for signs of reimplemented tools
REIMPLEMENT=$(grep -r "eslint" "$ENGINEERING_GATES/scripts" 2>/dev/null | grep -v "npx\|command -v\|node_modules" | head -1)
if [ -n "$REIMPLEMENT" ]; then
    echo -e "${YELLOW}WARNING${NC}: Possible tool reimplementation found"
else
    echo -e "${GREEN}OK${NC}: No tool reimplementations"
fi

# Look for product code
PRODUCT_CODE=$(find "$ENGINEERING_GATES" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" \) -not -path '*/.git/*' 2>/dev/null)
if [ -n "$PRODUCT_CODE" ]; then
    echo -e "${RED}VIOLATION${NC}: Product code files found"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}OK${NC}: No product code files"
fi

echo ""

# List all files
echo "Current file inventory:"
find "$ENGINEERING_GATES" -type f -not -path '*/.git/*' -not -name '.*' | sort | while read -r f; do
    REL_PATH="${f#$ENGINEERING_GATES/}"
    echo "  $REL_PATH"
done

echo ""
echo "========================================="
if [ "$VIOLATIONS" -gt 0 ]; then
    echo -e "${RED}SCOPE EXCEEDED${NC}: $VIOLATIONS violation(s)"
    exit 1
else
    echo -e "${GREEN}WITHIN BOUNDS${NC}"
    exit 0
fi
