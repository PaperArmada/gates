#!/bin/bash
# Governance repo scope check
# Verifies the governance repo stays within its defined bounds.
#
# Usage: ./scope-check.sh
# Exit codes: 0 = within bounds, 1 = exceeded bounds

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GOVERNANCE_DIR="$(dirname "$SCRIPT_DIR")"

# Bounds from contracts.yaml
MAX_FILES=15
MAX_SCRIPTS=5
MAX_TEMPLATES=5

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

VIOLATIONS=0

echo "========================================="
echo "Governance Scope Check"
echo "========================================="
echo ""

# Count files (excluding .git and hidden files)
TOTAL_FILES=$(find "$GOVERNANCE_DIR" -type f -not -path '*/.git/*' -not -name '.*' | wc -l)
echo -n "Total files: $TOTAL_FILES / $MAX_FILES "
if [ "$TOTAL_FILES" -gt "$MAX_FILES" ]; then
    echo -e "${RED}EXCEEDED${NC}"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}OK${NC}"
fi

# Count scripts
SCRIPT_COUNT=$(find "$GOVERNANCE_DIR/scripts" -type f -name "*.sh" 2>/dev/null | wc -l)
echo -n "Scripts: $SCRIPT_COUNT / $MAX_SCRIPTS "
if [ "$SCRIPT_COUNT" -gt "$MAX_SCRIPTS" ]; then
    echo -e "${RED}EXCEEDED${NC}"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}OK${NC}"
fi

# Count templates
TEMPLATE_COUNT=$(find "$GOVERNANCE_DIR/templates" -type f 2>/dev/null | wc -l)
echo -n "Templates: $TEMPLATE_COUNT / $MAX_TEMPLATES "
if [ "$TEMPLATE_COUNT" -gt "$MAX_TEMPLATES" ]; then
    echo -e "${RED}EXCEEDED${NC}"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}OK${NC}"
fi

echo ""

# Check for forbidden content patterns
echo "Checking for scope violations..."

# Look for signs of product code
PRODUCT_CODE=$(find "$GOVERNANCE_DIR" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" \) -not -path '*/.git/*' 2>/dev/null)
if [ -n "$PRODUCT_CODE" ]; then
    echo -e "${RED}VIOLATION${NC}: Product code files found:"
    echo "$PRODUCT_CODE"
    VIOLATIONS=$((VIOLATIONS + 1))
else
    echo -e "${GREEN}OK${NC}: No product code files"
fi

# Look for package.json, requirements.txt, go.mod (signs of a library)
PACKAGE_FILES=$(find "$GOVERNANCE_DIR" -type f \( -name "package.json" -o -name "requirements.txt" -o -name "go.mod" -o -name "Cargo.toml" \) -not -path '*/.git/*' 2>/dev/null)
if [ -n "$PACKAGE_FILES" ]; then
    echo -e "${YELLOW}WARNING${NC}: Package/dependency files found (may indicate library creep):"
    echo "$PACKAGE_FILES"
else
    echo -e "${GREEN}OK${NC}: No package/dependency files"
fi

echo ""

# List all files for review
echo "Current file inventory:"
find "$GOVERNANCE_DIR" -type f -not -path '*/.git/*' -not -name '.*' | sort | while read -r f; do
    REL_PATH="${f#$GOVERNANCE_DIR/}"
    echo "  $REL_PATH"
done

echo ""
echo "========================================="
if [ "$VIOLATIONS" -gt 0 ]; then
    echo -e "${RED}SCOPE EXCEEDED${NC}: $VIOLATIONS violation(s)"
    echo ""
    echo "The governance repo has grown beyond its bounds."
    echo "Review contracts.yaml for allowed scope."
    echo "Remove files or increase limits (with justification)."
    exit 1
else
    echo -e "${GREEN}WITHIN BOUNDS${NC}"
    exit 0
fi
