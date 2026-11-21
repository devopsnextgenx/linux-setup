#!/bin/bash
set -euo pipefail

setup_module() {
    log "Step 1: Ensuring group '$SHARED_GROUP' and membership..."
    groupadd -f "$SHARED_GROUP"
    for user in "${USERS[@]}"; do
        if user_exists "$user"; then
            if id -nG "$user" | tr ' ' '\n' | grep -qx "$SHARED_GROUP"; then
                log "    - $user already in $SHARED_GROUP"
            else
                usermod -aG "$SHARED_GROUP" "$user"
                log "    - Added $user to $SHARED_GROUP"
            fi
        else
            warn "User '$user' does not exist. Skipping."
        fi
    done

    log "Step 3: Installing packages via apt..."
    apt-get update
    apt-get install -y zsh git curl sassc libglib2.0-dev-bin libxml2-utils
    if apt_has gnome-shell-extensions; then
        apt-get install -y gnome-shell-extensions
    fi

    log "Step 5: zsh as login shell..."
    ZSH_PATH="$(command -v zsh)"
    grep -qx "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" >> /etc/shells
    for user in "${USERS[@]}"; do
        if user_exists "$user"; then
            current=$(getent passwd "$user" | cut -d: -f7)
            if [ "$current" = "$ZSH_PATH" ]; then
                log "    - $user already uses zsh"
            else
                chsh -s "$ZSH_PATH" "$user"
                log "    - Changed shell for $user ($current -> $ZSH_PATH)"
            fi
        fi
    done

    # Default shell for newly created users
    if [ -f /etc/default/useradd ]; then
        if grep -q '^SHELL=' /etc/default/useradd; then
            sed -i "s|^SHELL=.*|SHELL=$ZSH_PATH|" /etc/default/useradd
        else
            echo "SHELL=$ZSH_PATH" >> /etc/default/useradd
        fi
    fi
    if [ -f /etc/adduser.conf ]; then
        if grep -q '^DSHELL=' /etc/adduser.conf; then
            sed -i "s|^DSHELL=.*|DSHELL=$ZSH_PATH|" /etc/adduser.conf
        else
            echo "DSHELL=$ZSH_PATH" >> /etc/adduser.conf
        fi
    fi
}

uninstall_module() {
    log "Uninstalling system changes (non-destructive where possible)..."
    for user in "${USERS[@]}"; do
        if user_exists "$user"; then
            gpasswd -d "$SHARED_GROUP" "$user" || true
        fi
    done
}

return 0
