#!/bin/sh
set -e # Exit immediately if a command exits with a non-zero status

echo "===================================================="
echo "Setting up Docker and Podman with shared storage..."
echo "===================================================="

# -------------------------------------------------------------------------
# 1. USER SETUP & MANAGEMENT
# -------------------------------------------------------------------------
echo "Ensuring users 'admn' and 'kira' exist..."
for username in admn kira; do
  if ! id "$username" >/dev/null 2>&1; then
    echo "User '$username' not found. Creating user..."
    sudo useradd -m -s /bin/bash "$username"
  else
    echo "User '$username' already exists."
  fi
done

# Ensure the system groups exist before assigning users
sudo groupadd -f docker
sudo groupadd -f containers

# Add both users to the required groups
for username in admn kira; do
  echo "Adding $username to docker and containers groups..."
  sudo usermod -aG docker "$username"
  sudo usermod -aG containers "$username"
done

# -------------------------------------------------------------------------
# 2. CREATE DIRECTORIES
# -------------------------------------------------------------------------
echo "Creating isolated directories under /home/shared..."
sudo mkdir -p /home/shared/docker
sudo mkdir -p /home/shared/podman

# -------------------------------------------------------------------------
# 3. CONFIGURE DOCKER STORAGE & INSTALLATION
# -------------------------------------------------------------------------
echo "Configuring Docker daemon root path..."
sudo mkdir -p /etc/docker
echo '{
  "data-root": "/home/shared/docker"
}' | sudo tee /etc/docker/daemon.json > /dev/null

echo "Installing Docker dependencies and repository..."
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

sudo mkdir -p /usr/share/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Installing Docker packages..."
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Set up directory permissions for Docker
sudo chown admn:docker /home/shared/docker
sudo chmod g+rwx /home/shared/docker
sudo chmod g+s /home/shared/docker

# -------------------------------------------------------------------------
# 4. CONFIGURE PODMAN STORAGE & INSTALLATION
# -------------------------------------------------------------------------
echo "Installing Podman..."
sudo apt install -y podman podman-compose

echo "Configuring Podman global storage path..."
sudo mkdir -p /etc/containers
sudo tee /etc/containers/storage.conf > /dev/null <<EOF
[storage]
driver = "overlay"
runroot = "/run/containers/storage"
graphroot = "/home/shared/podman"
EOF

# Set up directory permissions for Podman
sudo chown admn:containers /home/shared/podman
sudo chmod g+rwx /home/shared/podman
sudo chmod g+s /home/shared/podman

# -------------------------------------------------------------------------
# 5. START SERVICES & VERIFY
# -------------------------------------------------------------------------
echo "Restarting services..."
sudo systemctl daemon-reload
sudo systemctl restart docker

echo "===================================================="
echo " Setup Complete!"
echo " - Docker Root: /home/shared/docker"
echo " - Podman Root: /home/shared/podman"
echo " - Users configured: admn, kira"
echo "===================================================="
echo "NOTE: Both 'admn' and 'kira' must log out and log back in for their new group memberships to take effect."
