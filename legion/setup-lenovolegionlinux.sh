#!/usr/bin/env bash
set -euo pipefail

# Metadata
VERSION="1.3.0"
DESCRIPTION="Setup script for Lenovo Legion Linux tools"
REPO_URL="https://github.com/johnfanv2/LenovoLegionLinux.git"
WORK_DIR="/home/shared/git/LenovoLegionLinux"
BIN_DIR="/home/shared/bin"
VENV_DIR="/home/shared/venv/legion"
LAUNCHER_DIR="/usr/share/applications"
LAUNCHER_GUI="$LAUNCHER_DIR/legion-linux-gui.desktop"
LAUNCHER_CLI="$LAUNCHER_DIR/legion-linux-cli.desktop"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Flags
DRY_RUN=false
FORCE=false
UNINSTALL=false
VERIFY=false

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

show_help() {
    echo "Usage: $(basename "$0") [OPTIONS]"
    echo ""
    echo "Description: $DESCRIPTION"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message and exit"
    echo "  -v, --version           Show the version information and exit"
    echo "  --uninstall             Uninstall the installed components"
    echo "  --dry-run               Show what would be done without making changes"
    echo "  --verify                Verify the current installation status"
    echo "  --force                 Skip confirmation prompts and overwrite existing files"
    echo ""
    echo "Executables are linked into: $BIN_DIR"
    echo "System-wide launchers (GUI and CLI) are created in: $LAUNCHER_DIR"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0")"
    echo "  $(basename "$0") --verify"
    echo "  $(basename "$0") --dry-run"
    echo "  $(basename "$0") --uninstall"
}

show_version() {
    echo "$DESCRIPTION version $VERSION"
}

ask_confirmation() {
    local prompt="$1"
    if [[ "$FORCE" == "true" ]]; then
        return 0
    fi
    local response
    read -r -p "$(echo -e "${YELLOW}[CONFIRM]${NC} $prompt (y/N): ")" response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

run_cmd() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] $*"
        return 0
    fi
    "$@"
}

install_dependencies() {
    log_header "Installing System and Python Dependencies"

    run_cmd sudo apt-get update
    run_cmd sudo apt-get install -y \
        make \
        gcc \
        "linux-headers-$(uname -r)" \
        build-essential \
        git \
        lm-sensors \
        wget \
        python3-pyqt6 \
        python3-yaml \
        python3-venv \
        python3-pip \
        python3-argcomplete \
        dkms \
        openssl \
        mokutil

    log_info "Installing darkdetect via pip..."
    run_cmd pip install --break-system-packages darkdetect
}

clone_or_update_repo() {
    log_header "Fetching LenovoLegionLinux Source"

    run_cmd mkdir -p "$(dirname "$WORK_DIR")"

    if [[ -d "$WORK_DIR/.git" ]]; then
        if [[ "$FORCE" == "true" ]]; then
            log_info "Resetting and pulling latest changes in $WORK_DIR..."
            run_cmd git -C "$WORK_DIR" fetch origin
            run_cmd git -C "$WORK_DIR" reset --hard origin/HEAD
        else
            log_info "Pulling latest changes in $WORK_DIR..."
            run_cmd git -C "$WORK_DIR" pull --ff-only
        fi
    else
        if [[ -e "$WORK_DIR" ]]; then
            if ask_confirmation "$WORK_DIR already exists and is not a git repo. Replace it?"; then
                run_cmd rm -rf "$WORK_DIR"
            else
                log_error "Aborting because $WORK_DIR already exists."
                exit 1
            fi
        fi
        run_cmd git clone "$REPO_URL" "$WORK_DIR"
    fi
}

build_and_install_module() {
    log_header "Building and Loading Kernel Module"

    local mod_dir="$WORK_DIR/kernel_module"
    if [[ ! -d "$mod_dir" && "$DRY_RUN" == "false" ]]; then
        log_error "Kernel module directory not found at $mod_dir"
        exit 1
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] make -C \"$mod_dir\" clean && make -C \"$mod_dir\""
        log_info "[DRY-RUN] sudo make -C \"$mod_dir\" install"
        log_info "[DRY-RUN] sudo modprobe legion-laptop || sudo make -C \"$mod_dir\" reloadmodule"
        return 0
    fi

    make -C "$mod_dir" clean
    make -C "$mod_dir"
    sudo make -C "$mod_dir" install
    sudo modprobe legion-laptop || sudo make -C "$mod_dir" reloadmodule || true

    if lsmod | grep -Eq "^legion_laptop\b"; then
        log_success "Kernel module built and loaded."
    else
        log_warn "Kernel module built and installed, but NOT loaded. Recent kernel messages:"
        sudo dmesg | grep -i legion | tail -n 10 || true
        log_warn "Secure Boot: $(mokutil --sb-state 2>&1 || echo unknown)"
    fi
}

write_launcher() {
    local file="$1" name="$2" comment="$3" exec_line="$4" icon="$5" terminal="$6"

    local content
    content="[Desktop Entry]
Type=Application
Version=1.0
Name=$name
Comment=$comment
Exec=$exec_line
Icon=$icon
Terminal=$terminal
Categories=System;Settings;HardwareSettings;
Keywords=Lenovo;Legion;Fan;Power;Battery;Performance;
StartupNotify=true
"

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Write launcher $file"
        return 0
    fi

    printf '%s' "$content" | sudo tee "$file" >/dev/null
    sudo chmod 644 "$file"
    log_success "Created launcher $file"
}

create_launchers() {
    log_header "Creating Application Launchers"

    # Make sure every user can read/execute the shared install
    run_cmd sudo chmod a+rx "$BIN_DIR"
    run_cmd sudo chmod -R a+rX "$VENV_DIR"

    write_launcher "$LAUNCHER_GUI" \
        "Legion Linux (GUI)" \
        "Lenovo Legion laptop control (graphical)" \
        "sudo $BIN_DIR/legion_gui" \
        "preferences-system" \
        "false"

    if command -v update-desktop-database >/dev/null 2>&1; then
        run_cmd sudo update-desktop-database "$LAUNCHER_DIR"
    fi
}

install_executables() {
    log_header "Linking Executables into $BIN_DIR"

    run_cmd mkdir -p "$BIN_DIR"

    local exe
    for exe in legion_cli legion_gui; do
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY-RUN] ln -sf $VENV_DIR/bin/$exe $BIN_DIR/$exe"
        elif [[ -x "$VENV_DIR/bin/$exe" ]]; then
            ln -sf "$VENV_DIR/bin/$exe" "$BIN_DIR/$exe"
            log_success "Linked $BIN_DIR/$exe"
        else
            log_warn "$exe not found in $VENV_DIR/bin"
        fi
    done

    case ":$PATH:" in
        *":$BIN_DIR:"*) ;;
        *) log_warn "$BIN_DIR is not in your PATH. Add: export PATH=\"$BIN_DIR:\$PATH\"" ;;
    esac

    create_launchers
}

build_and_install_python_tools() {
    log_header "Building and Installing Python CLI/GUI Tools"

    local pkg_dir=""
    local d
    for d in "$WORK_DIR/python/legion_linux" "$WORK_DIR/python"; do
        if [[ -f "$d/setup.py" || -f "$d/pyproject.toml" ]]; then
            pkg_dir="$d"
            break
        fi
    done

    if [[ -z "$pkg_dir" && "$DRY_RUN" == "false" ]]; then
        log_warn "No installable Python package found; skipping CLI/GUI build."
        return 0
    fi
    pkg_dir="${pkg_dir:-$WORK_DIR/python/legion_linux}"

    log_info "Creating venv at $VENV_DIR (with system site-packages for PyQt6)..."
    run_cmd mkdir -p "$(dirname "$VENV_DIR")"
    run_cmd python3 -m venv --system-site-packages "$VENV_DIR"
    run_cmd "$VENV_DIR/bin/pip" install --upgrade "$pkg_dir"

    install_executables
}

verify_installation() {
    log_header "Verifying Installation"

    local failures=0

    if python3 -c "import darkdetect" 2>/dev/null; then
        log_success "Python module 'darkdetect' is importable."
    else
        log_error "Python module 'darkdetect' is NOT importable."
        failures=$((failures + 1))
    fi

    if lsmod | grep -Eq "^legion_laptop\b"; then
        log_success "Kernel module 'legion_laptop' is loaded."
    else
        log_warn "Kernel module 'legion_laptop' is not currently loaded."
        failures=$((failures + 1))
    fi

    if [[ -x "$BIN_DIR/legion_cli" || -x "$BIN_DIR/legion_gui" ]]; then
        log_success "Found executables in $BIN_DIR"
    else
        log_warn "No legion_cli/legion_gui found in $BIN_DIR."
    fi

    if [[ -f "$LAUNCHER_GUI" && -f "$LAUNCHER_CLI" ]]; then
        log_success "Found GUI and CLI launchers in $LAUNCHER_DIR"
    else
        log_warn "GUI and/or CLI launcher missing in $LAUNCHER_DIR."
    fi

    if [[ "$failures" -gt 0 ]]; then
        return 1
    fi
}

uninstall_components() {
    log_header "Uninstalling LenovoLegionLinux"

    if ! ask_confirmation "Remove the legion_laptop kernel module, Python tools, executables in $BIN_DIR, and launchers?"; then
        log_info "Uninstall cancelled."
        exit 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] sudo modprobe -r legion_laptop || true"
        log_info "[DRY-RUN] Run uninstall targets if present in $WORK_DIR"
        log_info "[DRY-RUN] rm -f $BIN_DIR/legion_cli $BIN_DIR/legion_gui"
        log_info "[DRY-RUN] rm -rf $VENV_DIR"
        log_info "[DRY-RUN] sudo rm -f $LAUNCHER_GUI $LAUNCHER_CLI"
        return 0
    fi

    sudo modprobe -r legion_laptop || true

    if [[ -d "$WORK_DIR/python" && -f "$WORK_DIR/python/Makefile" ]] && make -n -C "$WORK_DIR/python" uninstall >/dev/null 2>&1; then
        sudo make -C "$WORK_DIR/python" uninstall
    fi

    if [[ -d "$WORK_DIR/kernel_module" && -f "$WORK_DIR/kernel_module/Makefile" ]] && make -n -C "$WORK_DIR/kernel_module" uninstall >/dev/null 2>&1; then
        sudo make -C "$WORK_DIR/kernel_module" uninstall
    fi

    rm -f "$BIN_DIR/legion_cli" "$BIN_DIR/legion_gui"
    rm -rf "$VENV_DIR"
    sudo rm -f "$LAUNCHER_GUI" "$LAUNCHER_CLI"
    if command -v update-desktop-database >/dev/null 2>&1; then
        sudo update-desktop-database "$LAUNCHER_DIR" || true
    fi

    log_success "Uninstall steps completed."
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            --uninstall)
                UNINSTALL=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verify)
                VERIFY=true
                shift
                ;;
            --force)
                FORCE=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    if [[ "$UNINSTALL" == "true" ]]; then
        uninstall_components
    elif [[ "$VERIFY" == "true" ]]; then
        verify_installation
    else
        log_header "Starting Installation"
        install_dependencies
        clone_or_update_repo
        build_and_install_module
        build_and_install_python_tools
        verify_installation || true
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
