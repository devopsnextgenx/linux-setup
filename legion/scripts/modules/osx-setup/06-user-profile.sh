#!/bin/bash
set -euo pipefail

ensure_zshrc() {
    local file="$1" owner="$2" tmp
    if [ ! -f "$file" ]; then
        : > "$file"
        [ -n "$owner" ] && chown "$owner:$(id -gn "$owner")" "$file"
    fi

    if ! grep -qF "$ZSH_TOP_MARK" "$file"; then
        tmp=$(mktemp)
        cat > "$tmp" << 'EOF'
# >>> shared-p10k-instant-prompt >>>
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
# <<< shared-p10k-instant-prompt <<<

EOF
        cat "$file" >> "$tmp"
        cat "$tmp" > "$file"
        rm -f "$tmp"
    fi

    if ! grep -qF "$ZSH_BOTTOM_MARK" "$file"; then
        cat >> "$file" << 'EOF'

# >>> shared-p10k >>>
# Shared tool environment (nvm, cargo, go, flatpak wrapper, ...)
[ -f /home/shared/common/env.shared ] && source /home/shared/common/env.shared
# Shared powerlevel10k theme + shared config
source /home/shared/powerlevel10k/powerlevel10k.zsh-theme
[[ -r /home/shared/.p10k.zsh ]] && source /home/shared/.p10k.zsh
# <<< shared-p10k <<<
EOF
    fi
}

setup_module() {
    log "Step 6: Wiring .zshrc (users + /etc/skel)..."
    for user in "${USERS[@]}"; do
        if user_exists "$user"; then
            ensure_zshrc "$(user_home "$user")/.zshrc" "$user"
            log "    - $(user_home "$user")/.zshrc configured"
        fi
    done
    mkdir -p /etc/skel
    ensure_zshrc /etc/skel/.zshrc ""

    log "Step 10: Permissions on shared files..."
    for d in "$P10K_DIR" "$SRC_DIR" "$SHARE_DIR"; do
        chown -R root:"$SHARED_GROUP" "$d"
        find "$d" -type d -exec chmod 2770 {} +
        find "$d" -type f -exec chmod g+rw {} +
    done
    chown root:"$SHARED_GROUP" "$P10K_CONFIG"
    chmod 664 "$P10K_CONFIG"

    log "Step 11: Linking shared themes/icons into profiles..."
    # New users get the links from /etc/skel
    ensure_dirs "" /etc/skel/.local /etc/skel/.local/share /etc/skel/.local/share/themes /etc/skel/.local/share/icons
    link_entries "$THEMES_DEST" /etc/skel/.local/share/themes ""
    link_entries "$ICONS_DEST"  /etc/skel/.local/share/icons  ""

    local THEME_NAME=""
    for cand in "$THEMES_DEST/WhiteSur-Dark" "$THEMES_DEST"/WhiteSur-Dark*; do
        [ -d "$cand/gtk-4.0" ] && THEME_NAME="$cand" && break
    done

    for user in "${USERS[@]}"; do
        user_exists "$user" || continue
        home="$(user_home "$user")"
        ensure_dirs "$user" "$home/.local" "$home/.local/share" "$home/.local/share/themes" "$home/.local/share/icons"
        link_entries "$THEMES_DEST" "$home/.local/share/themes" "$user"
        link_entries "$ICONS_DEST"  "$home/.local/share/icons"  "$user"

        if [ -n "$THEME_NAME" ]; then
            ensure_dirs "$user" "$home/.config" "$home/.config/gtk-4.0"
            for item in assets gtk.css gtk-dark.css; do
                t="$home/.config/gtk-4.0/$item"
                if [ -e "$t" ] && [ ! -L "$t" ]; then
                    warn "Skipping $t (real file exists)"
                    continue
                fi
                ln -sfn "$THEME_NAME/gtk-4.0/$item" "$t"
                chown -h "$user:$(id -gn "$user")" "$t"
            done
        else
            warn "No WhiteSur-Dark gtk-4.0 theme found; skipped libadwaita links for $user"
        fi

        if [ "$ENABLE_FIREFOX_TWEAK" = "1" ] && [ -d "$home/.mozilla" ]; then
            runuser -u "$user" -- bash -c "cd '$SRC_DIR/WhiteSur-gtk-theme' && ./tweaks.sh -F -f default" \
                || warn "Firefox tweak failed for $user"
        fi
        log "    - $user linked"
    done
}

uninstall_module() {
    log "Uninstalling user profiles..."
    log "    - (Note: User-side changes and .zshrc modifications are not automatically reverted.)"
}

return 0
