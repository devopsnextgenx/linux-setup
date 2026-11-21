#!/bin/bash

# Dependencies: scripts/modules/utils.sh, scripts/modules/llama-setup/config.sh

REQUIRED_PKGS=(build-essential cmake ninja-build git curl gnupg ca-certificates pkg-config ccache
               libcurl4-openssl-dev libssl-dev libomp-dev python3)
VULKAN_PKGS=(libvulkan-dev glslc glslang-tools spirv-headers mesa-vulkan-drivers vulkan-tools)

pkg_installed() { [ "$(dpkg-query -W -f='${db:Status-Status}' "$1" 2>/dev/null)" = "installed" ]; }

have_rocm() { [ -x "$ROCM_PATH/bin/hipconfig" ] && [ -d "$ROCM_PATH/include/hipblas" ]; }

install_rocm() {
  if have_rocm; then log "ROCm already present: $(readlink -f "$ROCM_PATH")"; return 0; fi

  local ver="$ROCM_VERSION" code
  code="$(. /etc/os-release; echo "${VERSION_CODENAME:-noble}")"
  case "$code" in jammy|noble) ;; *) code=noble ;; esac

  local base="https://repo.radeon.com/rocm/apt/$ver"
  curl -fsI "$base/dists/$code/Release" >/dev/null 2>&1 \
    || { warn "AMD repo not found: $base ($code). Set ROCM_VERSION to a version listed at https://repo.radeon.com/rocm/apt/"; return 1; }

  log "adding AMD ROCm $ver apt repo ($code) and installing 'rocm'"
  $SUDO apt-get update
  $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y rocm || return 1

  echo "$ROCM_PATH/lib" | $SUDO tee /etc/apt/sources.list.d/rocm.conf >/dev/null 2>/dev/null || true
  $SUDO ldconfig
  have_rocm || { warn "ROCm installed but hipconfig/hipblas headers not found under $ROCM_PATH"; return 1; }
  log "ROCm installed: $(readlink -f "$ROCM_PATH")"
}

add_gpu_groups() {
  local members u g
  members="$(getent group "$SHARED_GROUP" 2>/dev/null | cut -d: -f4 | tr ',' ' ') $(id -un)"
  for u in $(printf '%s\n' $members | sort -u); do
    id "$u" >/dev/null 2>&1 || continue
    for g in render video; do
      getent group "$g" >/dev/null || continue
      if id -nG "$u" | tr ' ' '\n' | grep -qx "$g"; then continue; fi
      $SUDO usermod -aG "$g" "$u" && log "added $u to group $g" || warn "could not add $u to $g"
    done
  done
}

kernel_check() {
  local k; k="$(uname -r | cut -d. -f1,2)"
  if [ "$(printf '%s\n6.14\n' "$k" | sort -V | head -n1)" != "6.14" ]; then
    warn "kernel $(uname -r) is older than 6.14; gfx1151 ROCm needs 6.14+ and a reboot"
  fi
}

install_deps() {
  command -v apt-get >/dev/null || die "this script supports Debian/Ubuntu (apt) only"
  local missing=() p
  for p in "${REQUIRED_PKGS[@]}"; do pkg_installed "$p" || missing+=("$p"); done
  if ((${#missing[@]})); then
    log "installing: ${missing[*]}"
    $SUDO apt-get update
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${missing[@]}"
  fi

  if ((DO_VULKAN)); then
    for p in "${VULKAN_PKGS[@]}"; do
      pkg_installed "$p" && continue
      log "installing optional Vulkan package: $p"
      $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$p" || warn "could not install $p"
    done
  fi

  if ((DO_ROCM)); then install_rocm || warn "ROCm install failed; ROCm build will be skipped"; fi
  add_gpu_groups
  kernel_check
}

setup_dependencies() {
  install_deps
}

uninstall_dependencies() {
  log "Dependencies are system packages and usually not uninstalled by this script."
}
