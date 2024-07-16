#!/bin/bash
GITHUB_TOKEN="${GITHUB_TOKEN}"

# Source the common functions
source ./utils/fork_utils.sh

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
