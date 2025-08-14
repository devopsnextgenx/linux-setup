#!/bin/sh
echo "Setting up shared directory..."
sudo mkdir -p /home/shared
sudo groupadd shared
sudo usermod -a -G shared $USER
sudo chown :shared /home/shared
sudo chmod g+rwx /home/shared
sudo chmod g+s /home/shared

# install python3-venv
echo "Installing python3-venv..."
sudo apt install python3-venv -y
echo "Creating python3 virtual environment..."
sudo python3 -m venv /home/shared/pyenv
sudo chown :shared /home/shared/pyenv
sudo chmod g+rwx /home/shared/pyenv
sudo chmod g+s /home/shared/pyenv