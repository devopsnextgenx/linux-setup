#!/bin/sh
echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER
# install nala
sudo apt install nala -y
# install git
sudo nala install git -y
# install zsh
sudo nala install zsh -y
# install podman
sudo nala install podman -y
# install yq
sudo nala install yq jq -y

# setup tools
./1.shared.sh
./10.llm.sh

# install mission-center
./20.flatpak.sh