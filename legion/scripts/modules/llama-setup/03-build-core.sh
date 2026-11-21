#!/bin/bash

# Dependencies: scripts/modules/utils.sh, scripts/modules/llama-setup/config.sh

COMPAT_DIR="$SHARED_ROOT/lib/compat"
KEEP_BINS=(llama-server llama-bench)

# build_one <name> <cmake args...>
build_one() {
  local name="$1"; shift
  local -a args=("$@")
  local dest="$BIN_ROOT/build-$name" bdir="$REPO_DIR/build-$name" stage="$BIN_ROOT/build-$name.staging"
  local commit stamp t

  commit=$(git -C "$REPO_DIR" rev-parse HEAD)
  stamp="$commit:$(printf '%s\n' "${args[@]}" | sha1sum | cut -c1-12)"

  if ((FORCE == 0)) && [ -x "$dest/bin/llama-server" ] && [ "$(cat "$dest/.stamp" 2>/dev/null)" = "$stamp" ]; then
    log "[$name] up to date (${commit:0:8}); skipping"
    return 0
  fi

  log "[$name] configuring"
  cmake -S "$REPO_DIR" -B "$bdir" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_RPATH='$ORIGIN/../lib' \
    -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON \
    "${args[@]}" || die "[$name] cmake configure failed"

  log "[$name] building with $JOBS jobs"
  cmake --build "$bdir" --config Release -j"$JOBS" || die "[$name] build failed"

  rm -rf "$stage" "$stage.full"
  cmake --install "$bdir" --prefix "$stage.full" --config Release || die "[$name] install failed"
  mkdir -p "$stage/bin" "$stage/lib"
  for t in "${KEEP_BINS[@]}"; do
    if   [ -x "$stage.full/bin/$t" ]; then cp -a "$stage.full/bin/$t" "$stage/bin/"
    elif [ -x "$bdir/bin/$t" ];       then install -D -m 775 "$bdir/bin/$t" "$stage/bin/$t"
    else warn "[$name] $t not produced by this build"; fi
  done
  find "$stage.full/lib" -maxdepth 1 \( -name '*.so' -o -name '*.so.*' \) -exec cp -a {} "$stage/lib/" \;
  rm -rf "$stage.full"
  [ -x "$stage/bin/llama-server" ] || die "[$name] llama-server missing after install"
  echo "$stamp" > "$stage/.stamp"

  rm -rf "$dest.old"
  if [ -d "$dest" ]; then mv "$dest" "$dest.old"; fi
  mv "$stage" "$dest"
  rm -rf "$dest.old"
  log "[$name] installed -> $dest"
}

rocm_missing_libs() {  # <llvm bin dir>
  local f
  for f in "$1/clang" "$1/ld.lld"; do
    if [ -x "$f" ]; then ldd "$f" 2>/dev/null | awk '/not found/ {print $1}'; fi
  done | sort -u
}

build_libxml2_compat() {
  local ver=2.9.14 tmp
  [ -e "$COMPAT_DIR/libxml2.so.2" ] && return 0
  mkdir -p "$COMPAT_DIR"
  tmp="$(mktemp -d)"
  log "building libxml2 $ver compat library for ROCm's ld.lld"
  ( cd "$tmp" \
    && curl -fsSL "https://download.gnome.org/sources/libxml2/2.9/libxml2-$ver.tar.xz" | tar xJ \
    && cd "libxml2-$ver" \
    && CFLAGS="-O2 -std=gnu17" ./configure --prefix="$tmp/inst" --disable-static \
         --without-python --without-icu --without-lzma --without-zlib --without-http --without-ftp >/dev/null \
    && make -j"$JOBS" >/dev/null \
    && make install >/dev/null ) || { rm -rf "$tmp"; return 1; }
  cp -a "$tmp"/inst/lib/libxml2.so* "$COMPAT_DIR/"
  rm -rf "$tmp"
}

ensure_rocm_toolchain() {  # <llvm bin dir>; exports LD_LIBRARY_PATH for this (sub)shell
  local llvm="$1" miss
  if [ -e "$COMPAT_DIR/libxml2.so.2" ]; then export LD_LIBRARY_PATH="$COMPAT_DIR:${LD_LIBRARY_PATH:-}"; fi
  miss="$(rocm_missing_libs "$llvm" || true)"
  [ -z "$miss" ] && return 0
  if grep -qx 'libxml2.so.2' <<<"$miss"; then
    build_libxml2_compat || die "[rocm] could not build libxml2 compat library"
    export LD_LIBRARY_PATH="$COMPAT_DIR:${LD_LIBRARY_PATH:-}"
    miss="$(rocm_missing_libs "$llvm" || true)"
  fi
  [ -z "$miss" ] || die "[rocm] ROCm toolchain still missing libraries: $(echo $miss) (install the matching apt packages)"
  "$llvm/ld.lld" --version >/dev/null 2>&1 || die "[rocm] $llvm/ld.lld does not run"
}

setup_build_core() {
  :
}

uninstall_build_core() {
  log "Build artifacts are not automatically uninstalled by the core module."
}
