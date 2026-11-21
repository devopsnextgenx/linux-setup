#!/bin/bash
# modules/shared-setup/02-directories.sh

setup_directories() {
    info "Step 4: Setting up $SHARED_DIR directory structure and permissions..."
    
    mkdir -p "$COMMON_DIR"
    chown root:"$SHARED_GROUP" "$SHARED_DIR"
    chmod 2771 "$SHARED_DIR"

    mkdir -p "$COMMON_DIR"/{nvm,python_env,rustup,cargo,go,gopath,ollama}
    mkdir -p "$PODMAN_USERS_DIR" "$PODMAN_ARCHIVES_DIR"
    
    info "    - Created common directories and podman subdirs."
}

uninstall_directories() {
    warn "Removing shared directories..."
    rm -rf "$SHARED_DIR"
}
