#!/bin/bash

# Dependencies: scripts/modules/utils.sh, scripts/modules/llama-setup/config.sh, scripts/modules/llama-setup/03-build-core.sh

build_rocm() {
  have_rocm || die "[rocm] ROCm HIP SDK not available; skipping"
  export PATH="$ROCM_PATH/bin:$PATH"
  export LD_LIBRARY_PATH="$ROCM_PATH/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  local llvm; llvm="$(hipconfig -l)" || die "[rocm] hipconfig -l failed"
  ensure_rocm_toolchain "$llvm"
  # a previous failed configure leaves a half-initialised build dir; start clean
  [ -f "$REPO_DIR/build-rocm/build.ninja" ] || rm -rf "$REPO_DIR/build-rocm"
  local -a args=(
    -DCMAKE_C_COMPILER="$llvm/clang"
    -DCMAKE_CXX_COMPILER="$llvm/clang++"
    -DCMAKE_HIP_COMPILER="$llvm/clang"
    -DCMAKE_PREFIX_PATH="$ROCM_PATH"
    -DGGML_HIP=ON
    -DHIP_PLATFORM=amd
    -DGPU_TARGETS="$GPU_TARGET"
    -DAMDGPU_TARGETS="$GPU_TARGET"
    -DGGML_NATIVE=ON
    -DGGML_OPENMP=ON
    -DGGML_LTO=ON
  )
  if [ "${ROCWMMA:-0}" = 1 ]; then args+=(-DGGML_HIP_ROCWMMA_FATTN=ON); fi
  build_one rocm "${args[@]}"
}

setup_rocm() {
  build_rocm
}

uninstall_rocm() {
  log "ROCm build binaries are located in $BIN_ROOT/build-rocm and will be removed if requested by orchestrator."
}
