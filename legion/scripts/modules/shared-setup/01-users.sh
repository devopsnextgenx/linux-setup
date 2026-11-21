#!/bin/bash
# modules/shared-setup/01-users.sh

setup_users() {
    info "Step 1: Creating shared user group '$SHARED_GROUP'..."
    groupadd -f "$SHARED_GROUP"

    info "Step 2: Adding users to '$SHARED_GROUP'..."
    for user in "${USERS[@]}"; do
        if id "$user" &>/dev/null; then
            if id -nG "$user" | tr ' ' '\n' | grep -qx "$SHARED_GROUP"; then
                info "    - $user already in $SHARED_GROUP"
            else
                usermod -aG "$SHARED_GROUP" "$user"
                success "    - Added $user to $SHARED_GROUP"
            fi
        else
            warn "    - User '$user' does not exist. Skipping."
        fi
    done

    info "Step 3: Configuring subuid/subgid for users..."
    for user in "${USERS[@]}"; do
        if id "$user" &>/dev/null; then
            add_subid_range /etc/subuid "$user"
            add_subid_range /etc/subgid "$user"
            success "    - Configured subuid/subgid for $user"
        fi
    done
}

uninstall_users() {
    warn "Uninstalling user group '$SHARED_GROUP'..."
    groupdel "$SHARED_GROUP" || true
    
    # Note: Removing subuid/subgid entries can be dangerous if other things use them.
    # In a real system, we'd need to be careful.
    info "Removing subuid/subgid entries for users..."
    for user in "${USERS[@]}"; do
        sed -i "/^${user}:/d" /etc/subuid
        sed -i "/^${user}:/d" /etc/subgid
    done
}
