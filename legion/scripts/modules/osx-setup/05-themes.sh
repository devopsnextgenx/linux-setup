#!/bin/bash
set -euo pipefail

setup_module() {
    log "Step 9: WhiteSur GTK theme -> $THEMES_DEST"
    GTK_REPO="$SRC_DIR/WhiteSur-gtk-theme"
    sync_repo "$REPO_GTK" "$GTK_REPO"
    
    GTK_OPTS=(-o normal -c Dark -a normal -m -t all -N stable -HD --shell -i apple -b default -p --black --dialog -d "$THEMES_DEST")
    want="$(git -C "$GTK_REPO" rev-parse HEAD)|${GTK_OPTS[*]}|gdm=$ENABLE_GDM_TWEAK"

    if needs_install gtk "$want"; then
        ( cd "$GTK_REPO" && chmod 755 ./*.sh && ./install.sh "${GTK_OPTS[@]}" )
        if [ "$ENABLE_GDM_TWEAK" = "1" ]; then
            ( cd "$GTK_REPO" && ./tweaks.sh -g ) || warn "GDM tweak failed; continuing"
        fi
        write_stamp gtk "$want"
        log "    - Installed GTK themes"
    else
        log "    - GTK themes up to date"
    fi
}

uninstall_module() {
    log "Uninstalling themes..."
    rm -rf "$THEMES_DEST"
    rm -rf "$SRC_DIR/WhiteSur-gtk-theme"
}

return 0
