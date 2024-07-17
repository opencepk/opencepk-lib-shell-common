#!/bin/bash

log() {
  local log_level=$1
  local message=$2
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "${timestamp} [${log_level}] ${message}" >&2
}

get_upstream() {
  local upstream_local="{}"
  if [[ -f ".github/UPSTREAM" ]]; then
    log "INFO" "Using .github/UPSTREAM file for fork status."
    upstream_local=$(<".github/UPSTREAM")
  else
    log "WARN" "No .github/UPSTREAM file found. Please check the PR in the repo."
  fi
  echo "$upstream_local"
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
  local upstream_local=$1
  local upstream_branch="feat/add-initial-sync-flow"

  ensure_jq_installed

  local upstream_repo=$(parse_upstream_repo "${upstream_local}")
  if [[ -z "$upstream_repo" ]]; then
    log "ERROR" "Failed to parse upstream repository from fork status."
    exit 1
  fi

  add_remote_upstream "${upstream_repo}"
  fetch_upstream_changes
  merge_upstream_changes "${upstream_branch}"
}