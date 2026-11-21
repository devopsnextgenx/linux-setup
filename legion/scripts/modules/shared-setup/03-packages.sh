#!/bin/bash
# modules/shared-setup/03-packages.sh

setup_packages() {
    info "Step 5: Installing base packages via apt (global)..."
    apt-get update
    apt-get install -y curl ca-certificates python3-venv python3-pip \
        flatpak podman uidmap fuse-overlayfs gnome-tweaks

    # gnome extension manager
    if apt_has gnome-shell-extension-manager; then
        apt-get install -y gnome-shell-extension-manager
    else
        info "    - gnome-shell-extension-manager not in apt; will use Flatpak instead"
        fp install -y --noninteractive flathub com.mattjakeman.ExtensionManager || true
    fi

    # kind (global): prefer apt, otherwise install the pinned upstream binary
    if apt_has kind; then
        apt-get install -y kind
    elif command -v kind &>/dev/null; then
        info "    - kind already installed: $(command -v kind)"
    else
        info "    - kind not in apt; installing ${KIND_VERSION} to /usr/local/bin"
        local arch=$(get_arch)
        curl -fsSLo /tmp/kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${arch}"
        install -m 0755 /tmp/kind /usr/local/bin/kind
        rm -f /tmp/kind
    fi

    info "Step 6: Installing Flatpak apps system-wide..."
    fp remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

    for app in "${FLATPAK_APPS[@]}"; do
        if fp_installed "$app"; then
            info "    - $app already installed"
        else
            info "    - Installing $app..."
            fp install -y --noninteractive flathub "$app"
        fi
    done
}

uninstall_packages() {
    warn "Removing installed packages..."
    apt-get remove -y curl ca-certificates python3-venv python3-pip flatpak podman uidmap fuse-overlayfs gnome-tweaks kind || true
    # We don't necessarily want to uninstall flatpak apps as they might be used by other things, 
    # but for a complete uninstall we could.
}
