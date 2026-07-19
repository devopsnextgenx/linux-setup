#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# --- CONFIGURATION ---
EXPORT_NVM_VERSION="v0.40.2"
EXPORT_NVM_DIR="/home/shared/nvm"
SHARED_GROUP="shared" # Change this to the group your users share

echo "=== Starting Shared NVM Setup at $EXPORT_NVM_DIR ==="

# 1. Handle directory creation and permissions
echo "Step 1: Setting up shared directory permissions..."
if [ ! -d "$EXPORT_NVM_DIR" ]; then
    echo "Creating directory $EXPORT_NVM_DIR..."
    sudo mkdir -p "$EXPORT_NVM_DIR"
fi

# Ensure correct ownership and write permissions for the shared group
sudo chown -R root:$SHARED_GROUP "$EXPORT_NVM_DIR"
sudo chmod -R 775 "$EXPORT_NVM_DIR"
sudo chmod g+s "$EXPORT_NVM_DIR" # Force new files to inherit the group

# 2. Idempotently install NVM into the new shared location
echo "Step 2: Checking NVM installation..."
if [ ! -f "$EXPORT_NVM_DIR/nvm.sh" ]; then
    echo "Installing NVM version $EXPORT_NVM_VERSION at $EXPORT_NVM_DIR..."
    sudo NVM_DIR="$EXPORT_NVM_DIR" curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$EXPORT_NVM_VERSION/install.sh" | sudo NVM_DIR="$EXPORT_NVM_DIR" bash
    
    # Fix permissions right after installation to ensure group can write
    sudo chmod -R g+w "$EXPORT_NVM_DIR"
else
    echo "NVM is already installed in $EXPORT_NVM_DIR. Skipping install."
fi

# 3. Overwrite the system-wide profile script to point to the new location
echo "Step 3: Updating system-wide profile (/etc/profile.d/nvm.sh)..."
sudo tee /etc/profile.d/nvm.sh > /dev/null << EOF
# System-wide Shared NVM Configuration
export NVM_DIR="$EXPORT_NVM_DIR"
export NVM_SYMLINK_CURRENT="true"

[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"

# Prevent permission clashes by keeping global npm packages separate per user
export NPM_CONFIG_PREFIX="\$HOME/.npm-global"
export PATH="\$HOME/.npm-global/bin:\$PATH"
EOF

# Make sure the system profile script is executable
sudo chmod +x /etc/profile.d/nvm.sh

# 4. Cleanup old artifact if it exists from the previous setup
if [ -d "/usr/local/nvm" ]; then
    echo "Note: Old NVM directory found at /usr/local/nvm. You can safely delete it later via: sudo rm -rf /usr/local/nvm"
fi

echo "=== Setup complete! Please restart your terminal session to apply changes ==="