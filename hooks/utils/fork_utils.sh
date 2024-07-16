#!/bin/bash

decide_sync_strategy_based_on_fork_status() {
  local fork_status_local="{}"
  # if [[ $CI == "true" ]]; then
  #   # Running in CI environment
  #   log "INFO" "$REPO_NAME is the repo name"
  #   fork_status_local=$(fetch_fork_parent_repo_info "$REPO_NAME")
  # else
  #   # Running in local environment
  #   if [ -f ".github/UPSTREAM" ]; then
  #     log "INFO" "Using .github/UPSTREAM file for fork status."
  #     fork_status_local=$(cat ".github/UPSTREAM")
  #   else
  #     log "WARN" "No .github/UPSTREAM file found. Exiting."
  #     echo "{}"
  #   fi
  # fi
  if [ -f ".github/UPSTREAM" ]; then
    log "INFO" "Using .github/UPSTREAM file for fork status."
    fork_status_local=$(cat ".github/UPSTREAM")
  else
    log "WARN" "No .github/UPSTREAM file found. Please check the PR in the repo. If you have pushed your changes and created the PR there should be a PR creating UPSTREAM file."
    echo "{}"
  fi
  # return $fork_status_local
  echo "$fork_status_local"
}

log() {
  local log_level=$1
  local message=$2
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "${timestamp} [${log_level}] ${message}" >&2
}
