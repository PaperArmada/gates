#!/bin/bash
# Charter gates preflight check
# Run this BEFORE any work session. Returns machine-readable status.
#
# Usage: ./preflight.sh [path-to-product-repo]
#
# Exit codes (per contracts.yaml):
#   0 = Clear to proceed
#   1 = Blocked (hard stop)
#   2 = Warning (proceed with caution)
#
# Output format:
#   STATUS: CLEAR|BLOCKED|WARNING
#   OUTCOME: proceed|freeze|kill|unknown
#   REVIEW_STATUS: current|overdue|unknown
#   ASSUMPTIONS: A1=status,A2=status,A3=status
#   BLOCK_REASON: (if blocked)
#   WARNING: (if warning)

REPO_PATH="${1:-.}"
CHARTER="$REPO_PATH/charter/charter.yaml"
RUBRIC="$REPO_PATH/charter/kill-rubric.yaml"
GATES_CONFIG="$REPO_PATH/gates.yaml"
LOCAL_CONFIG="$REPO_PATH/.gates.local"

# Read config value from a file's charter section
read_charter_config() {
    local file=$1
    local key=$2
    [ ! -f "$file" ] && return 1

    # Simple extraction for charter.* keys
    local section_found=0
    local result=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^charter: ]]; then
            section_found=1
        elif [[ $section_found -eq 1 && "$line" =~ ^[a-z] ]]; then
            section_found=0
        elif [[ $section_found -eq 1 && "$line" =~ ^[[:space:]]+${key}: ]]; then
            result=$(echo "$line" | sed "s/.*${key}: *//" | tr -d '"' | tr -d "'" | sed 's/#.*//' | sed 's/ *$//')
            break
        fi
    done < "$file"

    [ -n "$result" ] && echo "$result" && return 0
    return 1
}

# Read config with local override support
# Priority: .gates.local > gates.yaml
gates_config() {
    local key=$1
    local default=$2

    # Check local override first
    if [ -f "$LOCAL_CONFIG" ]; then
        local local_val=$(read_charter_config "$LOCAL_CONFIG" "$key")
        if [ -n "$local_val" ]; then
            echo "$local_val"
            return
        fi
    fi

    # Fall back to main config
    local main_val=$(read_charter_config "$GATES_CONFIG" "$key")
    if [ -n "$main_val" ]; then
        echo "$main_val"
        return
    fi

    echo "$default"
}

# Configuration
ENFORCE_REVIEWS=$(gates_config "enforce_reviews" "true")

# Extract simple YAML value (handles quotes, strips comments)
yaml_value() {
    local file=$1
    local key=$2
    local indent=${3:-0}

    local prefix=""
    for ((i=0; i<indent; i++)); do prefix+="  "; done

    grep "^${prefix}${key}:" "$file" 2>/dev/null | head -1 | \
        sed "s/^${prefix}${key}: *//" | \
        sed 's/#.*//' | \
        tr -d '"' | tr -d "'" | \
        sed 's/^ *//' | sed 's/ *$//'
}

# Extract nested assumption field
assumption_field() {
    local file=$1
    local assumption=$2
    local field=$3

    awk -v a="  $assumption:" -v f="    $field:" '
        $0 ~ a { found=1; next }
        found && /^  [A-Z]/ { found=0 }
        found && $0 ~ f {
            sub(/.*: */, "");
            gsub(/^["'"'"']|["'"'"']$/, "");
            gsub(/^ *| *$/, "");
            print;
            exit
        }
    ' "$file" 2>/dev/null
}

# Initialize
STATUS="CLEAR"
BLOCK_REASON=""
WARNING_MSG=""
OUTCOME="unknown"
REVIEW_STATUS="unknown"

# 1. Check charter exists
if [ ! -f "$CHARTER" ]; then
    STATUS="BLOCKED"
    BLOCK_REASON="No charter.yaml found at $CHARTER"
else
    # Check required fields
    CODENAME=$(yaml_value "$CHARTER" "codename" 1)
    JTBD=$(yaml_value "$CHARTER" "jtbd")
    HYPOTHESIS=$(yaml_value "$CHARTER" "hypothesis")

    MISSING=""
    [ -z "$CODENAME" ] && MISSING="${MISSING}codename, "
    [ -z "$JTBD" ] && MISSING="${MISSING}jtbd, "
    [ -z "$HYPOTHESIS" ] && MISSING="${MISSING}hypothesis, "

    # Check A1 statement (required)
    A1_STMT=$(assumption_field "$CHARTER" "A1" "statement")
    [ -z "$A1_STMT" ] && MISSING="${MISSING}assumptions.A1.statement, "

    if [ -n "$MISSING" ]; then
        STATUS="BLOCKED"
        BLOCK_REASON="Charter incomplete: missing ${MISSING%, }"
    fi

    # Get assumption statuses
    A1_STATUS=$(assumption_field "$CHARTER" "A1" "status")
    A2_STATUS=$(assumption_field "$CHARTER" "A2" "status")
    A3_STATUS=$(assumption_field "$CHARTER" "A3" "status")

    [ -z "$A1_STATUS" ] && A1_STATUS="empty"
    [ -z "$A2_STATUS" ] && A2_STATUS="empty"
    [ -z "$A3_STATUS" ] && A3_STATUS="empty"
fi

# 2. Check kill rubric
if [ -f "$RUBRIC" ]; then
    OUTCOME=$(yaml_value "$RUBRIC" "outcome")
    [ -z "$OUTCOME" ] && OUTCOME="unknown"

    NEXT_REVIEW=$(yaml_value "$RUBRIC" "next_review")

    # Check outcome status
    if [ "$OUTCOME" = "kill" ]; then
        STATUS="BLOCKED"
        BLOCK_REASON="Product is KILLED. No work allowed."
    elif [ "$OUTCOME" = "freeze" ]; then
        if [ "$STATUS" = "CLEAR" ]; then
            STATUS="WARNING"
            WARNING_MSG="Product is FROZEN. Only bug fixes allowed."
        fi
    fi

    # Check review date (if enforcement enabled)
    if [[ "$NEXT_REVIEW" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        TODAY=$(date +%Y-%m-%d)
        if [[ "$TODAY" > "$NEXT_REVIEW" ]]; then
            REVIEW_STATUS="overdue"
            if [ "$ENFORCE_REVIEWS" = "true" ]; then
                STATUS="BLOCKED"
                BLOCK_REASON="Past review date ($NEXT_REVIEW). Complete review first."
            else
                if [ "$STATUS" = "CLEAR" ]; then
                    STATUS="WARNING"
                    WARNING_MSG="Review overdue ($NEXT_REVIEW). Consider scheduling review."
                fi
            fi
        else
            REVIEW_STATUS="current"
        fi
    fi
fi

# 3. Output machine-readable status
echo "STATUS: $STATUS"
echo "OUTCOME: $OUTCOME"
echo "REVIEW_STATUS: $REVIEW_STATUS"
echo "ASSUMPTIONS: A1=${A1_STATUS:-unknown},A2=${A2_STATUS:-unknown},A3=${A3_STATUS:-unknown}"

if [ -n "$BLOCK_REASON" ]; then
    echo "BLOCK_REASON: $BLOCK_REASON"
fi

if [ -n "$WARNING_MSG" ]; then
    echo "WARNING: $WARNING_MSG"
fi

# 4. Exit with appropriate code
case $STATUS in
    CLEAR)   exit 0 ;;
    WARNING) exit 2 ;;
    BLOCKED) exit 1 ;;
esac
