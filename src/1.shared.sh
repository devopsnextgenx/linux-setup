#!/bin/sh
echo "Setting up shared directory..."
sudo mkdir -p /home/shared
sudo groupadd shared
sudo usermod -a -G shared $USER
sudo chown -R :shared /home/shared
sudo chmod -R g+rwx /home/shared
sudo chmod -R g+s /home/shared

# install python3-venv
echo "Installing python3-venv..."
sudo apt install python3-venv -y
echo "Creating python3 virtual environment..."
sudo python3 -m venv /home/shared/pyenv
sudo chown :shared /home/shared/pyenv
sudo chmod g+rwx /home/shared/pyenv
sudo chmod g+s /home/shared/pyenv

# add plex/jellyfin setup
sudo usermod -aG shared plex
sudo mkdir -p /home/shared/plex/Library
sudo chown :shared /home/shared/plex/Library
sudo chmod g+rwx /home/shared/plex/Library
sudo chmod g+s /home/shared/plex/Library

sudo usermod -aG shared jellyfin
sudo usermod -aG jellyfin admn

sudo chgrp -R shared /home/shared/jellyfin
sudo chmod -R g+rwx /home/shared/jellyfin
sudo chmod -R g+s /home/shared/jellyfin
sudo mkdir -p /home/shared/jellyfin/{jellyfin-data,jellyfin-cache,jellyfin-config}
sudo chown -R jellyfin:shared /home/shared/jellyfin
