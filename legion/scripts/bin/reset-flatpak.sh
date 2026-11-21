#!/bin/bash
# reset-flatpak.sh
#
# Reverts the custom "shared" Flatpak installation created by setup-shared.sh:
#   - re-installs the apps from it into the standard system-wide Flatpak (/var/lib/flatpak)
#   - removes /etc/flatpak/installations.d/shared.conf  (this is what put
#     /home/shared/common/flatpak/exports/share into XDG_DATA_DIRS for EVERY user,
#     including the gdm-greeter user that cannot read /home/shared -> broken login screen)
#   - removes the flatpak() wrapper function from /home/shared/common/env.shared
#   - deletes /home/shared/common/flatpak (only if every app migrated successfully)
#   - re-tightens permissions on /home/shared and /home/shared/common
#
# NOT touched: nvm, python_env, rust, go, ollama, podman, p10k, themes, ~/.var/app user data.
#
# Usage:   sudo ./reset-flatpak.sh
# Options (env vars):
#   MIGRATE=0   skip re-installing apps into the system installation
#   KEEP_DIR=1  keep /home/shared/common/flatpak even after a successful migration
set -uo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "[-] Error: This script must be run as root (sudo)." >&2
    exit 1
fi

SHARED_GROUP="sharedusers"
SHARED_DIR="/home/shared"
COMMON_DIR="$SHARED_DIR/common"
FLATPAK_DIR="$COMMON_DIR/flatpak"
INSTALL_NAME="shared"
CONF="/etc/flatpak/installations.d/${INSTALL_NAME}.conf"
ENV_SHARED="$COMMON_DIR/env.shared"

MIGRATE="${MIGRATE:-1}"
KEEP_DIR="${KEEP_DIR:-0}"

log()  { echo "[+] $*"; }
warn() { echo "    ! $*" >&2; }

MIGRATION_OK=1

# ===========================================================================
log "Step 1: Collecting apps installed in the shared installation..."
APPS=()
if [ -f "$CONF" ] && command -v flatpak &>/dev/null; then
    while IFS= read -r app; do
        [ -n "$app" ] && APPS+=("$app")
    done < <(flatpak --installation="$INSTALL_NAME" list --app --columns=application 2>/dev/null \
             | grep -E '^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+)+$' || true)
fi
if [ "${#APPS[@]}" -gt 0 ]; then
    printf '    - %s\n' "${APPS[@]}"
else
    echo "    - none found"
fi

log "Step 2: Migrating apps to the system-wide Flatpak installation..."
if [ "$MIGRATE" = "1" ] && [ "${#APPS[@]}" -gt 0 ]; then
    flatpak --system remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
        || { warn "Could not add the flathub system remote"; MIGRATION_OK=0; }
    for app in "${APPS[@]}"; do
        if flatpak --system info "$app" &>/dev/null; then
            echo "    - $app already installed system-wide"
        elif flatpak --system install -y --noninteractive flathub "$app"; then
            echo "    - Installed $app system-wide"
        else
            warn "Failed to install $app system-wide"
            MIGRATION_OK=0
        fi
    done
else
    echo "    - skipped"
fi

log "Step 3: Removing the shared installation definition..."
if [ -f "$CONF" ]; then
    rm -f "$CONF"
    echo "    - removed $CONF"
else
    echo "    - $CONF not present"
fi
rmdir /etc/flatpak/installations.d 2>/dev/null || true

log "Step 4: Removing the flatpak() wrapper from env.shared..."
if [ -f "$ENV_SHARED" ] && grep -q 'installation=shared' "$ENV_SHARED"; then
    cp -p "$ENV_SHARED" "$ENV_SHARED.bak-flatpak"
    # Drop from the "# Flatpak: use the shared ..." comment through the function's closing "}"
    awk '
        /^# Flatpak: use the shared installation/ { skip = 1 }
        skip { if ($0 == "}") skip = 0; next }
        { print }
    ' "$ENV_SHARED.bak-flatpak" > "$ENV_SHARED"
    if grep -q 'installation=shared' "$ENV_SHARED"; then
        warn "Still found 'installation=shared' in $ENV_SHARED; please remove the flatpak() function by hand"
    else
        echo "    - wrapper removed (backup: $ENV_SHARED.bak-flatpak)"
    fi
else
    echo "    - nothing to remove"
fi

log "Step 5: Checking for other places that reference the shared path..."
if grep -rIn -E "common/flatpak|FLATPAK_USER_DIR" /etc /usr/lib/environment.d 2>/dev/null; then
    warn "The lines above still reference the shared Flatpak path; remove them if they are from this setup"
else
    echo "    - no system-wide references left"
fi

log "Step 6: Removing $FLATPAK_DIR..."
if [ -d "$FLATPAK_DIR" ]; then
    if [ "$KEEP_DIR" = "1" ]; then
        echo "    - kept (KEEP_DIR=1)"
    elif [ "$MIGRATION_OK" = "1" ]; then
        rm -rf "$FLATPAK_DIR"
        echo "    - removed"
    else
        warn "Migration had errors; keeping $FLATPAK_DIR (it is no longer used by Flatpak)"
    fi
else
    echo "    - not present"
fi

log "Step 7: Re-tightening permissions on $SHARED_DIR..."
# Undo any 'chmod o+x' workaround; keep the setgid bit and group access
for d in "$SHARED_DIR" "$COMMON_DIR"; do
    if [ -d "$d" ]; then
        chown root:"$SHARED_GROUP" "$d" 2>/dev/null || true
        chmod 2770 "$d"
        echo "    - $d -> 2770"
    fi
done

echo "[✔] Done."
echo "    Reboot so GDM and every user session regenerate XDG_DATA_DIRS without /home/shared."
echo "    Then check:  sudo journalctl -b | grep -i 'Permission denied'   (should show nothing from gdm/gnome-shell)"
echo "    Open shells still carry the old flatpak() function; run 'unset -f flatpak' or open a new terminal."
echo "    Flatpak app data in ~/.var/app was not touched."
