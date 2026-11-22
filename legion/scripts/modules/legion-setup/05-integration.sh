#!/bin/bash
set -euo pipefail

MODULE_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
[[ -f "$MODULE_DIR/../config.sh" ]] && source "$MODULE_DIR/../config.sh"
[[ -f "$MODULE_DIR/../utils.sh" ]] && source "$MODULE_DIR/../utils.sh"

setup_domain() {
    info "Linking Executables and Creating Launchers"

    local dry_run=${DRY_RUN:-false}

    if [[ "$dry_run" == "true" ]]; then
        info "[DRY-RUN] sudo chmod a+rx $LEGION_BIN_DIR"
        info "[DRY-RUN] sudo chmod -R a+rX $LEGION_VENV_DIR"
        info "[DRY-RUN] Creating launcher $LEGION_LAUNCHER_GUI"
        return 0
    fi

    as_needed chmod a+rx "$LEGION_BIN_DIR" || true
    as_needed chmod -R a+rX "$LEGION_VENV_DIR" || true

    # Create launcher wrapper
    create_gui_wrapper

    # Create .desktop launcher
    write_launcher "$LEGION_LAUNCHER_GUI" \
        "Legion Linux (GUI)" \
        "Lenovo Legion laptop control (graphical)" \
        "$LEGION_BIN_DIR/legion_gui_launcher" \
        "preferences-system" \
        "false"

    if command -v update-desktop-database >/dev/null 2>&1; then
        as_needed update-desktop-database "$LEGION_LAUNCHER_DIR"
    fi

    # Link executables
    install_executables
}

# Helper functions that were in the monolith
write_launcher() {
    local file="$1" name="$2" comment="$3" exec_line="$4" icon="$5" terminal="$6"
    local content="[Desktop Entry]
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
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        info "[DRY-RUN] Write launcher $file"
        return 0
    fi
    printf '%s' "$content" | as_needed tee "$file" >/dev/null
    as_needed chmod 644 "$file"
    success "Created launcher $file"
}

create_gui_wrapper() {
    local wrapper="$LEGION_BIN_DIR/legion_gui_launcher"
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        info "[DRY-RUN] Write root wrapper $wrapper"
        return 0
    fi

    cat > "$wrapper" <<'WRAPPER_EOF'
#!/usr/bin/env bash
set -euo pipefail
gui="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/legion_gui"
env_args=()
for v in DISPLAY XAUTHORITY WAYLAND_DISPLAY XDG_RUNTIME_DIR XDG_CURRENT_DESKTOP DBUS_SESSION_BUS_ADDRESS; do
    if [[ -n "${!v:-}" ]]; then
        env_args+=("$v=${!v}")
    fi
done
if [[ "$(id -u)" -eq 0 ]]; then
    exec "$gui" "$@"
fi
if sudo -n true 2>/dev/null; then
    exec sudo -n env "${env_args[@]}" "$gui" "$@"
fi
exec pkexec env "${env_args[@]}" "$gui" "$@"
WRAPPER_EOF
    chmod 755 "$wrapper"
    success "Created $wrapper"
}

install_executables() {
    info "Linking Executables into $LEGION_BIN_DIR"
    ensure_dirs "" "$LEGION_BIN_DIR"
    
    local exe
    for exe in legion_cli legion_gui; do
        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            info "[DRY-RUN] ln -sf $LEGION_VENV_DIR/bin/$exe $LEGION_BIN_DIR/$exe"
        elif [[ -x "$LEGION_VENV_DIR/bin/$exe" ]]; then
            ln -sf "$LEGION_VENV_DIR/bin/$exe" "$LEGION_BIN_DIR/$exe"
            success "Linked $LEGION_BIN_DIR/$exe"
        else
            warn "$exe not found in $LEGION_VENV_DIR/bin"
        fi
    done

    case ":$PATH:" in
        *":$LEGION_BIN_DIR:"*) ;;
        *) warn "$LEGION_BIN_DIR is not in your PATH. Add: export PATH=\"$LEGION_BIN_DIR:\$PATH\"" ;;
    esac
}

uninstall_domain() {
    info "Uninstalling Integration Components"
    local dry_run=${DRY_RUN:-false}

    if [[ "$dry_run" == "true" ]]; then
        info "[DRY-RUN] rm -f $LEGION_BIN_DIR/legion_cli $LEGION_BIN_DIR/legion_gui $LEGION_BIN_DIR/legion_gui_launcher"
        info "[DRY-RUN] sudo rm -f $LEGION_LAUNCHER_GUI"
        return 0
    fi

    rm -f "$LEGION_BIN_DIR/legion_cli" "$LEGION_BIN_DIR/legion_gui" "$LEGION_BIN_DIR/legion_gui_launcher"
    sudo rm -f "$LEGION_LAUNCHER_GUI"
    if command -v update-desktop-database >/dev/null 2>&1; then
        as_needed update-desktop-database "$LEGION_LAUNCHER_DIR" || true
    fi
}
