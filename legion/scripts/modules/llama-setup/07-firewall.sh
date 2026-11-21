#!/bin/bash

# Dependencies: scripts/modules/utils.sh, scripts/modules/llama-setup/config.sh

open_firewall() {
  local port="${LLAMA_PORT:-9874}"
  command -v ufw >/dev/null 2>&1 || return 0
  if $SUDO ufw status 2>/dev/null | grep -q '^Status: active'; then
    if $SUDO ufw status | grep -qE "^$port/tcp .*ALLOW"; then return 0; fi
    $SUDO ufw allow "$port/tcp" comment 'llama-server' >/dev/null && log "ufw: allowed $port/tcp"
  fi
}

setup_firewall() {
  open_firewall
}

uninstall_firewall() {
  local port="${LLAMA_PORT:-9874}"
  command -v ufw >/dev/null 2>&1 || return 0
  if $SUDO ufw status 2>/dev/null | grep -q '^Status: active'; then
    $SUDO ufw delete allow "$port/tcp" comment 'llama-server' >/dev/null 2>/dev/null || true
  fi
}
