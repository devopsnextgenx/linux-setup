#!/bin/bash
# modules/shared-setup/04-tools.sh

setup_tools() {
    info "Step 7: Installing tools to common locations..."

    # --- NVM & Node.js ---
    info "    -> NVM / Node.js..."
    export NVM_DIR="$COMMON_DIR/nvm"
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        info "    - Downloading NVM..."
        curl -fsSo- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | PROFILE=/dev/null bash
    fi
    
    # nvm.sh is not nounset-safe, so we use a subshell or disable unset for a bit
    set +u
    # shellcheck disable=SC1091
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    set -u

    nvm install --lts > /dev/null 2>&1
    nvm alias default 'lts/*' > /dev/null 2>&1

    # --- Python Virtual Environment ---
    info "    -> Python virtual environment..."
    if [ ! -x "$COMMON_DIR/python_env/bin/python" ]; then
        python3 -m venv "$COMMON_DIR/python_env"
    fi

    # --- Rust & Cargo ---
    info "    -> Rust and Cargo..."
    export RUSTUP_HOME="$COMMON_DIR/rustup"
    export CARGO_HOME="$COMMON_DIR/cargo"
    if [ ! -x "$CARGO_HOME/bin/rustc" ]; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --default-toolchain stable
    fi

    # --- Go ---
    info "    -> Go ${GO_VERSION}..."
    local arch=$(get_arch)
    if [ ! -x "$COMMON_DIR/go/bin/go" ] || ! "$COMMON_DIR/go/bin/go" version | grep -q "go${GO_VERSION} "; then
        curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${arch}.tar.gz" -o /tmp/go.tar.gz
        rm -rf "$COMMON_DIR/go"
        tar -C "$COMMON_DIR" -xzf /tmp/go.tar.gz
        rm -f /tmp/go.tar.gz
    fi
}

uninstall_tools() {
    warn "Removing installed tools..."
    # Deleting the common directories is the cleanest way
    rm -rf "$COMMON_DIR/nvm"
    rm -rf "$COMMON_DIR/rustup"
    rm -rf "$COMMON_DIR/cargo"
    rm -rf "$COMMON_DIR/go"
    rm -rf "$COMMON_DIR/python_env"
}
