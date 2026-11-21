#!/bin/bash
# modules/shared-setup/05-podman.sh

setup_podman() {
    info "Step 8: Setting up Ollama..."
    chmod 770 "$COMMON_DIR/ollama"
    if [ -n "$(systemctl list-unit-files ollama.service --no-legend 2>/dev/null)" ]; then
        mkdir -p /etc/systemd/system/ollama.service.d
        cat << EOF > /etc/systemd/system/ollama.service.d/override.conf
[Service]
Environment="OLLAMA_MODELS=$COMMON_DIR/ollama"
EOF
        systemctl daemon-reload
        systemctl restart ollama || true
    fi

    info "Step 9: Podman setup (graphroots + image cache under $PODMAN_DIR)..."
    # (Legacy check is just info)
    if [ -d "$PODMAN_DIR/images" ]; then
        warn "    - Legacy shared image store found at $PODMAN_DIR/images (unused now)."
    fi

    # 9a. Non-overlapping subuid/subgid ranges for rootless podman
    # (Already handled in 01-users.sh for setup, but let's ensure)
    for user in "${USERS[@]}"; do
        if id "$user" &>/dev/null; then
            add_subid_range /etc/subuid "$user"
            add_subid_range /etc/subgid "$user"
        fi
    done

    # 9b. Directory permissions
    chown root:"$SHARED_GROUP" "$PODMAN_DIR" "$PODMAN_USERS_DIR" "$PODMAN_ARCHIVES_DIR"
    chmod 2771 "$PODMAN_DIR" "$PODMAN_USERS_DIR"
    chmod 2770 "$PODMAN_ARCHIVES_DIR"

    for user in "${USERS[@]}"; do
        if id "$user" &>/dev/null; then
            install -d -m 0700 -o "$user" -g "$SHARED_GROUP" "$PODMAN_USERS_DIR/$user"
            install -d -m 0700 -o "$user" -g "$SHARED_GROUP" "$PODMAN_USERS_DIR/$user/storage"
        fi
    done

    # 9c. Per-user storage.conf -> graphroot in the common location
    for user in "${USERS[@]}"; do
        if id "$user" &>/dev/null; then
            local user_home=$(getent passwd "$user" | cut -d: -f6)
            local conf_dir="$user_home/.config/containers"
            local conf_file="$conf_dir/storage.conf"
            [ -d "$user_home/.config" ] || install -d -m 0700 -o "$user" -g "$user" "$user_home/.config"
            install -d -m 0755 -o "$user" -g "$user" "$conf_dir"

            local new_conf="[storage]
driver = \"overlay\"
graphroot = \"$PODMAN_USERS_DIR/$user/storage\""

            if [ -f "$conf_file" ] && [ "$(cat "$conf_file")" != "$new_conf" ]; then
                cp -a "$conf_file" "$conf_file.bak.$(date +%s)"
            fi
            printf '%s\n' "$new_conf" > "$conf_file"
            chown "$user":"$user" "$conf_file"
            chmod 644 "$conf_file"
        fi
    done

    # 9d. Helper: podman-get
    info "    - Creating /usr/local/bin/podman-get..."
    cat << 'EOF' > "$PODMAN_GET_PATH"
#!/bin/bash
# Get an image without downloading it twice across users.
# Usage: podman-get docker.io/library/alpine [image...]
set -euo pipefail
ARCHIVES="$PODMAN_ARCHIVES_DIR"
[ $# -ge 1 ] || { echo "Usage: podman-get <image> [image...]" >&2; exit 1; }
for ref in "$@"; do
    key=$(printf '%s' "$ref" | tr '/:@' '___')
    tar="$ARCHIVES/$key.tar"
    if podman image exists "$ref"; then
        echo "[=] $ref already in your local store"
    elif [ -f "$tar" ]; then
        echo "[+] Loading $ref from shared cache (no download)"
        podman load -i "$tar"
    else
        echo "[+] Pulling $ref"
        podman pull "$ref"
    fi
    if [ ! -f "$tar" ]; then
        echo "[+] Saving $ref to shared cache"
        podman save --format oci-archive -o "$tar.tmp" "$ref"
        chmod 664 "$tar.tmp"
        mv "$tar.tmp" "$tar"
    fi
done
EOF
    chmod 755 "$PODMAN_GET_PATH"
}

uninstall_podman() {
    warn "Cleaning up Podman configurations and helper..."
    rm -f "$PODMAN_GET_PATH"
    # Note: removing subuid/subgid and storage.conf might require manual user intervention 
    # to avoid breaking user's local podman. We'll skip it to be safe.
}
