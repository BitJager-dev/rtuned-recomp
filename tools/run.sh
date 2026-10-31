#!/usr/bin/env bash
# Starts R-Tuned through lindbergh-loader. Lives in dist-linux/; the game is looked up in $RTUNED_GAME,
# ./game/disk0 or ../game/disk0. Extra arguments go to the loader (-t = test menu).
#   RTUNED_ZINK=1 ./run.sh   # render the game's OpenGL through Vulkan (Mesa Zink)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
GAME="${RTUNED_GAME:-}"
for d in "$GAME" "$HERE/game/disk0" "$HERE/../game/disk0"; do
  [ -n "$d" ] && [ -x "$d/dsr" ] && { GAME="$(cd "$d" && pwd)"; break; }
done
[ -x "${GAME:-}/dsr" ] || { echo "Game not found: run tools/setup_game.sh or set RTUNED_GAME=<.../disk0>" >&2; exit 1; }

# The loader runs from the game folder: link in its files (kept separate so updates don't touch the dump)
for f in lindbergh lindbergh.so libsegaapi.so libkswapapi.so libposixtime.so libposixtime.so.1 libposixtime.so.2.4; do
  [ -e "$HERE/$f" ] && ln -sfn "$HERE/$f" "$GAME/$f"
done
[ -e "$GAME/lindbergh.conf" ] || cp "$HERE/lindbergh.conf.default" "$GAME/lindbergh.conf"

export LD_LIBRARY_PATH="$GAME:$HERE/lib32${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
if [ "${RTUNED_ZINK:-0}" = 1 ]; then
  export MESA_LOADER_DRIVER_OVERRIDE=zink __GLX_VENDOR_LIBRARY_NAME=mesa
fi

cd "$GAME"
exec ./lindbergh "$@"
