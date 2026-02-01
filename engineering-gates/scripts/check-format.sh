#!/bin/bash
# Format check wrapper
# Detects stack and checks if code is formatted.
#
# Exit codes: 0 = pass, 1 = fail, 2 = skip

REPO_PATH="${1:-.}"
cd "$REPO_PATH"

# Detect and check formatting
if [ -f "package.json" ]; then
    # Node.js - check for prettier
    if [ -f "node_modules/.bin/prettier" ]; then
        npx prettier --check . 2>&1
        EXIT_CODE=$?
    elif command -v prettier &> /dev/null; then
        prettier --check . 2>&1
        EXIT_CODE=$?
    elif grep -q '"format"' package.json 2>/dev/null; then
        # Try format:check script
        if grep -q '"format:check"' package.json 2>/dev/null; then
            npm run format:check 2>&1
            EXIT_CODE=$?
        else
            echo "STATUS: SKIP"
            echo "TOOL: prettier"
            echo "MESSAGE: No format check available"
            exit 2
        fi
    else
        echo "STATUS: SKIP"
        echo "TOOL: prettier"
        echo "MESSAGE: Prettier not installed"
        exit 2
    fi

    echo "STATUS: $([ $EXIT_CODE -eq 0 ] && echo 'PASS' || echo 'FAIL')"
    echo "TOOL: prettier"
    exit $([ $EXIT_CODE -eq 0 ] && echo 0 || echo 1)

elif [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; then
    # Python - check with ruff format or black
    if command -v ruff &> /dev/null; then
        ruff format --check . 2>&1
        EXIT_CODE=$?
        TOOL="ruff-format"
    elif command -v black &> /dev/null; then
        black --check . 2>&1
        EXIT_CODE=$?
        TOOL="black"
    else
        echo "STATUS: SKIP"
        echo "TOOL: ruff/black"
        echo "MESSAGE: No Python formatter installed"
        exit 2
    fi

    echo "STATUS: $([ $EXIT_CODE -eq 0 ] && echo 'PASS' || echo 'FAIL')"
    echo "TOOL: $TOOL"
    exit $([ $EXIT_CODE -eq 0 ] && echo 0 || echo 1)

elif [ -f "go.mod" ]; then
    # Go - gofmt returns non-zero if files need formatting
    UNFORMATTED=$(gofmt -l . 2>&1)
    if [ -z "$UNFORMATTED" ]; then
        EXIT_CODE=0
    else
        EXIT_CODE=1
        echo "Unformatted files:"
        echo "$UNFORMATTED"
    fi

    echo "STATUS: $([ $EXIT_CODE -eq 0 ] && echo 'PASS' || echo 'FAIL')"
    echo "TOOL: gofmt"
    exit $([ $EXIT_CODE -eq 0 ] && echo 0 || echo 1)

elif [ -f "Cargo.toml" ]; then
    # Rust
    cargo fmt --check 2>&1
    EXIT_CODE=$?

    echo "STATUS: $([ $EXIT_CODE -eq 0 ] && echo 'PASS' || echo 'FAIL')"
    echo "TOOL: cargo-fmt"
    exit $([ $EXIT_CODE -eq 0 ] && echo 0 || echo 1)

else
    echo "STATUS: SKIP"
    echo "TOOL: unknown"
    echo "MESSAGE: Unknown stack, cannot check format"
    exit 2
fi
