#!/bin/bash
# setup-powerlevel10k-osx.sh (Orchestrator)

set -euo pipefail

# Determine base directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MODULES_DIR="$SCRIPT_DIR/modules/osx-setup"

# Source foundation
source "$SCRIPT_DIR/modules/config.sh"
source "$SCRIPT_DIR/modules/utils.sh"

# Default values
export FORCE=0
export ENABLE_GDM_TWEAK=1
export ENABLE_FIREFOX_TWEAK=0
export P10K_SRC=""
export EXTRA_USERS=()
export ENABLE_AMDGPU_TOP=0

show_help() {
    cat <<EOF
Usage: sudo ./setup-powerlevel10k-osx.sh [options] [extra_user ...]

Options:
  -h, --help             Show this help message and exit
  -v, --version          Show version information
  --uninstall             Undo changes made by the script
  --dry-run              Show what the script would do without making changes
  --verify               Check if the changes are correct and valid
  --force                Override existing files or settings (ask for confirmation)
  --p10k-src <path>      Path to the .p10k.zsh config to install
  --no-gdm-tweak         Skip the GDM login-screen tweak
  --enable-firefox       Run the WhiteSur Firefox tweak per user
  --install-amdgpu-top    Install amdgpu_top package
}

show_version() {
    echo "setup-powerlevel10k-osx.sh version 1.0.0"
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) show_help; exit 0 ;;
            -v|--version) show_version; exit 0 ;;
            --uninstall) ACTION="uninstall"; shift ;;
            --dry-run) DRY_RUN=true; shift ;;
            --verify) VERIFY=true; shift ;;
            --force) FORCE=1; shift ;;
            --p10k-src) P10K_SRC="$2"; shift 2 ;;
            --no-gdm-tweak) ENABLE_GDM_TWEAK=0; shift ;;
            --enable-firefox) ENABLE_FIREFOX_TWEAK=1; shift ;;
            -*) echo "Unknown option: $1" >&2; show_help; exit 1 ;;
            *) EXTRA_USERS+=("$1"); shift ;;
        esac
    done
}

# Handle user input
if [ $# -eq 0 ]; then
    parse_args "$@"
else
    parse_args "$@"
    export USERS=("kira" "admn" "${EXTRA_USERS[@]}")
fi

# Pre-check
if [ "$EUID" -ne 0 ]; then
    error "This script must be run as root (sudo)."
    exit 1
fi

if [ "$DRY_RUN" = true ]; then
    info "DRY RUN MODE: No changes will be made."
fi

# Configuration for P10K_SRC if not provided
if [ -z "$P10K_SRC" ]; then
    for f in "$SCRIPT_DIR/_p10k.zsh" "$SCRIPT_DIR/.p10k.zsh"; do
        [ -f "$f" ] && P10K_SRC="$f" && break
    done
fi

# Module Execution Wrapper
run_module() {
    local module_script="$1"
    local module_name="$2"

    if [ "$DRY_RUN" = true ]; then
        log "[DRY-RUN] Would execute $module_name ($module_script)"
        return 0
    fi

    # Source the module
    # We use a subshell to prevent module-level variables from leaking, 
    # but we want to capture return codes.
    (
        set -euo pipefail
        source "$module_script"
        if [ "$ACTION" = "uninstall" ]; then
            uninstall_module
        else
            setup_module
        fi
    )

    local status=$?
    if [ $status -ne 0 ]; then
        error "Module $module_name failed!"
        return $status
    fi
}

# Orchestration Logic
main() {
    # 1. Initialize Environment
    log "Starting Orchestrator..."
    mkdir -p "$SRC_DIR" "$STAMP_DIR" "$THEMES_DEST" "$ICONS_DEST" "$P10K_DIR" "$SHARE_DIR"
    chown root:"$SHARED_GROUP" "$SHARE_DIR" "$P10K_DIR"
    chmod 2770 "$SHARE_DIR"

    if [ "$ACTION" = "uninstall" ]; then
        # Uninstall in reverse order
        run_module "$MODULES_DIR/06-user-profile.sh" "user_profile"
        run_module "$MODULES_DIR/05-themes.sh" "themes"
        run_module "$MODULES_DIR/04-wallpapers.sh" "wallpapers"
        run_module "$MODULES_DIR/03-icons.sh" "icons"
        run_module "$MODULES_DIR/02-p10k.sh" "p10k"
        run_module "$MODULES_DIR/01-system.sh" "system"
    else
        # Setup in order
        run_module "$MODULES_DIR/01-system.sh" "system"
        run_module "$MODULES_DIR/02-p10k.sh" "p10k"
        run_module "$MODULES_DIR/03-icons.sh" "icons"
        run_module "$MODULES_DIR/04-wallpapers.sh" "wallpapers"
        run_module "$MODULES_DIR/05-themes.sh" "themes"
        run_module "$MODULES_DIR/06-user-profile.sh" "user_profile"

        if [ "$VERIFY" = true ]; then
            log "Running verification..."
            # Verification logic would go here, e.g. checking if files exist
            # For now, just checking if critical directories exist
            for d in "$P10K_DIR" "$THEMES_DEST" "$ICONS_DEST"; do
                if [ ! -d "$d" ]; then
                    error "Verification failed: $d does not exist."
                    exit 1
                fi
            done
            success "Verification passed!"
        fi
    fi

    success "Orchestration completed successfully."
}

ACTION=""
main
