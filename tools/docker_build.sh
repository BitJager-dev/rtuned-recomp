#!/usr/bin/env bash
# Build the phase 1 port in the container (docker/Dockerfile): 32-bit deps + lindbergh-loader -> dist-linux/.
#
#   tools/docker_build.sh            # build deps (if missing) and the loader
#   tools/docker_build.sh --shell    # interactive shell in the build environment
#
# The lindbergh folder (this project and ../deps) is mounted at the same absolute path, so recorded paths stay
# valid on the host, and the container runs as you, so everything it writes is yours. The game runs on the host
# (dist-linux/run.sh): it needs the GPU, the display and the controller.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LINDBERGH="$(cd "$ROOT/.." && pwd)"
IMAGE=rtuned-recomp-build

# Rebuild the image when the Dockerfile changes.
tag="$(sha256sum <"$ROOT/docker/Dockerfile" | cut -c1-12)"
if ! docker image inspect "$IMAGE:$tag" >/dev/null 2>&1; then
  echo "== Building the $IMAGE:$tag image"
  docker build -t "$IMAGE:$tag" -t "$IMAGE:latest" "$ROOT/docker"
fi

run=(docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp
     -v "$LINDBERGH:$LINDBERGH" -w "$ROOT")
if [[ "${1:-}" == "--shell" ]]; then
  exec "${run[@]}" -it "$IMAGE:$tag" bash
fi

mkdir -p "$ROOT/logs"
"${run[@]}" "$IMAGE:$tag" bash -c \
  "git config --global --add safe.directory '*' && tools/build_deps32.sh && tools/build_linux.sh" \
  2>&1 | tee "$ROOT/logs/build.log"
echo "build log: logs/build.log"
