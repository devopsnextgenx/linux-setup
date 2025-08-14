#!/bin/sh
echo "Setting up Docker with shared directory..."
sudo mkdir -p /home/shared/docker
# ...existing code...
# add content to /etc/docker/daemon.json
sudo mkdir -p /etc/docker
echo '{
  "data-root": "/home/shared/docker"
}' | sudo tee /etc/docker/daemon.json > /dev/null
# ...existing code...

sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker $USER
sudo chown :docker /home/shared/docker
sudo chmod g+rwx /home/shared/docker
sudo chmod g+s /home/shared/docker
# add content to /etc/docker/daemon.json


sudo mkdir -p /home/shared/jellyfin/cache
sudo chown :docker /home/shared/jellyfin/cache
sudo chmod g+rwx /home/shared/jellyfin/cache
sudo chmod g+s /home/shared/jellyfin/cache
sudo mkdir -p /home/shared/jellyfin/config
sudo chown :docker /home/shared/jellyfin/config
sudo chmod g+rwx /home/shared/jellyfin/config
sudo chmod g+s /home/shared/jellyfin/config
