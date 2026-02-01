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
            gsub(/["\047#].*/, "");
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

    # Check review date
    if [[ "$NEXT_REVIEW" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        TODAY=$(date +%Y-%m-%d)
        if [[ "$TODAY" > "$NEXT_REVIEW" ]]; then
            STATUS="BLOCKED"
            BLOCK_REASON="Past review date ($NEXT_REVIEW). Complete review first."
            REVIEW_STATUS="overdue"
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
