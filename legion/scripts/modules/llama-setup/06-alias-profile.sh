#!/bin/bash

# Dependencies: scripts/modules/utils.sh, scripts/modules/llama-setup/config.sh

install_alias() {
  local self src dest="$BIN_ROOT/alias.env"
  self="$(realpath "${BASH_SOURCE[0]}")"
  src="$(dirname "$self")/alias.env"

  # keep a copy of this script where `llm --recompile` expects it
  if [ "$self" != "$BIN_ROOT/llama-setup.sh" ]; then
    cmp -s "$self" "$BIN_ROOT/llama-setup.sh" 2>/dev/null || install -m 775 "$self" "$BIN_ROOT/llama-setup.sh"
  fi

  if [ "$src" = "$dest" ]; then return 0; fi
  if [ ! -f "$dest" ]; then
    [ -f "$src" ] || die "alias.env not found next to this script ($src)"
    install -m 664 "$src" "$dest"; log "created $dest"
  elif ((RESET_ALIAS)); then
    cp -a "$dest" "$dest.bak.$(date +%Y%m%d-%H%M%S)"
    install -m 664 "$src" "$dest"; log "replaced $dest (backup kept)"
  elif [ -f "$src" ] && ! cmp -s "$src" "$dest"; then
    log "kept existing $dest (differs from $src; use --reset-alias to replace)"
  fi
}

profile_block() {
  printf '%s\n[ -f "%s/alias.env" ] && . "%s/alias.env"\n%s\n' \
    "$PROFILE_BEGIN" "$BIN_ROOT" "$BIN_ROOT" "$PROFILE_END"
}

hook_profile() {
  local rc="$1"
  [ -f "$rc" ] || return 0
  grep -qF "$PROFILE_BEGIN" "$rc" && return 0
  if [ -w "$rc" ]; then profile_block >> "$rc"
  elif [ -n "$SUDO" ]; then profile_block | $SUDO tee -a "$rc" >/dev/null
  else warn "cannot update $rc"; return 0; fi
  log "added alias.env to $rc"
}

hook_all_profiles() {
  hook_profile "$HOME/.bashrc"
  local members u home
  members="$(getent group "$SHARED_GROUP" | cut -d: -f4 | tr ',' ' ')"
  for u in $members; do
    home="$(getent passwd "$u" | cut -d: -f6)"
    if [ -n "$home" ] && [ "$home" != "$HOME" ]; then hook_profile "$home/.bashrc"; fi
  done
}

setup_alias_profile() {
  install_alias
  hook_all_profiles
}

uninstall_alias_profile() {
  log "Removing alias.env and profile hooks from .bashrc"
  # This is hard to do perfectly without a specialized tool, 
  # but we can try to remove the block if it exists.
  if [ -f "$HOME/.bashrc" ]; then
    sed -i '/$PROFILE_BEGIN/,/$PROFILE_END/d' "$HOME/.bashrc"
  fi
}
