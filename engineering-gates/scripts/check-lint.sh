#!/bin/bash
# Lint check wrapper
# Detects stack and runs appropriate linter.
#
# Exit codes: 0 = pass, 1 = fail, 2 = skip

REPO_PATH="${1:-.}"
cd "$REPO_PATH"

# Detect and run linter
if [ -f "package.json" ]; then
    # Node.js - try npm script first, then direct eslint
    if grep -q '"lint"' package.json 2>/dev/null; then
        npm run lint --silent 2>&1
        EXIT_CODE=$?
    elif [ -f "node_modules/.bin/eslint" ]; then
        npx eslint . 2>&1
        EXIT_CODE=$?
    elif command -v eslint &> /dev/null; then
        eslint . 2>&1
        EXIT_CODE=$?
    else
        echo "STATUS: SKIP"
        echo "TOOL: eslint"
        echo "MESSAGE: ESLint not installed"
        exit 2
    fi

    echo "STATUS: $([ $EXIT_CODE -eq 0 ] && echo 'PASS' || echo 'FAIL')"
    echo "TOOL: eslint"
    exit $([ $EXIT_CODE -eq 0 ] && echo 0 || echo 1)

elif [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; then
    # Python - try ruff, then flake8
    if command -v ruff &> /dev/null; then
        ruff check . 2>&1
        EXIT_CODE=$?
        TOOL="ruff"
    elif command -v flake8 &> /dev/null; then
        flake8 . 2>&1
        EXIT_CODE=$?
        TOOL="flake8"
    else
        echo "STATUS: SKIP"
        echo "TOOL: ruff/flake8"
        echo "MESSAGE: No Python linter installed"
        exit 2
    fi

    echo "STATUS: $([ $EXIT_CODE -eq 0 ] && echo 'PASS' || echo 'FAIL')"
    echo "TOOL: $TOOL"
    exit $([ $EXIT_CODE -eq 0 ] && echo 0 || echo 1)

elif [ -f "go.mod" ]; then
    # Go
    if command -v golangci-lint &> /dev/null; then
        golangci-lint run 2>&1
        EXIT_CODE=$?
        TOOL="golangci-lint"
    else
        # Fall back to go vet
        go vet ./... 2>&1
        EXIT_CODE=$?
        TOOL="go-vet"
    fi

    echo "STATUS: $([ $EXIT_CODE -eq 0 ] && echo 'PASS' || echo 'FAIL')"
    echo "TOOL: $TOOL"
    exit $([ $EXIT_CODE -eq 0 ] && echo 0 || echo 1)

elif [ -f "Cargo.toml" ]; then
    # Rust
    if command -v cargo &> /dev/null; then
        cargo clippy -- -D warnings 2>&1
        EXIT_CODE=$?
    else
        echo "STATUS: SKIP"
        echo "TOOL: clippy"
        echo "MESSAGE: Cargo not installed"
        exit 2
    fi

    echo "STATUS: $([ $EXIT_CODE -eq 0 ] && echo 'PASS' || echo 'FAIL')"
    echo "TOOL: clippy"
    exit $([ $EXIT_CODE -eq 0 ] && echo 0 || echo 1)

else
    echo "STATUS: SKIP"
    echo "TOOL: unknown"
    echo "MESSAGE: Unknown stack, cannot lint"
    exit 2
fi
