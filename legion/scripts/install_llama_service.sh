#!/usr/bin/env bash

# Set up colors
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m' # No Color

# Script Metadata
VERSION="1.0.1"
SERVICE_NAME="llama-gemma.service"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}"

# Default values
MODEL_PATH="/home/shared/common/llama.cpp/models/models--ggml-org--gemma-4-26B-A4B-it-GGUF/snapshots/1ca99aae748b4b01f609fa51eb23682ee5f00b85/gemma-4-26B-A4B-it-Q4_0.gguf"
SERVER_PATH="/home/shared/bin/build-rocm/bin/llama-server"
PORT=9874
CONTEXT_SIZE=262144 # 256k
SLEEP_IDLE=1800
CACHE_RAM=8192
EXTRA_ARGS="--temp 1.0 --top-p 0.95 --top-k 64 --repeat-penalty 1.0"
DRY_RUN=false
FORCE=false
UNINSTALL=false
VERIFY=false

# --- Utility Functions ---

log_info() { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
log_success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"; }
log_warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$1" >&2; }

print_usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -m, --model-path PATH    Path to the gemma4-26b model file (Required)
  -s, --server-path PATH   Path to the llama-server executable (Required)
  -c, --context SIZE       Context size (default: 262144)
  --sleep SECONDS          Sleep idle seconds (default: 1800)
  --cache RAM              Cache RAM in MiB (default: 8192)
  --uninstall              Remove the systemd service
  --dry-run                Show what would be done without making changes
  --verify                Verify if the service is running correctly
  --force                 Overwrite existing service files without asking
  -h, --help              Show this help message
  -v, --version           Show version information

EOF
}

show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    echo -n "  "
    while true; do
        if ! kill -0 "$pid" 2>/dev/null; then
            break
        fi
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp"${spinstr%"$temp"}"
        sleep $delay
        printf "\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# --- Core Logic Functions ---

check_privileges() {
    if [[ $EUID -ne 0 ]] && [[ "$UNINSTALL" != "true" ]] && [[ "$DRY_RUN" != "true" ]]; then
        log_error "This script must be run as root (use sudo)."
        exit 1
    fi
}

validate_args() {
    if [[ "$UNINSTALL" == "false" ]] && [[ "$VERIFY" == "false" ]] && [[ "$DRY_RUN" == "false" ]]; then
        if [[ -z "$MODEL_PATH" ]] || [[ -z "$SERVER_PATH" ]]; then
            log_error "Model path and Server path are required for installation."
            print_usage
            exit 1
        fi
    fi
}

get_service_content() {
    cat <<EOF
[Unit]
Description=Llama Server - Gemma 4 26B
After=network.target

[Service]
Type=simple
ExecStart=${SERVER_PATH} --model ${MODEL_PATH} --ctx-size ${CONTEXT_SIZE} --port ${PORT} --host 0.0.0.0 --sleep-idle-seconds ${SLEEP_IDLE} --cache-ram ${CACHE_RAM} ${EXTRA_ARGS} --n-gpu-layers 99 --flash-attn on --cache-type-k q8_0 --cache-type-v q8_0
Restart=always
RestartSec=5
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=llama-gemma

[Install]
WantedBy=multi-user.target
EOF
}

install_service() {
    log_info "Preparing to install ${SERVICE_NAME}..."

    if [[ -f "$SERVICE_FILE" ]] && [[ "$FORCE" != "true" ]]; then
        read -p "Service file already exists. Overwrite? (y/N) " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_warn "Installation aborted by user."
            return
        fi
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would create $SERVICE_FILE with content:"
        get_service_content
        return
    fi

    log_info "Creating service file at $SERVICE_FILE..."
    (
        sleep 1 &
        PID=$!
        show_spinner $PID
    )

    if ! echo "$(get_service_content)" | sudo tee "$SERVICE_FILE" > /dev/null; then
        log_error "Failed to write service file."
        return 1
    fi

    log_info "Reloading systemd and enabling service..."
    sudo systemctl daemon-reload > /dev/null
    sudo systemctl enable "${SERVICE_NAME}" > /dev/null
    sudo systemctl start "${SERVICE_NAME}" > /dev/null

    log_success "Service installed and started successfully!"
    log_info "You can check status with: systemctl status ${SERVICE_NAME}"
}

uninstall_service() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY-RUN] Would remove ${SERVICE_NAME} and reload systemd."
        return
    fi

    if [[ -f "$SERVICE_FILE" ]]; then
        log_info "Stopping and removing ${SERVICE_NAME}..."
        sudo systemctl stop "${SERVICE_NAME}" > /dev/null 2>&1
        sudo systemctl disable "${SERVICE_NAME}" > /dev/null 2>&1
        sudo rm "$SERVICE_FILE"
        sudo systemctl daemon-reload
        log_success "Service uninstalled."
    else
        log_warn "Service file not found. Nothing to do."
    fi
}

verify_service() {
    log_info "Verifying ${SERVICE_NAME} status..."
    if systemctl is-active --quiet "${SERVICE_NAME}"; then
        log_success "Service is running."
        echo "------------------------------------------------"
        sudo systemctl status "${SERVICE_NAME}" --no-pager | tail -n 10
        echo "------------------------------------------------"
    else
        log_error "Service is NOT running."
        sudo systemctl status "${SERVICE_NAME}" --no-pager | tail -n 10
        exit 1
    fi
}

# --- Main Entry Point ---

main() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--model-path) MODEL_PATH="$2"; shift 2 ;;
            -s|--server-path) SERVER_PATH="$2"; shift 2 ;;
            -c|--context) CONTEXT_SIZE="$2"; shift 2 ;;
            --sleep) SLEEP_IDLE="$2"; shift 2 ;;
            --cache) CACHE_RAM="$2"; shift 2 ;;
            --uninstall) UNINSTALL=true ;;
            --dry-run) DRY_RUN=true ;;
            --verify) VERIFY=true ;;
            --force) FORCE=true ;;
            -h|--help) print_usage; exit 0 ;;
            -v|--version) echo "Llama Service Installer v${VERSION}"; exit 0 ;;
            *) log_error "Unknown option: $1"; print_usage; exit 1 ;;
        esac
    done

    check_privileges
    validate_args

    if [[ "$UNINSTALL" == "true" ]]; then
        uninstall_service
    elif [[ "$VERIFY" == "true" ]]; then
        verify_service
    else
        install_service
    fi
}

main "$@"
