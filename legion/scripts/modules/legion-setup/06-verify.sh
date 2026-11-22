#!/bin/bash
set -euo pipefail

MODULE_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
[[ -f "$MODULE_DIR/../config.sh" ]] && source "$MODULE_DIR/../config.sh"
[[ -f "$MODULE_DIR/../utils.sh" ]] && source "$MODULE_DIR/../utils.sh"

verify_installation() {
    info "Verifying Installation"
    local failures=0

    if python3 -c "import darkdetect" 2>/dev/null; then
        success "Python module 'darkdetect' is importable."
    else
        error "Python module 'darkdetect' is NOT importable."
        failures=$((failures + 1))
    fi

    if lsmod | grep -Eq "^legion_laptop\b"; then
        success "Kernel module 'legion_laptop' is loaded."
    else
        warn "Kernel module 'legion_laptop' is not currently loaded."
        failures=$((failures + 1))
    fi

    if [[ -x "$LEGION_BIN_DIR/legion_cli" || -x "$LEGION_BIN_DIR/legion_gui" ]]; then
        success "Found executables in $LEGION_BIN_DIR"
    else
        warn "No legion_cli/legion_gui found in $LEGION_BIN_DIR."
        failures=$((failures + 1))
    fi

    if [[ -f "$LEGION_LAUNCHER_GUI" && -x "$LEGION_BIN_DIR/legion_gui_launcher" ]]; then
        success "Found GUI launcher and root wrapper"
    else
        warn "GUI launcher or $LEGION_BIN_DIR/legion_gui_launcher is missing."
        failures=$((failures + 1))
    fi

    if [[ "$failures" -gt 0 ]]; then
        error "Verification failed with $failures errors."
        return 1
    else
        success "Verification passed!"
        return 0
    fi
}

# If run directly (though not intended to be run alone in this framework)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    verify_installation
fi
