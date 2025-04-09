#!/bin/bash

# check if $USER ALL=(ALL:ALL) NOPASSWD: ALL exists in /etc/sudoers.d/$USER
if grep -q "$USER ALL=(ALL:ALL) NOPASSWD: ALL" /etc/sudoers.d/$USER; then
    echo "User $USER already has sudo privileges without password."
else
    echo "Adding user $USER to sudo group without password..."
    # add user to sudo group without password
    echo "$USER ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/$USER
fi

# First install nala using apt
echo "Installing nala package manager..."
sudo apt install nala -y

# Define packages to install
packages=(
    "git"
    "zsh"
    "podman"
    "yq"
    "jq"
)

# Progress bar function
show_progress() {
    local current=$1
    local total=$2
    local package=$3
    local width=50
    local percent=$((current * 100 / total))
    local completed=$((width * current / total))
    local remaining=$((width - completed))
    
    # Save cursor position and clear from cursor to end of screen
    tput sc
    tput el
    printf "Installing packages: ["
    printf "%${completed}s" | tr ' ' '#'
    printf "%${remaining}s" | tr ' ' '-'
    printf "] %3d%%" "$percent"
    printf " (Current: %s)" "$package"
    # Restore cursor position
    tput rc
}

# Install packages with progress bar
total=${#packages[@]}
echo -n "Starting package installations..."
# Move cursor to next line and save position
echo
tput sc

for i in "${!packages[@]}"; do
    package="${packages[$i]}"
    # Check if package is already installed
    if ! dpkg -l | grep -q "^ii.*$package"; then
        show_progress "$((i + 1))" "$total" "$package"
        sudo nala install -y "$package" >/dev/null 2>&1
    else
        show_progress "$((i + 1))" "$total" "$package (already installed)"
    fi
done

# Move cursor to next line after completion
echo -e "\nAll packages installed successfully!"


# setup tools
./1.shared.sh
./5.gnome-extensions.sh
./10.llm.sh

# install mission-center
./20.flatpak.sh