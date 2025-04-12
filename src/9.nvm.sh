#!/usr/bin/env bash
# Install NVM (Node Version Manager)
# This script installs NVM globally for all users on the system.
# It creates a directory at /usr/local/nvm and sets up the necessary environment variables.

export NVM_VERSION=v0.40.2
export NVM_DIR=/usr/local/nvm


sudo mkdir -p $NVM_DIR
echo "Installing NVM version $NVM_VERSION at $NVM_DIR..."
sudo curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | sudo NVM_DIR=$NVM_DIR bash

# It also creates a profile script to load NVM automatically for all users.
sudo tee /etc/profile.d/nvm.sh > /dev/null << 'EOF'
export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF

# Set permissions for the profile script
sudo chmod +x /etc/profile.d/nvm.sh
