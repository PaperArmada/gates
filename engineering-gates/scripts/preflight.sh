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

# Config resolution: gates.yaml (unified) > engineering.yaml (legacy)
if [ -f "$REPO_PATH/gates.yaml" ]; then
    CONFIG="$REPO_PATH/gates.yaml"
    CONFIG_PREFIX="engineering."
else
    CONFIG="$REPO_PATH/engineering.yaml"
    CONFIG_PREFIX=""
fi

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

# Read nested YAML value (handles dot-separated paths like "engineering.checks.lint")
# Usage: yaml_get "path.to.key" "default" [file]
yaml_get() {
    local path=$1
    local default=$2
    local file=${3:-$CONFIG}

    [ ! -f "$file" ] && echo "$default" && return

    # Convert dot path to components
    IFS='.' read -ra parts <<< "$path"
    local depth=${#parts[@]}

    # Build awk pattern for nested extraction
    local result=$(awk -v parts="${parts[*]}" -v depth="$depth" '
    BEGIN {
        split(parts, p, " ")
        current_depth = 0
        found_path = ""
    }
    {
        # Calculate indentation (2 spaces per level)
        match($0, /^[ ]*/)
        indent = RLENGTH / 2

        # Extract key and value
        if (match($0, /^[ ]*([a-zA-Z0-9_-]+):[ ]*(.*)$/, m)) {
            key = m[1]
            val = m[2]

            # Track current path based on indent
            if (indent == 0) {
                found_path = key
                current_depth = 1
            } else if (indent == current_depth) {
                found_path = found_path "." key
                current_depth = indent + 1
            } else if (indent > current_depth) {
                found_path = found_path "." key
                current_depth = indent + 1
            } else {
                # Dedent - rebuild path
                split(found_path, fp, ".")
                found_path = ""
                for (i = 1; i <= indent; i++) {
                    found_path = (found_path == "" ? fp[i] : found_path "." fp[i])
                }
                found_path = found_path "." key
                current_depth = indent + 1
            }

            # Check if this matches our target path
            target = p[1]
            for (i = 2; i <= depth; i++) target = target "." p[i]

            if (found_path == target && val != "") {
                gsub(/^[ ]*|[ ]*$/, "", val)
                gsub(/^["'"'"']|["'"'"']$/, "", val)
                gsub(/#.*$/, "", val)
                gsub(/[ ]*$/, "", val)
                print val
                exit
            }
        }
    }
    ' "$file")

    [ -n "$result" ] && echo "$result" || echo "$default"
}

# Helper for boolean values
yaml_bool() {
    local val=$(yaml_get "$1" "$2" "$3")
    [ "$val" = "true" ] && echo "true" || echo "false"
}

# Version check for gates.yaml
check_config_version() {
    if [ "$CONFIG" = "$REPO_PATH/gates.yaml" ]; then
        local version=$(yaml_get "version" "" "$CONFIG")
        if [ -z "$version" ]; then
            echo "WARNING: gates.yaml missing version field" >&2
        elif [ "$version" != "1" ]; then
            echo "WARNING: gates.yaml version $version may not be fully supported" >&2
        fi
    fi
}

# Backward-compatible wrappers
config_value() {
    yaml_get "${CONFIG_PREFIX}$1" "$2"
}

config_bool() {
    yaml_bool "${CONFIG_PREFIX}$1" "$2"
}

# Validate config version
check_config_version

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
