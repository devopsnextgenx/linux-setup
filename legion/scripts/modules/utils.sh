#!/bin/bash
set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Logging ---
log() { echo -e "${GREEN}[+] $*${NC}"; }
warn() { echo -e "${YELLOW}    ! $*${NC}" >&2; }
error() { echo -e "${RED}[!] Error: $*${NC}" >&2; }
info() { echo -e "${BLUE}[*] $*${NC}"; }
success() { echo -e "${GREEN}[✔] $*${NC}"; }

# --- System Helpers ---
user_exists() { id "$1" &>/dev/null; }
user_home()   { getent passwd "$1" | cut -d: -f6; }


# Root check
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "This script must be run as root (sudo)."
        exit 1
    fi
}

# Get architecture
get_arch() {
    case "$(uname -m)" in
        x86_64) echo "amd64" ;;
        aarch64) echo "arm64" ;;
        *) echo "unknown" ;;
    esac
}

# Package helpers
apt_has() {
    local cand
    cand=$(apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/ {print $2}')
    [ -n "$cand" ] && [ "$cand" != "(none)" ]
}

# Flatpak helpers
fp() {
    flatpak --system "$@"
}

fp_installed() {
    fp info "$1" &>/dev/null
}

# Subid helpers
add_subid_range() {
    local file="$1" user="$2" start
    touch "$file"
    grep -q "^${user}:" "$file" && return 0
    start=$(awk -F: 'BEGIN{m=100000} {e=$2+$3; if (e>m) m=e} END{print m}' "$file")
    echo "${user}:${start}:65536" >> "$file"
}

# --- File/Dir Helpers ---
as_needed() {
    local cmd="$1"; shift
    local sudo_cmd="${SUDO:-}"
    "$cmd" "$@" 2>/dev/null && return 0
    if [ -n "$sudo_cmd" ]; then
        "$sudo_cmd" "$cmd" "$@"
    else
        return 1
    fi
}

fix_perms() {
    local group="$1"; shift
    if ! getent group "$group" >/dev/null; then
        warn "group '$group' not found; skipping group permissions"
        return 0
    fi
    local p
    for p in "$@"; do
        [ -e "$p" ] || continue
        as_needed chgrp -R "$group" "$p" || true
        as_needed chmod -R g+rwX "$p" || true
        as_needed find "$p" -type d -exec chmod g+s {} + || true
    done
}

ensure_dirs() {
    local owner="$1"; shift
    local d
    for d in "$@"; do
        if [ ! -d "$d" ]; then
            mkdir -p "$d"
            [ -n "$owner" ] && chown "$owner:$(id -gn "$owner")" "$d"
        fi
    done
}

link_entries() {
    local src="$1" dest="$2" owner="$3" entry target
    [ -d "$src" ] || return 0
    for entry in "$src"/*; do
        [ -e "$entry" ] || continue
        target="$dest/$(basename "$entry")"
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            warn "Skipping $target (real file/dir exists)"
            continue
        fi
        ln -sfn "$entry" "$target"
        [ -n "$owner" ] && chown -h "$owner:$(id -gn "$owner")" "$target"
    done
}

sync_repo() {
    local url="$1" dir="$2"
    if [ -d "$dir/.git" ]; then
        if git -C "$dir" fetch --depth=1 -q origin; then
            git -C "$dir" reset --hard -q FETCH_HEAD
        else
            warn "Could not fetch $url; using existing checkout"
        fi
    else
        rm -rf "$dir"
        git clone --depth=1 -q "$url" "$dir"
    fi
}

needs_install() {
    local stamp="$STAMP_DIR/$1" want="$2"
    [ "$FORCE" = "1" ] || [ ! -f "$stamp" ] || [ "$(cat "$stamp")" != "$want" ]
}

write_stamp() { 
    mkdir -p "$STAMP_DIR"
    printf '%s' "$2" > "$STAMP_DIR/$1" 
}

show_spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\\'
    echo -ne "\r"
    while kill -0 "$pid" 2>/dev/null; do
        local i
        for (( i=0; i<${#spinstr}; i++ )); do
            echo -ne "\r${spinstr:i:1} Please wait..."
            sleep $delay
        done
        echo -ne "\r"
    done
    echo -ne "\r"
}

# Progress spinner
spinner() {
    local pid=$1
    local delay=0.1

    local spinstr='|/-\'
    echo -ne "\r"
    while [ "$(ps -p $pid -o state= 2>/dev/null)" ]; do
        local temp=${spinstr#?}
        spinstr=${spinstr%$temp}$temp$spinstr
        echo -ne "\r$spinstr"
        sleep $delay
    done
    echo -ne "\r"
}
