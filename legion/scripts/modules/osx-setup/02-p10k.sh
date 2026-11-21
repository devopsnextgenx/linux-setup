#!/bin/bash
set -euo pipefail

setup_module() {
    log "Step 4: Powerlevel10k theme -> $P10K_DIR"
    sync_repo "$REPO_P10K" "$P10K_DIR"

    if [ -z "${P10K_SRC:-}" ] || [ ! -f "$P10K_SRC" ]; then
        if [ -f "$P10K_CONFIG" ]; then
            log "    - Using existing $P10K_CONFIG"
        else
            error "p10k config not found. Set P10K_SRC=..."
            return 1
        fi
    else
        if [ -f "$P10K_CONFIG" ] && cmp -s "$P10K_SRC" "$P10K_CONFIG"; then
            log "    - $P10K_CONFIG is up to date"
        else
            [ -f "$P10K_CONFIG" ] && cp -p "$P10K_CONFIG" "$P10K_CONFIG.bak" && log "    - Previous config saved as $P10K_CONFIG.bak"
            install -m 664 -o root -g "$SHARED_GROUP" "$P10K_SRC" "$P10K_CONFIG"
            log "    - Installed $P10K_CONFIG"
        fi
    fi
}

uninstall_module() {
    log "Uninstalling Powerlevel10k..."
    rm -rf "$P10K_DIR"
    rm -f "$P10K_CONFIG"
}

return 0
