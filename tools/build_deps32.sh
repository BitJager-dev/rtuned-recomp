#!/usr/bin/env bash
# Builds the 32-bit libraries lindbergh-loader and the game need but most distros don't ship as 32-bit packages
# (SDL3, SDL3_image, SDL3_ttf, FAudio, freeglut) into a local prefix. No root needed.
#
#   tools/build_deps32.sh            # build what is missing
#   tools/build_deps32.sh --force    # rebuild everything
#
# Output: $DEPS/prefix32/{lib,include}. $DEPS defaults to ../deps (shared by all lindbergh projects).
# Needs: gcc/g++ with -m32 (gcc-multilib), git, python3, and 32-bit X11/GL/ALSA/udev/freetype dev libraries
# (Arch: lib32-mesa lib32-glu lib32-libx11 lib32-libxext lib32-libxi lib32-libxrandr lib32-libxcursor lib32-libxss
#  lib32-libxxf86vm lib32-libxmu lib32-alsa-lib lib32-systemd lib32-freetype2 lib32-harfbuzz).
# cmake and ninja come from a python venv in $DEPS/buildtools if they are not installed.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEPS="${DEPS:-$(cd "$ROOT/.." && pwd)/deps}"
PREFIX="$DEPS/prefix32"
SRC="$DEPS/src32"
FORCE=0; [ "${1:-}" = "--force" ] && FORCE=1

# name|repo|tag|extra cmake args
LIBS=(
  "SDL3|https://github.com/libsdl-org/SDL.git|release-3.4.16|-DSDL_TESTS=OFF -DSDL_EXAMPLES=OFF"
  "SDL3_image|https://github.com/libsdl-org/SDL_image.git|release-3.4.6|-DSDLIMAGE_VENDORED=OFF -DSDLIMAGE_AVIF=OFF -DSDLIMAGE_JXL=OFF -DSDLIMAGE_TIF=OFF -DSDLIMAGE_WEBP=OFF -DSDLIMAGE_SAMPLES=OFF -DSDLIMAGE_TESTS=OFF"
  "SDL3_ttf|https://github.com/libsdl-org/SDL_ttf.git|release-3.2.2|-DSDLTTF_VENDORED=OFF -DSDLTTF_HARFBUZZ=OFF -DSDLTTF_PLUTOSVG=OFF -DSDLTTF_SAMPLES=OFF"
  "FAudio|https://github.com/FNA-XNA/FAudio.git|26.09|-DBUILD_SHARED_LIBS=OFF"
  "freeglut|https://github.com/freeglut/freeglut.git|v3.6.0|-DFREEGLUT_BUILD_DEMOS=OFF -DFREEGLUT_BUILD_STATIC_LIBS=OFF -DFREEGLUT_GLES=OFF"
)

if command -v cmake >/dev/null && command -v ninja >/dev/null; then
  CMAKE=cmake; NINJA=ninja
else
  [ -x "$DEPS/buildtools/bin/cmake" ] || { python3 -m venv "$DEPS/buildtools" && "$DEPS/buildtools/bin/pip" install -q cmake ninja; }
  CMAKE="$DEPS/buildtools/bin/cmake"; NINJA="$DEPS/buildtools/bin/ninja"
fi

export PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig:/usr/lib32/pkgconfig"
mkdir -p "$PREFIX" "$SRC"

for entry in "${LIBS[@]}"; do
  IFS='|' read -r name repo tag extra <<<"$entry"
  stamp="$PREFIX/.installed-$name"
  if [ $FORCE = 0 ] && [ "$(cat "$stamp" 2>/dev/null)" = "$tag" ]; then echo "== $name $tag: up to date"; continue; fi
  echo "== $name $tag"
  if [ ! -d "$SRC/$name/.git" ]; then git clone -q "$repo" "$SRC/$name"; fi
  git -C "$SRC/$name" fetch -q --tags origin
  git -C "$SRC/$name" checkout -q "$tag"
  rm -rf "$SRC/$name/build32"
  # shellcheck disable=SC2086
  "$CMAKE" -S "$SRC/$name" -B "$SRC/$name/build32" -G Ninja -DCMAKE_MAKE_PROGRAM="$NINJA" \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS=-m32 -DCMAKE_CXX_FLAGS=-m32 \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_PREFIX_PATH="$PREFIX" \
    -DCMAKE_LIBRARY_PATH=/usr/lib32 -DCMAKE_POSITION_INDEPENDENT_CODE=ON $extra >/dev/null
  "$CMAKE" --build "$SRC/$name/build32"
  "$CMAKE" --install "$SRC/$name/build32" >/dev/null
  echo "$tag" >"$stamp"
done

echo "32-bit deps in $PREFIX/lib:"
ls "$PREFIX/lib" | grep -E '\.(so|a)' | tr '\n' ' '; echo
