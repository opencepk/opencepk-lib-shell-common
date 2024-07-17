#!/bin/bash

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
  local upstream_repo=$1
  if ! git remote get-url upstream &>/dev/null; then
    git remote add upstream "git@github.com:${upstream_repo}.git"
  fi
}

fetch_upstream_changes() {
  if ! git fetch upstream 2>&1; then
    log "ERROR" "Error fetching upstream changes."
    exit 1
  else
    log "INFO" "Successfully fetched upstream changes."
  fi
}

merge_upstream_changes() {
  local upstream_branch=$1
  if git diff --quiet HEAD upstream/${upstream_branch}; then
    log "INFO" "Branch is up-to-date with 'upstream/${upstream_branch}'."
    exit 0
  else
    if git merge --no-edit upstream/${upstream_branch} 2>&1; then
      log "INFO" "Merge successful. Branch is synced with upstream."
      exit 0
    else
      log "ERROR" "Failed to automatically sync with 'upstream/${upstream_branch}'."
      exit 1
    fi
  fi
}

sync_fork_with_upstream_branch() {
  local fork_status_local=$1
  local upstream_branch="feat/add-initial-sync-flow"
  ensure_jq_installed
  # Remove unnecessary escape characters
  # fork_status_local=$(echo "${fork_status_local}" | sed 's/\\\"/\"/g')
  # log "DEBUG" "Parsing fork_status_local with jq: ${fork_status_local}"

  # local upstream_repo=$(echo "${fork_status_local}" | jq -r '.parent')
  local upstream_repo=$(parse_upstream_repo "${upstream_local}")
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
