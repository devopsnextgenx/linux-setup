#!/bin/bash
set -euo pipefail

# Source configuration and utilities
MODULE_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
# If called from orchestrator in scripts/, MODULE_DIR is modules/
# If called from orchestrator in scripts/modules/legion-setup/, MODULE_DIR is legion-setup/
# We want to go up to the scripts/ directory.
# Let's assume modules/ is a sibling of legion-setup/
[[ -f "$MODULE_DIR/../config.sh" ]] && source "$MODULE_DIR/../config.sh"
[[ -f "$MODULE_DIR/../utils.sh" ]] && source "$MODULE_DIR/../utils.sh"

setup_domain() {
    info "Installing System and Python Dependencies"
    
    # Check if we are in dry-run mode (passed by orchestrator or via env)
    local dry_run=${DRY_RUN:-false}

    if [[ "$dry_run" == "true" ]]; then
        info "[DRY-RUN] sudo apt-get update"
        info "[DRY-RUN] sudo apt-get install -y make gcc linux-headers-$(uname -r) build-essential git lm-sensors wget python3-pyqt6 python3-yaml python3-venv python3-pip python3-argcomplete dkms openssl mokutil"
        info "[DRY-RUN] pip install --break-system-packages darkdetect"
        return 0
    fi

    as_needed sudo apt-get update
    as_needed apt-get install -y \
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

    info "Installing darkdetect via pip..."
    as_needed pip install --break-system-packages darkdetect
}

uninstall_domain() {
    info "Uninstalling Dependencies (Note: apt packages are not automatically removed)"
    # Usually we don't want to uninstall system packages automatically unless specifically requested, 
    # but for completeness we could. For now, we skip.
}
