#!/bin/bash
set -euo pipefail

# --- Default Configuration ---
export SHARED_GROUP="sharedusers"
export SHARED_DIR="/home/shared"
export P10K_DIR="$SHARED_DIR/powerlevel10k"
export P10K_CONFIG="$SHARED_DIR/.p10k.zsh"
export COMMON_DIR="$SHARED_DIR/common"
export SRC_DIR="$SHARED_DIR/src"
export STAMP_DIR="$SRC_DIR/.stamps"
export SHARE_DIR="$SHARED_DIR/share"
export PODMAN_DIR="$COMMON_DIR/podman"
export PODMAN_USERS_DIR="$PODMAN_DIR/users"
export PODMAN_ARCHIVES_DIR="$PODMAN_DIR/archives"
export THEMES_DEST="$SHARE_DIR/themes"
export ICONS_DEST="$SHARE_DIR/icons"

# Repo URLs
export REPO_P10K="https://github.com/romkatv/powerlevel10k.git"
export REPO_ICONS="https://github.com/vinceliuice/MacTahoe-icon-theme"
export REPO_WALLPAPERS="https://github.com/vinceliuice/WhiteSur-wallpapers.git"
export REPO_GTK="https://github.com/vinceliuice/WhiteSur-gtk-theme.git"

# ZSHRC Markers
export ZSH_TOP_MARK="# >>> shared-p10k-instant-prompt >>>"
export ZSH_BOTTOM_MARK="# >>> shared-p10k >>>"

# Defaults for flags
export DEFAULT_FORCE=0
export DEFAULT_ENABLE_GDM_TWEAK=1
export DEFAULT_ENABLE_FIREFOX_TWEAK=0

# Defaults for extra users
export DEFAULT_USERS=("kira" "admn")