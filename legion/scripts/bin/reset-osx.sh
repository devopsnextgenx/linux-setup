#!/bin/bash
# reset-osx.sh
#
# Reverts ONLY the desktop theme changes made by setup-powerlevel10k-osx.sh:
#   - removes the theme/icon symlinks from each user's ~/.local/share and /etc/skel
#   - removes the libadwaita links in ~/.config/gtk-4.0 (only ones pointing at /home/shared)
#   - resets gsettings (GTK theme, icon theme, shell theme, wallpaper) if they use WhiteSur/MacTahoe
#   - reverts the GDM login-screen tweak
#   - removes the system-wide WhiteSur wallpapers
#
# NOT touched: zsh, login shells, powerlevel10k, /home/shared/.p10k.zsh, .zshrc blocks, sharedusers group.
#
# Usage:   sudo ./reset-osx.sh [extra_user ...]
# Options (env vars):
#   PURGE=1                 also delete the installed theme/icon files and sources
#                           in /home/shared/share and /home/shared/src (p10k is kept)
#   ENABLE_FIREFOX_TWEAK=1  also try to revert the WhiteSur Firefox tweak per user
set -uo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "[-] Error: This script must be run as root (sudo)." >&2
    exit 1
fi

SHARED_DIR="/home/shared"
SHARE_DIR="$SHARED_DIR/share"
SRC_DIR="$SHARED_DIR/src"
GTK_REPO="$SRC_DIR/WhiteSur-gtk-theme"
USERS=(kira admn "$@")

PURGE="${PURGE:-0}"
ENABLE_FIREFOX_TWEAK="${ENABLE_FIREFOX_TWEAK:-0}"

log()  { echo "[+] $*"; }
warn() { echo "    ! $*" >&2; }
user_exists() { id "$1" &>/dev/null; }
user_home()   { getent passwd "$1" | cut -d: -f6; }

# Remove every symlink in $1 whose target lives under $SHARED_DIR (never touches real files)
remove_shared_links() {
    local dir="$1" entry target
    [ -d "$dir" ] || return 0
    for entry in "$dir"/*; do
        [ -L "$entry" ] || continue
        target="$(readlink "$entry")"
        case "$target" in
            "$SHARED_DIR"/*) rm -f "$entry" ;;
        esac
    done
}

# Remove a single symlink only if it points under $SHARED_DIR
remove_shared_link() {
    local link="$1" target
    [ -L "$link" ] || return 0
    target="$(readlink "$link")"
    case "$target" in
        "$SHARED_DIR"/*) rm -f "$link" ;;
    esac
}

# Run gsettings as a user inside their running session (best effort)
as_user_gs() {
    local user="$1"; shift
    local uid
    uid="$(id -u "$user")"
    [ -S "/run/user/$uid/bus" ] || return 1
    runuser -u "$user" -- env \
        XDG_RUNTIME_DIR="/run/user/$uid" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
        gsettings "$@" 2>/dev/null
}

# Reset schema/key only if its current value mentions WhiteSur or MacTahoe
reset_if_themed() {
    local user="$1" schema="$2" key="$3" val
    val="$(as_user_gs "$user" get "$schema" "$key")" || return 1
    if echo "$val" | grep -qiE 'whitesur|mactahoe'; then
        as_user_gs "$user" reset "$schema" "$key" && echo "      reset $schema $key"
    fi
}

# ===========================================================================
log "Step 1: Removing theme/icon symlinks from user profiles..."
for user in "${USERS[@]}"; do
    user_exists "$user" || { warn "User '$user' does not exist. Skipping."; continue; }
    home="$(user_home "$user")"

    remove_shared_links "$home/.local/share/themes"
    remove_shared_links "$home/.local/share/icons"

    # libadwaita / GTK4 links
    for item in assets gtk.css gtk-dark.css; do
        remove_shared_link "$home/.config/gtk-4.0/$item"
    done

    # Clean up directories the setup script created, only if now empty
    rmdir "$home/.config/gtk-4.0" 2>/dev/null || true
    rmdir "$home/.local/share/themes" "$home/.local/share/icons" 2>/dev/null || true

    echo "    - $user: links removed"
done

log "Step 2: Removing theme/icon symlinks from /etc/skel (new users)..."
remove_shared_links /etc/skel/.local/share/themes
remove_shared_links /etc/skel/.local/share/icons
rmdir /etc/skel/.local/share/themes /etc/skel/.local/share/icons \
      /etc/skel/.local/share /etc/skel/.local 2>/dev/null || true

log "Step 3: Resetting GNOME settings (needs the user to be logged in)..."
for user in "${USERS[@]}"; do
    user_exists "$user" || continue
    if as_user_gs "$user" get org.gnome.desktop.interface gtk-theme >/dev/null; then
        echo "    - $user:"
        reset_if_themed "$user" org.gnome.desktop.interface gtk-theme
        reset_if_themed "$user" org.gnome.desktop.interface icon-theme
        reset_if_themed "$user" org.gnome.desktop.interface cursor-theme
        reset_if_themed "$user" org.gnome.shell.extensions.user-theme name
        reset_if_themed "$user" org.gnome.desktop.background picture-uri
        reset_if_themed "$user" org.gnome.desktop.background picture-uri-dark
        reset_if_themed "$user" org.gnome.desktop.screensaver picture-uri
    else
        warn "$user has no active session; run this as $user after login instead:"
        echo "        gsettings reset org.gnome.desktop.interface gtk-theme"
        echo "        gsettings reset org.gnome.desktop.interface icon-theme"
        echo "        gsettings reset org.gnome.shell.extensions.user-theme name"
        echo "        gsettings reset org.gnome.desktop.background picture-uri"
        echo "        gsettings reset org.gnome.desktop.background picture-uri-dark"
    fi
done

log "Step 4: Reverting GDM login-screen tweak..."
if [ -d "$GTK_REPO" ] && [ -f "$GTK_REPO/tweaks.sh" ]; then
    ( cd "$GTK_REPO" && chmod 755 ./*.sh && ./tweaks.sh -g -r ) \
        || warn "tweaks.sh -g -r failed; trying update-alternatives fallback"
fi
# Fallback / extra safety: return the GDM gresource alternative to the distro default
if update-alternatives --list gdm-theme.gresource &>/dev/null; then
    update-alternatives --auto gdm-theme.gresource \
        && echo "    - gdm-theme.gresource alternative set back to automatic"
fi

if [ "$ENABLE_FIREFOX_TWEAK" = "1" ] && [ -d "$GTK_REPO" ]; then
    log "Step 4b: Reverting Firefox tweak..."
    for user in "${USERS[@]}"; do
        user_exists "$user" || continue
        home="$(user_home "$user")"
        [ -d "$home/.mozilla" ] || continue
        runuser -u "$user" -- bash -c "cd '$GTK_REPO' && ./tweaks.sh -F -r" \
            || warn "Firefox revert failed for $user"
    done
fi

log "Step 5: Removing system-wide WhiteSur wallpapers..."
for base in /usr/share/backgrounds /usr/share/gnome-background-properties /usr/share/wallpapers; do
    [ -d "$base" ] || continue
    find "$base" -maxdepth 1 -iname 'WhiteSur*' -print -exec rm -rf {} + 2>/dev/null | sed 's/^/    - removed /'
done

if [ "$PURGE" = "1" ]; then
    log "Step 6: PURGE=1 -> deleting installed theme/icon files and sources..."
    rm -rf "$SHARE_DIR"
    rm -rf "$SRC_DIR/WhiteSur-gtk-theme" \
           "$SRC_DIR/WhiteSur-wallpapers" \
           "$SRC_DIR/MacTahoe-icon-theme" \
           "$SRC_DIR/.stamps"
    rmdir "$SRC_DIR" 2>/dev/null || true
    echo "    - removed $SHARE_DIR and theme sources (powerlevel10k kept)"
else
    log "Step 6: Keeping files in $SHARE_DIR (run with PURGE=1 to delete them)."
    # Drop stamps so a future setup run reinstalls and relinks cleanly
    rm -rf "$SRC_DIR/.stamps"
fi

echo "[✔] Done."
echo "    Log out and back in (or reboot) so GNOME reloads theme, icons and the login screen."
echo "    zsh + powerlevel10k were not modified."
