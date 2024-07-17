#!/bin/bash
log() {
  local log_level=$1
  local message=$2
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "${timestamp} [${log_level}] ${message}" >&2
}

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

ensure_jq_installed() {
  if ! command -v jq &>/dev/null; then
    log "ERROR" "jq is not installed. Please install jq to parse JSON data."
    exit 1
  fi
}

parse_upstream_repo() {
  local upstream_local=$1
  upstream_local=$(echo "${upstream_local}" | sed 's/\\\"/\"/g')
  log "DEBUG" "Parsing upstream_local with jq: ${upstream_local}"
  echo "${upstream_local}" | jq -r '.parent'
}

add_remote_upstream() {
  log "INFO" "Adding upstream remote."
  local upstream_repo=$1
  if ! git remote get-url upstream &>/dev/null; then
    git remote add upstream "git@github.com:${upstream_repo}.git"
  fi
}

fetch_upstream_changes() {
  log "INFO" "Fetching upstream changes."
  local fetch_output=$(git fetch upstream 2>&1)
  local fetch_exit_status=$?

  if [[ $fetch_exit_status -ne 0 ]]; then
    log "ERROR" "Error fetching upstream changes: $fetch_output"
    exit 1
  else
    log "INFO" "Successfully fetched upstream changes."
  fi
}

merge_upstream_changes() {
  local upstream_branch=$1
  log "INFO" "Merging upstream changes."
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

sync_fork_with_upstream_branch() {
  log "INFO" "Syncing fork with upstream branch."
  local upstream_content=$(get_upstream)
  # local upstream_branch="feat/add-initial-sync-flow"
  local upstream_branch="main"
  ensure_jq_installed
  local upstream_repo=$(parse_upstream_repo "${upstream_content}")
  log "INFO" "upstream_repo is: $upstream_repo"
  add_remote_upstream "${upstream_repo}"
  fetch_upstream_changes
  merge_upstream_changes "${upstream_branch}"
}
