#!/usr/bin/env bash
# =============================================================================
# llama-setup.sh - orchestrator for building llama.cpp (ROCm + Vulkan)
# =============================================================================
set -Eeuo pipefail
umask 002

# --- Base Paths ---
# We assume this script is located in scripts/ or can be run from anywhere.
SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
MODULE_DIR="$SCRIPT_DIR/modules/llama-setup"

# Source Core Modules
# The order of sourcing is important: utils and config must come before feature modules.
source "$SCRIPT_DIR/modules/utils.sh"
source "$MODULE_DIR/config.sh"
source "$MODULE_DIR/01-dependencies.sh"
source "$MODULE_DIR/02-repo.sh"
source "$MODULE_DIR/03-build-core.sh"
source "$MODULE_DIR/04-build-rocm.sh"
source "$MODULE_DIR/05-build-vulkan.sh"
source "$MODULE_DIR/06-alias-profile.sh"
source "$MODULE_DIR/07-firewall.sh"

# --- Sudo/Privilege setup ---
if [ "$(id -u)" -eq 0 ]; then SUDO=""
elif command -v sudo >/dev/null 2>&1; then SUDO="sudo"
else SUDO=""; fi
export SUDO

# Global Flags
PULL=0; FORCE=0; DO_DEPS=1; DO_ROCM=1; DO_VULKAN=1; RESET_ALIAS=0; DRY_RUN=0; UNINSTALL=0; VERIFY=0
VERSION="1.0.0"

usage() {
  cat <<EOF
Usage: ./llama-setup.sh [OPTIONS]

Build llama.cpp (ROCm + Vulkan) for Legion 7a / Ryzen AI Max+ 388.

Options:
  -h, --help             Show this help message
  -v, --version          Show version information
  --recompile            Clean build dirs, git pull latest, and full rebuild (implies --force)
  --force                Rebuild even if nothing changed
  --no-deps              Skip apt dependency step
  --rocm-only            Install ROCm and build ROCm backend only
  --vulkan-only          Install Vulkan and build Vulkan backend only
  --reset-alias          Overwrite alias.env with the one next to this script
  --uninstall            Undo changes made by this script
  --dry-run              Show what the script would do without making any changes
  --verify               Check if the changes are correct and valid
EOF
}

parse_args() {
  while (($#)); do
    case "$1" in
      --recompile)   PULL=1; FORCE=1 ;;
      --force)       FORCE=1 ;;
      --no-deps)     DO_DEPS=0 ;;
      --rocm-only)   DO_VULKAN=0 ;;
      --vulkan-only) DO_ROCM=0 ;;
      --reset-alias) RESET_ALIAS=1 ;;
      --uninstall)    UNINSTALL=1 ;;
      --dry-run)     DRY_RUN=1 ;;
      --verify)      VERIFY=1 ;;
      -h|--help)     usage; exit 0 ;;
      -v|--version)  echo "llama-setup $VERSION"; exit 0 ;;
      *) die "unknown option: $1 (try --help)" ;;
    esac
    shift
  done
}

run_module() {
  local module_func="$1"
  local module_name="$2"
  
  if ((DRY_RUN)); then
    log "[$module_name] [DRY-RUN] Would run $module_func"
    return 0
  fi

  log "[$module_name] Executing $module_func..."
  if ! "$module_func"; then
    warn "[$module_name] $module_func failed"
    return 1
  fi
  return 0
}

verify_setup() {
  log "Verifying installation..."
  local failed=()
  
  # Check binaries
  [ -x "$BIN_ROOT/build-rocm/bin/llama-server" ] || failed+=("rocm llama-server")
  [ -x "$BIN_ROOT/build-vulkan/bin/llama-server" ] || failed+=("vulkan llama-server")
  
  # Check alias
  [ -f "$BIN_ROOT/alias.env" ] || failed+=("alias.env")
  
  # Check GPU target
  if ((DO_ROCM)); then
    have_rocm || failed+=("ROCm backend (check GPU target/drivers)")
  fi

  if ((${#failed[@]})); then
    error "Verification failed: ${failed[*]}"
    return 1
  else
    success "Verification passed!"
  fi
}

prepare_env() {
  # Ensure base directories exist
  ensure_dirs "$SHARED_ROOT" "$SHARED_ROOT/git/ai" "$BIN_ROOT" "$MODEL_DIR" "$BENCH_DIR" "$COMPAT_DIR"
  
  # Migrate models if necessary
  if [ -d "$OLD_MODEL_DIR" ] && [ -n "$(ls -A "$OLD_MODEL_DIR" 2>/dev/null)" ] && [ -z "$(ls -A "$MODEL_DIR" 2>/dev/null)" ]; then
    log "migrating models: $OLD_MODEL_DIR -> $MODEL_DIR"
    mv "$OLD_MODEL_DIR"/* "$MODEL_DIR"/ || warn "model migration incomplete"
  fi

  # Fix permissions for shared directories
  fix_perms "$SHARED_GROUP" "$SHARED_ROOT/git" "$BIN_ROOT" "$SHARED_ROOT/common" "$BENCH_DIR" "$SHARED_ROOT/lib"
}

main() {
  parse_args "$@"
  prepare_env

  if ((UNINSTALL)); then
    echo "This will attempt to uninstall components. Continue? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[yY]$ ]]; then
      exit 0
    fi
    run_module uninstall_alias_profile "Alias/Profile"
    run_module uninstall_firewall "Firewall"
    run_module uninstall_repo "Repo"
    exit 0
  fi

  # Lock file
  exec 9>"$LOCK_FILE"
  if ! flock -w 3600 9; then
    die "another build holds the lock ($LOCK_FILE)"
  fi

  # Execution sequencing
  failed=()

  if ((DO_DEPS)); then
    run_module setup_dependencies "Dependencies" || failed+=("Dependencies")
  fi

  if ((PULL)); then
    log "recompile: cleaning old build directories"
    ((DO_ROCM))   && rm -rf "$REPO_DIR/build-rocm"
    ((DO_VULKAN)) && rm -rf "$REPO_DIR/build-vulkan"
    rm -f "$BIN_ROOT"/build-*.staging.full 2>/dev/null || true
    rm -rf "$BIN_ROOT"/build-*.staging "$BIN_ROOT"/build-*.staging.full "$BIN_ROOT"/build-*.old
  fi

  run_module sync_repo "Repository" || failed+=("Repository")

  if ((DO_ROCM)); then
    run_module setup_rocm "ROCm Build" || failed+=("ROcm Build")
  fi

  if ((DO_VULKAN)); then
    run_module setup_vulkan "Vulkan Build" || failed+=("Vulkan Build")
  fi

  run_module setup_alias_profile "Alias/Profile" || failed+=("Alias/Profile")
  run_module setup_firewall "Firewall" || warn "could not update firewall"

  if ((${#failed[@]})); then
    error "failed steps: ${failed[*]}"
    exit 1
  fi

  if ((VERIFY)); then
    verify_setup || exit 1
  fi

  log "done. commit: $(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo "N/A")"
  echo
  if ((${#failed[@]})); then
    warn "failed backends: ${failed[*]}"
    exit 1
  fi
  log "open a new shell (or: source $BIN_ROOT/alias.env) and run: llm --help"
}

main "$@"
