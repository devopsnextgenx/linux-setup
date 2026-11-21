#!/bin/bash
# setup-shared.sh (Orchestrator)

set -euo pipefail

# Load modules
BASE_DIR="$(dirname "$(readlink -f "$0")")"
# Note: The modules are in modules/shared-setup/ or modules/
# But we are running from the root of the repo probably, or from the scripts directory.
# The original script was in scripts/setup-shared.sh.
# So the modules should be in modules/shared-setup/ etc.
# Let's assume we are in the root of the repo for the sake of this refactor, 
# or use a more robust way to find them.

# Based on the file path: /home/kira/git/devopsnextgenx/linux-setup/legion/scripts/setup-shared.sh
# The modules directory is likely at /home/kira/git/devopsnextgenx/linux-setup/legion/scripts/modules/
# Let's find the root directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"

# Source utilities and config
source "$MODULES_DIR/utils.sh"
source "$MODULES_DIR/config.sh"

# --- Global Flags ---
DRY_RUN=false
UNINSTALL=false
VERIFY=false
FORCE=false

# --- Argument Parsing ---
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -u, --uninstall      Revert changes made by the script
  -d, --dry-run        Show what would be done without making changes
  -v, --verify         Check if the system is in the expected state
  -f, --force          Override existing files/settings (requires confirmation)
  -h, --help           Show this help message

EOF
    exit 0
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -u|--uninstall) UNINSTALL=true ;;
        -d|--dry-run) DRY_RUN=true ;;
        -v|--verify) VERIFY=true ;;
        -f|--force) FORCE=true ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
    shift
done

# --- Orchestration Helpers ---

# Function to run a module's setup function
run_setup() {
    local module_path="$1"
    local func_name="$2"
    local module_name="$3"

    if [ "$DRY_RUN" = true ]; then
        info "[DRY-RUN] Would execute $func_name from $module_name"
        return 0
    fi

    info "Running $module_name..."
    # shellcheck disable=SC1090
    source "$module_path" "$func_name"
}

# Function to run a module's uninstall function
run_uninstall() {
    local module_path="$1"
    local func_name="$2"
    local module_name="$3"

    if [ "$DRY_RUN" = true ]; then
        info "[DRY-RUN] Would execute $func_name from $module_name (uninstall)"
        return 0
    fi

    if [ "$FORCE" = true ]; then
        read -p "Are you sure you want to UNINSTALL everything? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Uninstall aborted."
            exit 0
        fi
    fi

    info "Uninstalling $module_name..."
    # shellcheck disable=SC1090
    source "$module_path" "$func_name"
}

# --- Pre-flight Checks ---

check_prerequisites() {
    check_root
    
    if [ -f /etc/flatpak/installations.d/shared.conf ]; then
        error "Legacy shared Flatpak installation found (/etc/flatpak/installations.d/shared.conf)."
        error "Run ./reset-flatpak.sh first, then re-run this script."
        exit 1
    fi

    if [ "$DRY_RUN" = true ]; then
        success "[DRY-RUN] Prerequisites check passed."
        return 0
    fi
}

# --- Main Execution Flow ---

main() {
    check_prerequisites

    if [ "$UNINSTALL" = true ]; then
        # Uninstall in reverse order
        run_uninstall "$MODULES_DIR/shared-setup/07-bashrc.sh" "uninstall_bashrc" "bashrc"
        run_uninstall "$MODULES_DIR/shared-setup/06-environment.sh" "uninstall_environment" "environment"
        run_uninstall "$MODULES_DIR/shared-setup/05-podman.sh" "uninstall_podman" "podman"
        run_uninstall "$MODULES_DIR/shared-setup/04-tools.sh" "uninstall_tools" "tools"
        run_uninstall "$MODULES_DIR/shared-setup/03-packages.sh" "uninstall_packages" "packages"
        run_uninstall "$MODULES_DIR/shared-setup/02-directories.sh" "uninstall_directories" "directories"
        run_uninstall "$MODULES_DIR/shared-setup/01-users.sh" "uninstall_users" "users"
        success "Uninstallation complete."
        exit 0
    fi

    # Setup sequence
    run_setup "$MODULES_DIR/shared-setup/01-users.sh" "setup_users" "User Setup"
    run_setup "$MODULES_DIR/shared-setup/02-directories.sh" "setup_directories" "Directory Setup"
    run_setup "$MODULES_DIR/shared-setup/03-packages.sh" "setup_packages" "Package Installation"
    run_setup "$MODULES_DIR/shared-setup/04-tools.sh" "setup_tools" "Tools Configuration"
    run_setup "$MODULES_DIR/shared-setup/05-podman.sh" "setup_podman" "Podman Configuration"
    run_setup "$MODULES_DIR/shared-setup/06-environment.sh" "setup_environment" "Environment Configuration"
    run_setup "$MODULES_DIR/shared-setup/07-bashrc.sh" "setup_bashrc" "Bashrc Configuration"

    if [ "$VERIFY" = true ]; then
        info "Verification not fully implemented in this orchestrator, but all steps completed."
    fi

    success "Setup completed successfully!"
}

main
