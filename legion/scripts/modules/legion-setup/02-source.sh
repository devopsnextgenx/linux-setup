#!/bin/bash
set -euo pipefail

MODULE_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
[[ -f "$MODULE_DIR/../config.sh" ]] && source "$MODULE_DIR/../config.sh"
[[ -f "$MODULE_DIR/../utils.sh" ]] && source "$MODULE_DIR/../utils.sh"

setup_domain() {
    info "Fetching LenovoLegionLinux Source"
    
    local dry_run=${DRY_RUN:-false}
    local force=${FORCE:-false}

    if [[ "$dry_run" == "true" ]]; then
        info "[DRY-RUN] git clone $LEGION_REPO_URL $LEGION_WORK_DIR (or update)"
        return 0
    fi

    ensure_dirs "/" "$(dirname "$LEGION_WORK_DIR")"

    if [[ -d "$LEGION_WORK_DIR/.git" ]]; then
        if [[ "$force" == "true" ]]; then
            info "Resetting and pulling latest changes in $LEGION_WORK_DIR..."
            as_needed git -C "$LEGION_WORK_DIR" fetch origin
            as_needed git -C "$LEGION_WORK_DIR" reset --hard origin/HEAD
        else
            info "Pulling latest changes in $LEGION_WORK_DIR..."
            as_needed git -C "$LEGION_WORK_DIR" pull --ff-only
        fi
    else
        if [[ -e "$LEGION_WORK_DIR" ]]; then
            if [[ "$force" == "true" ]]; then
                info "Removing existing directory $LEGION_WORK_DIR"
                rm -rf "$LEGION_WORK_DIR"
            else
                error "$LEGION_WORK_DIR already exists and is not a git repo. Use --force to replace."
                exit 1
            fi
        fi
        as_needed git clone "$LEGION_REPO_URL" "$LEGION_WORK_DIR"
    fi
}

uninstall_domain() {
    info "Removing source directory $LEGION_WORK_DIR"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        info "[DRY-RUN] rm -rf $LEGION_WORK_DIR"
    else
        rm -rf "$LEGION_WORK_DIR"
    fi
}
