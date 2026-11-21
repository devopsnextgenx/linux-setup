#!/bin/bash
set -euo pipefail

setup_module() {
    log "Step 8: WhiteSur wallpapers (system-wide, single copy)..."
    WP_REPO="$SRC_DIR/WhiteSur-wallpapers"
    sync_repo "$REPO_WALLPAPERS" "$WP_REPO"
    want="$(git -C "$WP_REPO" rev-parse HEAD)"

    if needs_install wallpapers "$want"; then
        ( cd "$WP_REPO" && chmod 755 ./*.sh && ./install-gnome-backgrounds.sh && ./install-wallpapers.sh )
        write_stamp wallpapers "$want"
        log "    - Installed wallpapers"
    else
        log "    - Wallpapers up to date"
    fi
}

uninstall_module() {
    log "Uninstalling wallpapers..."
    rm -rf "$SRC_DIR/WhiteSur-wallpapers"
}

return 0
