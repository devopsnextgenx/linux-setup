#!/bin/bash

./20.flatpak.sh

echo -e "Setting up powerlevel10k!!!"
chsh -s $(which zsh)
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc

profile_file=(
    ".bashrc"
    ".p10k.zsh"
    ".profile"
    ".zshrc"
)

for i in "${!profile_file[@]}"; do
    file="${profile_file[$i]}"
    cp "../profile/$file" ~/
done

mkdir ~/tmp
git clone https://github.com/vinceliuice/WhiteSur-wallpapers.git --depth=1 ~/tmp/WhiteSur-wallpapers
cd ~/tmp/WhiteSur-wallpapers
chmod 755 *.sh
./install-gnome-backgrounds.sh
./install-wallpapers.sh

git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth=1 ~/tmp/WhiteSur-gtk-theme
cd ~/tmp/WhiteSur-gtk-theme
chmod 755 *.sh
./install.sh -o normal -c Dark -a normal -m -t all -l -N stable -HD --shell -i apple -b default -p --black --dialog
sudo ./tweaks.sh -g
./tweaks.sh -F -f default

