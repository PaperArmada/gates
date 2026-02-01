#!/bin/bash
# Engineering gates preflight check
# Run this BEFORE any commit. Returns machine-readable status.
#
# Usage: ./preflight.sh [path-to-product-repo]
#
# Exit codes (per contracts.yaml):
#   0 = All checks pass
#   1 = One or more checks failed
#
# Output format:
#   STATUS: PASS|FAIL
#   LINT: pass|fail|skip
#   TYPES: pass|fail|skip
#   TESTS: pass|fail|skip
#   FORMAT: pass|fail|skip
#   COVERAGE: NN%
#   FAILURES: (if any failed)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_PATH="${1:-.}"
CONFIG="$REPO_PATH/engineering.yaml"

# Detect stack
detect_stack() {
    if [ -f "$REPO_PATH/package.json" ]; then
        if [ -f "$REPO_PATH/tsconfig.json" ]; then
            echo "node-typescript"
        else
            echo "node-javascript"
        fi
    elif [ -f "$REPO_PATH/pyproject.toml" ] || [ -f "$REPO_PATH/setup.py" ] || [ -f "$REPO_PATH/requirements.txt" ]; then
        echo "python"
    elif [ -f "$REPO_PATH/go.mod" ]; then
        echo "go"
    elif [ -f "$REPO_PATH/Cargo.toml" ]; then
        echo "rust"
    else
        echo "unknown"
    fi
}

# Read config value (simple YAML parsing)
config_value() {
    local key=$1
    local default=$2
    if [ -f "$CONFIG" ]; then
        local val=$(grep "^${key}:" "$CONFIG" 2>/dev/null | head -1 | sed "s/^${key}: *//" | tr -d '"' | tr -d "'")
        [ -n "$val" ] && echo "$val" || echo "$default"
    else
        echo "$default"
    fi
}

config_bool() {
    local key=$1
    local default=$2
    local val=$(config_value "$key" "$default")
    [ "$val" = "true" ] && echo "true" || echo "false"
}

# Get stack
STACK=$(config_value "stack" "")
[ -z "$STACK" ] && STACK=$(detect_stack)

# Get check settings
DO_LINT=$(config_bool "checks.lint" "true")
DO_TYPES=$(config_bool "checks.types" "true")
DO_TESTS=$(config_bool "checks.tests" "true")
DO_FORMAT=$(config_bool "checks.format" "true")
COVERAGE_THRESHOLD=$(config_value "coverage_threshold" "0")

# Initialize results
LINT_STATUS="skip"
TYPES_STATUS="skip"
TESTS_STATUS="skip"
FORMAT_STATUS="skip"
COVERAGE=""
FAILURES=""

# Run checks based on stack
cd "$REPO_PATH"

# Lint check
if [ "$DO_LINT" = "true" ]; then
    "$SCRIPT_DIR/check-lint.sh" "$REPO_PATH" > /dev/null 2>&1
    case $? in
        0) LINT_STATUS="pass" ;;
        1) LINT_STATUS="fail"; FAILURES="${FAILURES}lint," ;;
        2) LINT_STATUS="skip" ;;
    esac
fi

# Types check
if [ "$DO_TYPES" = "true" ]; then
    "$SCRIPT_DIR/check-types.sh" "$REPO_PATH" > /dev/null 2>&1
    case $? in
        0) TYPES_STATUS="pass" ;;
        1) TYPES_STATUS="fail"; FAILURES="${FAILURES}types," ;;
        2) TYPES_STATUS="skip" ;;
    esac
fi

# Format check
if [ "$DO_FORMAT" = "true" ]; then
    "$SCRIPT_DIR/check-format.sh" "$REPO_PATH" > /dev/null 2>&1
    case $? in
        0) FORMAT_STATUS="pass" ;;
        1) FORMAT_STATUS="fail"; FAILURES="${FAILURES}format," ;;
        2) FORMAT_STATUS="skip" ;;
    esac
fi

# Tests check
if [ "$DO_TESTS" = "true" ]; then
    TEST_OUTPUT=$("$SCRIPT_DIR/check-tests.sh" "$REPO_PATH" 2>&1)
    case $? in
        0) TESTS_STATUS="pass" ;;
        1) TESTS_STATUS="fail"; FAILURES="${FAILURES}tests," ;;
        2) TESTS_STATUS="skip" ;;
    esac
    # Extract coverage if present
    COVERAGE=$(echo "$TEST_OUTPUT" | grep "^COVERAGE:" | sed 's/COVERAGE: *//')
fi

# Determine overall status
if [ -n "$FAILURES" ]; then
    STATUS="FAIL"
    FAILURES="${FAILURES%,}"  # Remove trailing comma
else
    STATUS="PASS"
fi

# Output
echo "STATUS: $STATUS"
echo "LINT: $LINT_STATUS"
echo "TYPES: $TYPES_STATUS"
echo "TESTS: $TESTS_STATUS"
echo "FORMAT: $FORMAT_STATUS"

[ -n "$COVERAGE" ] && echo "COVERAGE: $COVERAGE"
[ -n "$FAILURES" ] && echo "FAILURES: $FAILURES"

# Exit code
[ "$STATUS" = "PASS" ] && exit 0 || exit 1
