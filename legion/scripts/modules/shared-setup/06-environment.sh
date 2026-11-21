#!/bin/bash
# modules/shared-setup/06-environment.sh

setup_environment() {
    info "Step 10: Writing env.shared profile..."
    cat << EOF > "$ENV_SHARED_PATH"
# Shared Environment Configuration for Common Tools
export SHARED_HOME="/home/shared"
export COMMON_TOOLS="/home/shared/common"

# NVM & Node.js
export NVM_DIR="\$COMMON_TOOLS/nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"

# Python venv
export PYTHON_VENV="\$COMMON_TOOLS/python_env"
if [ -d "\$PYTHON_VENV" ]; then
    source "\$PYTHON_VENV/bin/activate"
fi

# Rust & Cargo
export RUSTUP_HOME="\$COMMON_TOOLS/rustup"
export CARGO_HOME="\$COMMON_TOOLS/cargo"
export PATH="\$CARGO_HOME/bin:\$PATH"

# Go
export GOROOT="\$COMMON_TOOLS/go"
export GOPATH="\$COMMON_TOOLS/gopath"
export PATH="\$GOROOT/bin:\$GOPATH/bin:\$PATH"

# Ollama Models Storage
export OLLAMA_MODELS="\$COMMON_TOOLS/ollama"

# Podman / kind
export STORAGE_DRIVER="overlay"
export KIND_EXPERIMENTAL_PROVIDER="podman"
EOF

    chown root:"$SHARED_GROUP" "$ENV_SHARED_PATH"
    chmod 664 "$ENV_SHARED_PATH"

    info "Step 11: Finalizing permissions on $COMMON_DIR..."
    chown root:"$SHARED_GROUP" "$COMMON_DIR"
    find "$COMMON_DIR" -mindepth 1 -path "$PODMAN_DIR" -prune -o \
        -exec chown --no-dereference root:"$SHARED_GROUP" {} +
    find "$COMMON_DIR" -mindepth 1 -path "$PODMAN_DIR" -prune -o -type d -exec chmod 2770 {} +
    find "$COMMON_DIR" -mindepth 1 -path "$PODMAN_DIR" -prune -o -type f -exec chmod g+rw {} +
    chmod 2771 "$COMMON_DIR"
}

uninstall_environment() {
    warn "Removing shared environment files..."
    rm -f "$ENV_SHARED_PATH"
}
