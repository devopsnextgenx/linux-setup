#!/bin/bash
set -euo pipefail

setup_module() {
    log "Step 7: MacTahoe icon theme -> $ICONS_DEST"
    sync_repo "$REPO_ICONS" "$SRC_DIR/MacTahoe-icon-theme"
    
    ICON_REPO="$SRC_DIR/MacTahoe-icon-theme"
    want="$(git -C "$ICON_REPO" rev-parse HEAD)|-b -d $ICONS_DEST -a normal"
    
    if needs_install icons "$want"; then
        ( cd "$ICON_REPO" && chmod 755 ./*.sh && ./install.sh -b -d "$ICONS_DEST" -a normal )
        write_stamp icons "$want"
        log "    - Installed icons"
    else
        log "    - Icons up to date"
    fi
}

uninstall_module() {
    log "Uninstalling icons..."
    rm -rf "$ICONS_DEST"
    rm -rf "$SRC_DIR/MacTahoe-icon-theme"
}

return 0
