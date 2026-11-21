#!/bin/bash
set -euo pipefail

setup_module() {
    local URL="https://github.com/Umio-Yasuno/amdgpu_top/releases/download/v0.11.5/amdgpu-top_0.11.5-1_amd64.deb"
    local FILENAME="amdgpu-top_0.11.5-1_amd64.deb"
    local DEST="/tmp/$FILENAME"

    log "Downloading amdgpu-top..."
    curl -L "$URL" -o "$DEST"

    log "Installing amdgpu-top..."
    apt-get install -y "$DEST"

    log "Cleaning up..."
    rm "$DEST"
}

uninstall_module() {
    log "Uninstalling amdgpu-top..."
    apt-get remove -y amdgpu-top || true
}

return 0
