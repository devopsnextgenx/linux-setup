#!/bin/sh
echo "Setting up shared directory..."
sudo mkdir -p /home/shared
sudo groupadd shared
sudo usermod -a -G shared $USER
sudo chown -R :shared /home/shared
sudo chgrp -R shared /home/shared
sudo chmod -R g+rwx /home/shared
sudo chmod -R g+s /home/shared

# install python3-venv
echo "Installing python3-venv..."
sudo apt install python3-venv -y
echo "Creating python3 virtual environment..."
sudo python3 -m venv /home/shared/pyenv
sudo chown -R :shared /home/shared/pyenv
sudo chgrp -R shared /home/shared/pyenv
sudo chmod -R g+rwx /home/shared/pyenv
sudo chmod -R g+s /home/shared/pyenv

# add plex/jellyfin setup
sudo usermod -aG shared plex
sudo mkdir -p /home/shared/plex/Library
sudo chown -R :shared /home/shared/plex/Library
sudo chgrp -R shared /home/shared/plex/Library
sudo chmod g+rwx /home/shared/plex/Library
sudo chmod g+s /home/shared/plex/Library

sudo usermod -aG shared jellyfin
sudo usermod -aG jellyfin admn

sudo chgrp -R shared /home/shared/jellyfin
sudo chmod -R g+rwx /home/shared/jellyfin
sudo chmod -R g+s /home/shared/jellyfin
sudo mkdir -p /home/shared/jellyfin/{jellyfin-data,jellyfin-cache,jellyfin-config}
sudo chown -R jellyfin:shared /home/shared/jellyfin

# add docker shared directory
sudo usermod -aG docker $USER
sudo chown :docker /home/shared/docker
sudo chmod g+rwx /home/shared/docker
sudo chmod g+s /home/shared/docker

# modify docker daemon.json to use shared directory
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json << EOF
{
  "data-root": "/home/shared/docker"
}
EOF
sudo chmod 600 /etc/docker/daemon.json
sudo systemctl restart docker

# add ollama shared directory (models, keys, server config)
sudo mkdir -p /home/shared/ollama/.ollama/models
sudo usermod -aG shared ollama 2>/dev/null || true
sudo chown -R ollama:shared /home/shared/ollama
sudo chmod -R g+rwx /home/shared/ollama
sudo chmod -R g+s /home/shared/ollama

# add lmstudio shared directory (models, runtime engines, CLI cache, app config)
sudo mkdir -p \
  /home/shared/lmstudio/.lmstudio/models \
  /home/shared/lmstudio/.lmstudio/bin \
  /home/shared/lmstudio/.lmstudio/.internal \
  /home/shared/lmstudio/cache/lm-studio \
  "/home/shared/lmstudio/config/LM Studio"
sudo chown -R :shared /home/shared/lmstudio
sudo chmod -R g+rwx /home/shared/lmstudio
sudo chmod -R g+s /home/shared/lmstudio

# add steam shared directory (shared game library across local users)
echo "Setting up Steam shared directory..."
sudo mkdir -p /home/shared/steam
sudo chown -R :shared /home/shared/steam
sudo chgrp -R shared /home/shared/steam
sudo chmod -R g+rwx /home/shared/steam
sudo chmod -R g+s /home/shared/steam
sudo setfacl -R -d -m g:shared:rwx /home/shared/steam
sudo setfacl -R -m g:shared:rwx /home/shared/steam


echo "Setup complete! Please restart your session for group changes to take effect."