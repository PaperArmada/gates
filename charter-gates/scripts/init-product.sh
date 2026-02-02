#!/bin/bash
# Initialize a new product repo with charter-gates and engineering-gates scaffolding
#
# Usage: ./init-product.sh <product-name>
# Creates: ../product-name/ with full gate structure

set -e

if [ -z "$1" ]; then
    echo "Usage: ./init-product.sh <product-name>"
    echo "Example: ./init-product.sh verify-mvp"
    exit 1
fi

PRODUCT_NAME=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHARTER_GATES="$(dirname "$SCRIPT_DIR")"
DEEPCURRENTS_DIR="$(dirname "$CHARTER_GATES")"
ENGINEERING_GATES="$DEEPCURRENTS_DIR/engineering-gates"
PRODUCT_DIR="$DEEPCURRENTS_DIR/$PRODUCT_NAME"

if [ -d "$PRODUCT_DIR" ]; then
    echo "Error: Directory already exists: $PRODUCT_DIR"
    exit 1
fi

echo "Creating product repo: $PRODUCT_DIR"

# Create directory structure
mkdir -p "$PRODUCT_DIR"/{.claude,charter/reviews,src}

# Initialize git
cd "$PRODUCT_DIR"
git init --quiet

# Copy charter templates
cp "$CHARTER_GATES/templates/charter.yaml" "$PRODUCT_DIR/charter/"
cp "$CHARTER_GATES/templates/kill-rubric.yaml" "$PRODUCT_DIR/charter/"

# Install git hooks
mkdir -p "$PRODUCT_DIR/.git/hooks"

# Charter gate: commit-msg hook
cp "$CHARTER_GATES/hooks/commit-msg" "$PRODUCT_DIR/.git/hooks/"
chmod +x "$PRODUCT_DIR/.git/hooks/commit-msg"

# Engineering gates: pre-commit and pre-push hooks
if [ -d "$ENGINEERING_GATES" ]; then
    cp "$ENGINEERING_GATES/hooks/pre-commit" "$PRODUCT_DIR/.git/hooks/"
    cp "$ENGINEERING_GATES/hooks/pre-push" "$PRODUCT_DIR/.git/hooks/"
    chmod +x "$PRODUCT_DIR/.git/hooks/pre-commit"
    chmod +x "$PRODUCT_DIR/.git/hooks/pre-push"
fi

# Create unified gates.yaml configuration
cat > "$PRODUCT_DIR/gates.yaml" << 'EOF'
# Unified Gate Configuration
# Version 1 schema - see gates/contracts.yaml for full specification

version: 1

# Charter gate configuration
charter:
  # Block work if review date is past due
  enforce_reviews: true

# Engineering gate configuration
engineering:
  # Stack auto-detected if not specified
  # stack: node-typescript

  checks:
    lint: true
    types: true
    tests: true
    format: true

  # Minimum coverage percentage (0 = no threshold)
  coverage_threshold: 0
EOF

# Create CLAUDE.md
cat > "$PRODUCT_DIR/.claude/CLAUDE.md" << 'CLAUDE_EOF'
# PRODUCT_NAME_PLACEHOLDER

## Gates

This product uses the deepcurrents gate system:
- **Charter Gates**: `../charter-gates/agent-instructions.md` - experiment discipline
- **Engineering Gates**: `../engineering-gates/agent-instructions.md` - code quality

## Pre-Work Checklist

```bash
# Charter gate (required before any work):
../charter-gates/scripts/preflight.sh .

# Engineering gate (required before commits):
../engineering-gates/scripts/preflight.sh .
```

If either returns `STATUS: BLOCKED` or `STATUS: FAIL`, resolve before continuing.

## Quick Reference

**Commits**: `feat(A1): description` for features, `chore: description` for maintenance

**Charter**: See `charter/charter.yaml` for hypothesis and assumptions

## Project Context

[TODO: What is this product? Who is it for?]

## Technical Notes

[TODO: Stack, key files, architecture decisions]
CLAUDE_EOF

# Replace placeholder
sed -i "s/PRODUCT_NAME_PLACEHOLDER/$PRODUCT_NAME/g" "$PRODUCT_DIR/.claude/CLAUDE.md"

# Create .gitignore
cat > "$PRODUCT_DIR/.gitignore" << 'EOF'
node_modules/
venv/
.env
.env.local
dist/
build/
*.pyc
__pycache__/
.idea/
.vscode/
*.swp
.DS_Store

# Local gate configuration overrides
.gates.local
EOF

# Create minimal README
cat > "$PRODUCT_DIR/README.md" << EOF
# $PRODUCT_NAME

> [TODO: One sentence matching JTBD from charter]

## Status

Experiment phase: **Pre-charter**

## Setup

1. Fill out \`charter/charter.yaml\`
2. Run \`../charter-gates/scripts/preflight.sh .\`
3. Begin development

## Charter

See \`charter/charter.yaml\` for experiment hypothesis and assumptions.
EOF

echo ""
echo "========================================="
echo "Created: $PRODUCT_DIR"
echo "========================================="
echo ""
echo "Installed gates:"
echo "  - Charter gates (commit-msg hook)"
echo "  - Engineering gates (pre-commit, pre-push hooks)"
echo ""
echo "Next steps:"
echo "1. cd $PRODUCT_DIR"
echo "2. Edit charter/charter.yaml (required before any feature work)"
echo "3. Run: ../charter-gates/scripts/preflight.sh ."
echo "4. Edit .claude/CLAUDE.md to add project context"
echo ""
