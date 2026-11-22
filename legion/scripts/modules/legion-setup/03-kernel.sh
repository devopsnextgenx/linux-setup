#!/bin/bash
set -euo pipefail

MODULE_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
[[ -f "$MODULE_DIR/../config.sh" ]] && source "$MODULE_DIR/../config.sh"
[[ -f "$MODULE_DIR/../utils.sh" ]] && source "$MODULE_DIR/../utils.sh"

setup_domain() {
    info "Building and Loading Kernel Module"

    local mod_dir="$LEGION_WORK_DIR/kernel_module"
    local dry_run=${DRY_RUN:-false}

    if [[ ! -d "$mod_dir" ]]; then
        error "Kernel module directory not found at $mod_dir"
        exit 1
    fi

    if [[ "$dry_run" == "true" ]]; then
        info "[DRY-RUN] make -C \"$mod_dir\" clean && make -C \"$mod_dir\""
        info "[DRY-RUN] sudo make -C \"$mod_dir\" install"
        info "[DRY-RUN] sudo modprobe legion-laptop"
        return 0
    fi

    as_needed make -C "$mod_dir" clean
    as_needed make -C "$mod_dir"
    as_needed make -C "$mod_dir" install
    as_needed modprobe legion-laptop || as_needed make -C "$mod_dir" reloadmodule || true

    if lsmod | grep -Eq "^legion_laptop\b"; then
        success "Kernel module built and loaded."
    else
        warn "Kernel module built and installed, but NOT loaded."
        sudo dmesg | grep -i legion | tail -n 10 || true
        warn "Secure Boot: $(mokutil --sb-state 2>&1 || echo unknown)"
    fi
}

uninstall_domain() {
    info "Uninstalling Kernel Module"
    local dry_run=${DRY_RUN:-false}

    if [[ "$dry_run" == "true" ]]; then
        info "[DRY-RUN] sudo modprobe -r legion_laptop"
        info "[DRY-RUN] make -C \"$LEGION_WORK_DIR/kernel_module\" uninstall"
        return 0
    fi

    as_needed modprobe -r legion_laptop || true
    if [[ -d "$LEGION_WORK_DIR/kernel_module" ]]; then
        as_needed make -C "$LEGION_WORK_DIR/kernel_module" uninstall || true
    fi
}
