#!/bin/bash
set -e
GITHUB_TOKEN="${GITHUB_TOKEN}"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# Source fork-utils.sh using the calculated directory
source "${SCRIPT_DIR}/utils/fork_utils.sh"

if [[ ! -f ".github/UPSTREAM" ]]; then
  log "INFO" "No .github/UPSTREAM file found. Exiting."
  exit 0
fi

upstream=$(get_upstream)
log "DEBUG" "fork_status is ${upstream}"

if [[ "${upstream}" = "{}" ]]; then
  log "INFO" "This repository is not a fork or the upstream information is empty."
  exit 0
fi

sync_fork_with_upstream_branch
