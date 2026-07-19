#!/bin/bash
echo "Installing flatpak and mission-center..."
# install flatpak
sudo apt install flatpak -y

# install flathub
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# define list of applications to install
APPS=(
    "io.missioncenter.MissionCenter"
    "org.gnome.Extensions"
    "org.videolan.VLC"
    "io.github.shiftey.Desktop"
    "org.libreoffice.LibreOffice"
    "org.geogebra.GeoGebra"
    "com.valvesoftware.Steam"
)

# loop through and install applications
for app in "${APPS[@]}"; do
    echo "Installing $app..."
    sudo flatpak install flathub "$app" -y
done

flatpak override --user --filesystem=/home/shared/steam com.valvesoftware.Steam

# append .profile file to set environment variables
# export GDK_BACKEND=x11
# export GSK_RENDERER=gl
cat << EOF >> ~/.profile
export GDK_BACKEND=x11
export GSK_RENDERER=gl
<< EOF

# GSK_RENDERER=gl flatpak run io.missioncenter.MissionCenter
# GDK_BACKEND=x11 flatpak run 