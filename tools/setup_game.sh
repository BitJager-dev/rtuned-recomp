#!/usr/bin/env bash
# Unpacks your R-Tuned (SBQW) dump into game/ and checks it is the expected executable.
#   tools/setup_game.sh "R-Tuned - Ultimate Street Racing (SBQW).zip" [target dir]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ZIP="${1:?usage: setup_game.sh <R-Tuned SBQW zip> [target dir]}"
DEST="${2:-$ROOT/game}"
# disk0/dsr of DVP-0060 (SBQW)
DSR_MD5=b8c3887e8273c8caedecb1d0053af28f

[ -e "$DEST/disk0/dsr" ] && { echo "Already set up: $DEST/disk0"; exit 0; }
mkdir -p "$DEST"
# disk0/drv/ is the cabinet's kernel and NVIDIA driver set (full of relative symlinks): not needed on a PC
7z x -y -o"$DEST" "$ZIP" -xr'!disk0/drv' >/dev/null
[ -e "$DEST/disk0/dsr" ] || { echo "No disk0/dsr in $ZIP: not an R-Tuned dump?" >&2; exit 1; }
chmod +x "$DEST/disk0/dsr"
md5="$(md5sum <"$DEST/disk0/dsr" | cut -d' ' -f1)"
if [ "$md5" != "$DSR_MD5" ]; then
  echo "Warning: disk0/dsr md5 $md5 is not the known SBQW build ($DSR_MD5)" >&2
fi
echo "Game in $DEST/disk0 (dsr md5 $md5)"
