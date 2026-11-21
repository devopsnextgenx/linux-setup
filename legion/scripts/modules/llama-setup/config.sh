#!/bin/bash

# --- Base Paths ---
export SHARED_ROOT="${SHARED_ROOT:-/home/shared}"
export SHARED_GROUP="${SHARED_GROUP:-sharedusers}"
export REPO_URL="${REPO_URL:-https://github.com/ggml-org/llama.cpp.git}"
export REPO_DIR="$SHARED_ROOT/git/ai/llama.cpp"
export BIN_ROOT="$SHARED_ROOT/bin"
export MODEL_DIR="$SHARED_ROOT/common/llama.cpp/models"
export OLD_MODEL_DIR="$SHARED_ROOT/models"
export BENCH_DIR="$SHARED_ROOT/bench"
export LOCK_FILE="$SHARED_ROOT/git/ai/.llama-build.lock"
export COMPAT_DIR="$SHARED_ROOT/lib/compat"

# --- GPU / ROCm / Vulkan ---
export GPU_TARGET="${GPU_TARGET:-gfx1151}"
export ROCM_PATH="${ROCM_PATH:-/opt/rocm}"
export ROCM_VERSION="${ROCM_VERSION:-7.2.1}"
export JOBS="${JOBS:-$(nproc)}"
export KEEP_BINS=(llama-server llama-bench)
export ROCWMMA="${ROCWMMA:-0}"

# --- Profiles ---
export PROFILE_BEGIN="# >>> llama-shared >>>"
export PROFILE_END="# <<< llama-shared <<<"
