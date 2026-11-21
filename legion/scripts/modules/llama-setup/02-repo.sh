#!/bin/bash

# Dependencies: scripts/modules/utils.sh, scripts/modules/llama-setup/config.sh

sync_repo() {
  git config --global --get-all safe.directory 2>/dev/null | grep -Fxq "$REPO_DIR" \
    || git config --global --add safe.directory "$REPO_DIR"

  if [ ! -d "$REPO_DIR/.git" ]; then
    log "cloning llama.cpp -> $REPO_DIR"
    git clone "$REPO_URL" "$REPO_DIR"
  elif ((PULL)); then
    local before after
    before=$(git -C "$REPO_DIR" rev-parse --short HEAD)
    log "updating llama.cpp (was $before)"
    git -C "$REPO_DIR" pull --ff-only
    after=$(git -C "$REPO_DIR" rev-parse --short HEAD)
    log "now at $after"
  else
    log "repo present at $(git -C "$REPO_DIR" rev-parse --short HEAD) (use --recompile to update)"
  fi
}

setup_repo() {
  sync_repo
}

uninstall_repo() {
  log "Removing llama.cpp repository: $REPO_DIR"
  rm -rf "$REPO_DIR"
}
