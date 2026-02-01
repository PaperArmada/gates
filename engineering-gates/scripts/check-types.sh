#!/bin/bash
# Type check wrapper
# Detects stack and runs appropriate type checker.
#
# Exit codes: 0 = pass, 1 = fail, 2 = skip

REPO_PATH="${1:-.}"
cd "$REPO_PATH"

# Detect and run type checker
if [ -f "tsconfig.json" ]; then
    # TypeScript
    if [ -f "node_modules/.bin/tsc" ]; then
        npx tsc --noEmit 2>&1
        EXIT_CODE=$?
    elif command -v tsc &> /dev/null; then
        tsc --noEmit 2>&1
        EXIT_CODE=$?
    else
        echo "STATUS: SKIP"
        echo "TOOL: tsc"
        echo "MESSAGE: TypeScript not installed"
        exit 2
    fi

    echo "STATUS: $([ $EXIT_CODE -eq 0 ] && echo 'PASS' || echo 'FAIL')"
    echo "TOOL: tsc"
    exit $([ $EXIT_CODE -eq 0 ] && echo 0 || echo 1)

elif [ -f "package.json" ] && ! [ -f "tsconfig.json" ]; then
    # Plain JavaScript - no type checking
    echo "STATUS: SKIP"
    echo "TOOL: none"
    echo "MESSAGE: JavaScript project, no type checking"
    exit 2

elif [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; then
    # Python - try mypy, then pyright
    if command -v mypy &> /dev/null; then
        mypy . 2>&1
        EXIT_CODE=$?
        TOOL="mypy"
    elif command -v pyright &> /dev/null; then
        pyright 2>&1
        EXIT_CODE=$?
        TOOL="pyright"
    else
        echo "STATUS: SKIP"
        echo "TOOL: mypy/pyright"
        echo "MESSAGE: No Python type checker installed"
        exit 2
    fi

    echo "STATUS: $([ $EXIT_CODE -eq 0 ] && echo 'PASS' || echo 'FAIL')"
    echo "TOOL: $TOOL"
    exit $([ $EXIT_CODE -eq 0 ] && echo 0 || echo 1)

elif [ -f "go.mod" ]; then
    # Go has built-in type checking via compilation
    go build ./... 2>&1
    EXIT_CODE=$?

    echo "STATUS: $([ $EXIT_CODE -eq 0 ] && echo 'PASS' || echo 'FAIL')"
    echo "TOOL: go-build"
    exit $([ $EXIT_CODE -eq 0 ] && echo 0 || echo 1)

elif [ -f "Cargo.toml" ]; then
    # Rust has built-in type checking
    cargo check 2>&1
    EXIT_CODE=$?

    echo "STATUS: $([ $EXIT_CODE -eq 0 ] && echo 'PASS' || echo 'FAIL')"
    echo "TOOL: cargo-check"
    exit $([ $EXIT_CODE -eq 0 ] && echo 0 || echo 1)

else
    echo "STATUS: SKIP"
    echo "TOOL: unknown"
    echo "MESSAGE: Unknown stack, cannot type check"
    exit 2
fi
