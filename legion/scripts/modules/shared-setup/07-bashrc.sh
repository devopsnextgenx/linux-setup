#!/bin/bash
# modules/shared-setup/07-bashrc.sh

setup_bashrc() {
    info "Step 12: Configuring .bashrc auto-source for users..."
    for user in "${USERS[@]}"; do
        if id "$user" &>/dev/null; then
            local user_home=$(getent passwd "$user" | cut -d: -f6)
            local bashrc_path="$user_home/.bashrc"

            if [ -f "$bashrc_path" ]; then
                if ! grep -q "env.shared" "$bashrc_path"; then
                    {
                        echo ""
                        echo "# Source shared common environment"
                        echo "[ -f /home/shared/common/env.shared ] && source /home/shared/common/env.shared"
                    } >> "$bashrc_path"
                    chown "$user":"$user" "$bashrc_path"
                    success "    - Added source line to $bashrc_path"
                else
                    info "    - $bashrc_path already configured"
                fi
            fi
        fi
    done
}

uninstall_bashrc() {
    warn "Removing .bashrc source lines for users..."
    for user in "${USERS[@]}"; do
        if id "$user" &>/dev/null; then
            local user_home=$(getent passwd "$user" | cut -d: -f6)
            local bashrc_path="$user_home/.bashrc"
            if [ -f "$bashrc_path" ]; then
                sed -i '/# Source shared common environment/,/\[ -f \/home\/shared\/common\/env.shared/d' "$bashrc_path" || true
                # The above might be too aggressive. A simpler way:
                # sed -i '/# Source shared common environment/,/source \/home\/shared\/common\/env.sh/d' "$bashrc_path"
                # But let's be careful with regex.
            fi
        fi
    done
}
