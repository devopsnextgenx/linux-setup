#!/usr/bin/env bash
# ==============================================================================
# Script Name: setup-gnome-rdp.sh
# Description: Idempotent configuration for native GNOME Wayland RDP
# ==============================================================================
set -euo pipefail

# Ensure this script is NOT run as root; it must configure the active user slice
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Please run this script as your standard user (admn), not root."
    exit 1
fi

echo "Cleaning up legacy TigerVNC artifacts..."
# Stop and disable old X11-based user services if they exist
systemctl --user stop vncserver.service 2>/dev/null || true
systemctl --user disable vncserver.service 2>/dev/null || true

# Define paths
CERT_DIR="$HOME/.config/gnome-remote-desktop"
CERT_FILE="$CERT_DIR/rdp.crt"
KEY_FILE="$CERT_DIR/rdp.key"

echo "Verifying TLS certificate generation..."
mkdir -p "$CERT_DIR"

if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    echo "Generating new self-signed TLS certificates..."
    openssl req -new -x509 -days 365 -nodes \
        -out "$CERT_FILE" \
        -keyout "$KEY_FILE" \
        -subj "/C=US/ST=Michigan/L=Troy/O=Local/CN=minis" 2>/dev/null
    echo "Certificates successfully generated."
else
    echo "Valid TLS certificates already exist. Skipping generation."
fi

echo "Configuring GNOME Remote Desktop (grdctl)..."
# Register certificates natively with the daemon
grdctl rdp set-tls-cert "$CERT_FILE"
grdctl rdp set-tls-key "$KEY_FILE"

# Enforce secure authentication parameters (Adjust password if needed)
grdctl rdp set-credentials admn "YourSecurePassword"

# Enable the RDP endpoint interface
grdctl rdp enable

echo "Reloading systemd user daemon structures..."
systemctl --user daemon-reload

echo "Restarting gnome-remote-desktop service..."
systemctl --user restart gnome-remote-desktop.service

echo "=================================================================="
echo "SUCCESS: Native GNOME Wayland RDP configuration completed!"
echo "Target service state:"
echo "=================================================================="
systemctl --user status gnome-remote-desktop.service --no-pager