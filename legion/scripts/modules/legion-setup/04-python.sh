#!/bin/bash
set -euo pipefail

MODULE_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
[[ -f "$MODULE_DIR/../config.sh" ]] && source "$MODULE_DIR/../config.sh"
[[ -f "$MODULE_DIR/../utils.sh" ]] && source "$MODULE_DIR/../utils.sh"

setup_domain() {
    info "Building and Installing Python CLI/GUI Tools"

    local pkg_dir=""
    local d
    for d in "$LEGION_WORK_DIR/python/legion_linux" "$LEGION_WORK_DIR/python"; do
        if [[ -f "$d/setup.py" || -f "$d/pyproject.toml" ]]; then
            pkg_dir="$d"
            break
        fi
    done

    if [[ -z "$pkg_dir" ]]; then
        warn "No installable Python package found; skipping CLI/GUI build."
        return 0
    fi

    local dry_run=${DRY_RUN:-false}

    if [[ "$dry_run" == "true" ]]; then
        info "[DRY-RUN] python3 -m venv --system-site-packages $LEGION_VENV_DIR"
        info "[DRY-RUN] $LEGION_VENV_DIR/bin/pip install $pkg_dir"
        return 0
    fi

    info "Creating venv at $LEGION_VENV_DIR (with system site-packages for PyQt6)..."
    ensure_dirs "" "$(dirname "$LEGION_VENV_DIR")"
    as_needed python3 -m venv --system-site-packages "$LEGION_VENV_DIR"
    as_needed "$LEGION_VENV_DIR/bin/pip" install --upgrade "$pkg_dir"
}

uninstall_domain() {
    info "Removing Python Virtual Environment"
    local dry_run=${DRY_RUN:-false}
    if [[ "$dry_run" == "true" ]]; then
        info "[DRY-RUN] rm -rf $LEGION_VENV_DIR"
    else
        rm -rf "$LEGION_VENV_DIR"
    fi
}
