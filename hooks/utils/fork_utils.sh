#!/bin/bash
log() {
  local log_level=$1
  local message=$2
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "${timestamp} [${log_level}] ${message}" >&2
}

get_upstream() {
  upstream_local=""
  if [[  $(cat .github/UPSTREAM | grep -v '^#' | wc -l) != 1 ]]; then
      log "INFO" "contents of .github/UPSTREAM not in valid format - can contain only 1 non-comment line with git url"
      exit 1
  else
      upstream_local=$(cat .github/UPSTREAM | grep -vE '(^#|^$)')
  fi
  log "INFO" "upstream_local is: $upstream_local"
  echo "$upstream_local"
}

add_remote_upstream() {
  log "INFO" "Adding upstream remote."
  local upstream_repo=$1
  if ! git remote get-url upstream &>/dev/null; then
    git remote add upstream "${upstream_repo}"
  fi
  git remote -v
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
        log "INFO" "Merge successful. Precommit will exit with error though as the branch was not synced with upstream. Rerun the precommit to check if everything is ready to push. "
        git status
        exit 1
      fi
    else
      log "ERROR" "Failed to automatically sync with 'upstream/${upstream_branch}'. Please resolve conflicts manually or run pre-commit run --all locally."
      git status
      exit 1
    fi
  fi
}

sync_fork_with_upstream_branch() {
  log "INFO" "Syncing fork with upstream branch."
  local upstream_content=$(get_upstream)
  local upstream_branch="main"
  local upstream_repo=${upstream_content}
  log "INFO" "upstream_repo is: $upstream_repo"
  add_remote_upstream "${upstream_repo}"
  fetch_upstream_changes
  merge_upstream_changes "${upstream_branch}"
}
