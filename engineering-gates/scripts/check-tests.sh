#!/bin/bash
# Test check wrapper
# Detects stack and runs appropriate test runner.
#
# Exit codes: 0 = pass, 1 = fail, 2 = skip

REPO_PATH="${1:-.}"
cd "$REPO_PATH"

# Detect and run tests
if [ -f "package.json" ]; then
    # Node.js
    if grep -q '"test"' package.json 2>/dev/null; then
        # Check if test script is just "echo" (placeholder)
        TEST_SCRIPT=$(grep '"test"' package.json | head -1)
        if echo "$TEST_SCRIPT" | grep -q 'echo.*no test'; then
            echo "STATUS: SKIP"
            echo "TOOL: npm"
            echo "MESSAGE: No tests configured"
            exit 2
        fi

        npm test 2>&1
        EXIT_CODE=$?

        # Try to extract coverage from output
        # (Jest and similar output coverage percentage)

        echo "STATUS: $([ $EXIT_CODE -eq 0 ] && echo 'PASS' || echo 'FAIL')"
        echo "TOOL: npm-test"
        exit $([ $EXIT_CODE -eq 0 ] && echo 0 || echo 1)
    else
        echo "STATUS: SKIP"
        echo "TOOL: npm"
        echo "MESSAGE: No test script in package.json"
        exit 2
    fi

elif [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; then
    # Python
    if command -v pytest &> /dev/null; then
        OUTPUT=$(pytest --tb=short 2>&1)
        EXIT_CODE=$?

        # Try to get coverage if pytest-cov is available
        if pytest --co -q 2>&1 | grep -q "test"; then
            COV_OUTPUT=$(pytest --cov --cov-report=term-missing 2>&1 | grep "TOTAL" | awk '{print $NF}')
            [ -n "$COV_OUTPUT" ] && echo "COVERAGE: $COV_OUTPUT"
        fi

        echo "STATUS: $([ $EXIT_CODE -eq 0 ] && echo 'PASS' || echo 'FAIL')"
        echo "TOOL: pytest"
        exit $([ $EXIT_CODE -eq 0 ] && echo 0 || echo 1)
    elif command -v python &> /dev/null; then
        python -m unittest discover 2>&1
        EXIT_CODE=$?

        echo "STATUS: $([ $EXIT_CODE -eq 0 ] && echo 'PASS' || echo 'FAIL')"
        echo "TOOL: unittest"
        exit $([ $EXIT_CODE -eq 0 ] && echo 0 || echo 1)
    else
        echo "STATUS: SKIP"
        echo "TOOL: pytest"
        echo "MESSAGE: No Python test runner installed"
        exit 2
    fi

elif [ -f "go.mod" ]; then
    # Go
    OUTPUT=$(go test ./... 2>&1)
    EXIT_CODE=$?

    # Get coverage
    COV_OUTPUT=$(go test -cover ./... 2>&1 | grep -oE '[0-9]+\.[0-9]+%' | tail -1)
    [ -n "$COV_OUTPUT" ] && echo "COVERAGE: $COV_OUTPUT"

    echo "STATUS: $([ $EXIT_CODE -eq 0 ] && echo 'PASS' || echo 'FAIL')"
    echo "TOOL: go-test"
    exit $([ $EXIT_CODE -eq 0 ] && echo 0 || echo 1)

elif [ -f "Cargo.toml" ]; then
    # Rust
    cargo test 2>&1
    EXIT_CODE=$?

    echo "STATUS: $([ $EXIT_CODE -eq 0 ] && echo 'PASS' || echo 'FAIL')"
    echo "TOOL: cargo-test"
    exit $([ $EXIT_CODE -eq 0 ] && echo 0 || echo 1)

else
    echo "STATUS: SKIP"
    echo "TOOL: unknown"
    echo "MESSAGE: Unknown stack, cannot run tests"
    exit 2
fi
