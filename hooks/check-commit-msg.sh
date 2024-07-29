#!/bin/bash
# set -e
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# Source fork-utils.sh using the calculated directory
source "${SCRIPT_DIR}/utils/fork_utils.sh"
# Exit the script if running in a CI environment
if [ "$CI" == "true" ]; then
   exit 0
fi

# Path to the commit-msg hook
HOOK_PATH=".git/hooks/commit-msg"
rm -rf $HOOK_PATH || true
# Desired content of the commit-msg hook
read -r -d '' HOOK_CONTENT <<'EOF'
#!/bin/bash

# Function to check branch name
check_branch_name() {
    # Get the current branch name
    BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)

    # Regular expression for the required branch name format
    BRANCH_PATTERN="^(feat|fix|build|breaking|chore|ci|docs|perf|refactor|revert|test)\/[a-zA-Z0-9-]+$"

    # Debug: Print the branch name and pattern
    echo "DEBUG: Branch name: '$BRANCH_NAME'"
    echo "DEBUG: Branch pattern: '$BRANCH_PATTERN'"

    # Check if the branch name matches the pattern
    if [[ ! "$BRANCH_NAME" =~ $BRANCH_PATTERN ]]; then
        echo "ERROR: Branch name does not follow the required format 'git branch -m type/jira-number'"
        exit 1
    else
        echo "DEBUG: Branch name matches the pattern"
    fi
}

# Check the branch name before allowing the commit
check_branch_name

# Path to the file containing the commit message
COMMIT_MSG_FILE=$1

# Regular expression for the required commit message format
PATTERN="^(feat|fix|build|breaking|chore|ci|docs|perf|refactor|revert|test)\/[a-zA-Z0-9-]+)?(:)? *.+$"

# Read the commit message
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Debug: Print the commit message and pattern
echo "DEBUG: Commit message: '$COMMIT_MSG'"
echo "DEBUG: Pattern: '$PATTERN'"

# Check if the commit message matches the pattern
if [[ ! "$COMMIT_MSG" =~ $PATTERN ]]; then
    echo "ERROR: Commit message does not follow the required format 'type/jira-ticket: description'"
    echo "DEBUG: Commit message does not match the pattern"
    exit 1
fi


# If the script reaches this point, the commit message is valid
exit 0
EOF

# Check if the hook exists and matches the desired content
# if [ -f "$HOOK_PATH" ]; then
#    CURRENT_CONTENT=$(cat "$HOOK_PATH")
#    if [ "$CURRENT_CONTENT" == "$HOOK_CONTENT" ]; then
#       # The hook exists and matches the desired content; no action needed
#       log "DEBUG" "The commit-msg hook already exists and matches the desired content."
#       exit 0
#    fi
# fi

# Write the desired content to the commit-msg hook, creating or updating it
echo "$HOOK_CONTENT" >"$HOOK_PATH"

# Make the hook executable
chmod +x "$HOOK_PATH"
