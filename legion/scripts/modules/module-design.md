# Module Design Documentation

This document outlines the architecture and purpose of the scripts within the `scripts/modules/` directory.

## Overview

The scripts are organized into two primary categories: **Core Utilities** (used by all modules) and **Feature Modules** (which implement specific setup tasks). The modules are designed to be idempotent and often support both `setup_module` and `uninstall_module` operations.

## Core Scripts

### `config.sh`
**Purpose:** Centralized configuration for the entire setup.
- Defines environment variables for shared paths (`SHARED_DIR`, `COMMON_DIR`, `SHARE_DIR`, etc.).
- Stores repository URLs for icons, wallpapers, and themes.
- Configures ZSH markers and default user settings.

### `utils.sh`
**Purpose:** Common utility functions used across all modules.
- **Logging:** Color-coded output (`log`, `warn`, `error`, `info`, `success`).
- **System Helpers:** User existence checks, architecture detection, and root verification.
- **Package Management:** Wrappers for `apt` and `flatpak`.
- **File/Directory Helpers:** Directory creation (`ensure_dirs`), symlinking (`link_entries`), and repository synchronization (`sync_repo`).
- **State Management:** Helpers for tracking installation state via stamps (`needs_install`, `write_stamp`).

## Feature Modules

### `osx-setup/`
**Goal:** Provide a macOS-like visual and terminal experience on Linux.

| Script | Description |
| :--- | :--- |
| `01-system.sh` | Sets up the `sharedusers` group, installs base packages (zsh, git, etc.), and sets ZSH as the default shell for all users. |
| `02-p10k.sh` | Installs and configures the `Powerlevel10k` zsh theme in the shared directory. |
| `03-icons.sh` | Installs the `MacTahoe` icon theme. |
| `04-wallpapers.sh` | Installs the `WhiteSur` wallpaper collection. |
| `05-themes.sh` | Installs the `WhiteSur` GTK theme and applies GDM (login screen) tweaks. |
| `06-user-profile.sh` | Configures `.zshrc` for users to source shared themes/configs and sets up symlinks for themes and icons in user home directories. |

### `shared-setup/`
**Goal:** Provide a standardized, shared development environment for all users.

| Script | Description |
| :--- | :--- |
| `01-users.sh` | Manages the `sharedusers` group and configures `subuid`/`subgid` for rootless containers. |
| `02-directories.sh` | Creates the shared `/home/shared` directory structure and sub-directories for tools and Podman. |
| `03-packages.sh` | Installs essential system packages via `apt` and `flatpak` (e.g., podman, kind, gnome-tweaks). |
| `04-tools.sh` | Installs developer toolchains (NVM/Node.js, Python venv, Rust/Cargo, Go) into shared paths. |
| `05-podman.sh` | Configures rootless Podman with shared image/container storage and provides a `podman-get` helper for efficient image sharing. |
| `06-environment.sh` | Generates a `env.shared` file that maps shared tool paths to environment variables for users. |
| `07-bashrc.sh` | Automatically configures user `.bashrc` files to source the shared `env.shared` file. |

## Summary of Directory Structure

```text
scripts/modules/
├── config.sh            # Global configuration
├── utils.sh            # Common utility functions
├── module-design.md    # This documentation
├── osx-setup/           # macOS-like visual setup
│   ├── 01-system.sh
│   ├── 02-p10k.sh
│   ├── 03-icons.sh
│   ├── 04-wallpapers.sh
│   ├── 05-themes.sh
│   └── 06-user-profile.sh
└── shared-setup/        # Shared developer environment
    ├── 01-users.sh
    ├── 02-directories.sh
    ├── 03-packages.sh
    ├── 04-tools.sh
    ├── 05-podman.sh
    ├── 06-environment.sh
    └── 07-bashrc.sh
```
