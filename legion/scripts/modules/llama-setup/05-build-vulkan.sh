#!/bin/bash

# Dependencies: scripts/modules/utils.sh, scripts/modules/llama-setup/config.sh, scripts/modules/llama-setup/03-build-core.sh

build_vulkan() {
  command -v glslc >/dev/null || die "[vulkan] glslc not found (apt install glslc)"
  [ -f /usr/include/vulkan/vulkan.h ] || die "[vulkan] Vulkan headers not found (apt install libvulkan-dev)"
  build_one vulkan \
    -DGGML_VULKAN=ON \
    -DGGML_NATIVE=ON \
    -DGGML_OPENMP=ON \
    -DGGML_LTO=ON
}

setup_vulkan() {
  build_vulkan
}

uninstall_vulkan() {
  log "Vulkan build binaries are located in $BIN_ROOT/build-vulkan and will be removed if requested by orchestrator."
}
