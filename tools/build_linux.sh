#!/usr/bin/env bash
# Phase 1 build: lindbergh-loader (pinned commit + patches/loader/*.patch) staged with our run script into dist-linux/.
#
#   tools/build_deps32.sh        # once: 32-bit SDL3/FAudio/freeglut into ../deps/prefix32
#   tools/build_linux.sh         # loader -> dist-linux/
#   tools/setup_game.sh <zip>    # game dump -> game/ (never committed)
#   dist-linux/run.sh            # play (-t = test menu)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEPS="${DEPS:-$(cd "$ROOT/.." && pwd)/deps}"
PREFIX="$DEPS/prefix32"
LOADER_REPO=https://github.com/lindbergh-loader/lindbergh-loader.git
LOADER_REV=0af606d
LOADER="$DEPS/lindbergh-loader"
DIST="$ROOT/dist-linux"

[ -e "$PREFIX/lib/libSDL3.so" ] || { echo "32-bit deps missing: run tools/build_deps32.sh first" >&2; exit 1; }

if [ ! -d "$LOADER/.git" ]; then git clone -q "$LOADER_REPO" "$LOADER"; fi
git -C "$LOADER" fetch -q origin || true

# Reset to the pinned commit and apply our patches whenever the patch set changes
shopt -s nullglob
PATCHES=("$ROOT"/patches/loader/*.patch)
STAMP="$LOADER_REV-$(cat /dev/null "${PATCHES[@]}" | sha1sum | cut -c1-12)"
if [ "$(cat "$LOADER/.rtuned-stamp" 2>/dev/null)" != "$STAMP" ]; then
  git -C "$LOADER" checkout -q -f "$LOADER_REV"
  git -C "$LOADER" clean -q -fdx
  for p in "${PATCHES[@]}"; do
    echo "== patch $(basename "$p")"
    git -C "$LOADER" apply "$p"
  done
  echo "$STAMP" >"$LOADER/.rtuned-stamp"
fi

# The loader's Makefile looks in /app/lib32 (flatpak); point the compiler and linker at our prefix instead.
PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig:/usr/lib32/pkgconfig" \
LIBRARY_PATH="$PREFIX/lib:/usr/lib32" \
C_INCLUDE_PATH="$PREFIX/include" CPLUS_INCLUDE_PATH="$PREFIX/include" \
  make -C "$LOADER" -j"$(nproc)"

rm -rf "$DIST"; mkdir -p "$DIST/lib32"
cp -a "$LOADER"/build/. "$DIST/"
cp -a "$LOADER"/libs/libCg.so "$DIST/lib32/"
cp -a "$PREFIX"/lib/libSDL3*.so* "$PREFIX"/lib/libglut.so* "$DIST/lib32/"
cp "$ROOT/tools/run.sh" "$DIST/run.sh"
chmod +x "$DIST/run.sh"
git -C "$ROOT" rev-parse --short HEAD >"$DIST/VERSION" 2>/dev/null || echo dev >"$DIST/VERSION"
echo "Built $DIST (loader $LOADER_REV, $(cat "$DIST/VERSION"))"
