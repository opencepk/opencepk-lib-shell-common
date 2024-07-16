#!/bin/bash
GITHUB_TOKEN="${GITHUB_TOKEN}"

# Source the common functions
source scripts/utils/fork_utils.sh

# Ensures the local fork is synced with the specified upstream branch.
# Arguments:
#   fork_status_local: The local fork status, expected to contain the parent repo information.
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

if [[ ! -f ".github/UPSTREAM" ]]; then
# if [[ $CI != "true" && ! -f ".github/UPSTREAM" ]]; then
  log "INFO" "No .github/UPSTREAM file found. Exiting."
  exit 0
else
  fork_status=$(decide_sync_strategy_based_on_fork_status)
  log "DEBUG" "fork_status is $fork_status"
  if [ "$fork_status" = "{}" ]; then
    exit 0
  fi

  if [ "$fork_status" = "{}" ]; then
    log "INFO" "This repository is not a fork"
    exit 0
  fi
  sync_fork_with_upstream_branch "${fork_status}"
fi
