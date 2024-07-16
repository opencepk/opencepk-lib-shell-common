#!/bin/bash
GITHUB_TOKEN="${GITHUB_TOKEN}"
# Debugging: Print current directory
echo "Current directory: $(pwd)"
# Source the common functions
echo "$(dirname "$0")"
# Dynamically find the script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
echo "$SCRIPT_DIR"
# Source fork-utils.sh using the calculated directory
source "${SCRIPT_DIR}/utils/fork-utils.sh"
echo "$(ls -R)"

get_upstream() {
  local fork_status_local="{}"
  if [ -f ".github/UPSTREAM" ]; then
    log "INFO" "Using .github/UPSTREAM file for fork status."
    fork_status_local=$(cat ".github/UPSTREAM")
  else
    log "WARN" "No .github/UPSTREAM file found. Please check the PR in the repo. If you have pushed your changes and created the PR there should be a PR creating UPSTREAM file."
    echo "{}"
  fi
  echo "$fork_status_local"
}

sync_fork_with_upstream_branch() {
  local fork_status_local=$1
  local upstream_branch="feat/add-initial-sync-flow"

  # Remove unnecessary escape characters
  fork_status_local=$(echo "${fork_status_local}" | sed 's/\\\"/\"/g')
  log "DEBUG" "Parsing fork_status_local with jq: ${fork_status_local}"

  local upstream_repo=$(echo "${fork_status_local}" | jq -r '.parent')
  if ! git remote get-url upstream &>/dev/null; then
    git remote add upstream "git@github.com:${upstream_repo}.git"
  fi

  local fetch_output=$(git fetch upstream 2>&1)
  local fetch_exit_status=$?

  if [[ $fetch_exit_status -ne 0 ]]; then
    log "ERROR" "Error fetching upstream changes: $fetch_output"
    exit 1
  else
    log "INFO" "Successfully fetched upstream changes."
  fi

  if git diff --quiet HEAD upstream/${upstream_branch}; then
    log "INFO" "Branch is up-to-date with 'upstream/${upstream_branch}'."
    exit 0
  else
    local merge_output=$(git merge --no-edit upstream/${upstream_branch} 2>&1)
    local merge_exit_status=$?

    if [[ $merge_exit_status -eq 0 ]]; then
      if [[ $merge_output == *"Already up to date."* ]]; then
        log "INFO" "No changes were necessary; your branch was already up to date."
        exit 0
      else
        log "INFO" "Merge successful. Precommit will exit with error though as the branch was not synced with upstream. Rerun the precommit to check if everything is ready to push."
        exit 1
      fi
    else
      log "ERROR" "Failed to automatically sync with 'upstream/${upstream_branch}'. Please resolve conflicts manually or run pre-commit run --all locally."
      exit 1
    fi
  fi
}

log() {
  local log_level=$1
  local message=$2
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "${timestamp} [${log_level}] ${message}" >&2
}

if [[ ! -f ".github/UPSTREAM" ]]; then
  log "INFO" "No .github/UPSTREAM file found. Exiting."
  exit 0
else
  upstream=$(get_upstream)
  log "DEBUG" "fork_status is $upstream"
  if [ "$upstream" = "{}" ]; then
    exit 0
  fi

  if [ "$upstream" = "{}" ]; then
    log "INFO" "This repository is not a fork"
    exit 0
  fi
  sync_fork_with_upstream_branch "${upstream}"
fi
