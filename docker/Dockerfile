# Build environment for the phase 1 port (tools/docker_build.sh drives it).
#
# Arch with multilib, like the CachyOS host the game runs on, so the 32-bit system libraries the loader links
# against are the ones it loads there. SDL3/FAudio/freeglut are still built from source into ../deps/prefix32
# (tools/build_deps32.sh) because they ship with the build. No game data goes into the image: the lindbergh folder
# is mounted at run time.
FROM archlinux:latest

RUN printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >>/etc/pacman.conf \
    && pacman -Syu --noconfirm --needed \
        base-devel gcc-multilib cmake ninja git python pkgconf \
        lib32-glibc lib32-gcc-libs lib32-mesa lib32-libglvnd lib32-glu \
        lib32-libx11 lib32-libxext lib32-libxi lib32-libxrandr lib32-libxcursor lib32-libxss lib32-libxxf86vm \
        lib32-libxmu lib32-libxfixes lib32-libxtst lib32-libxkbcommon lib32-wayland wayland-protocols \
        lib32-alsa-lib lib32-libpulse lib32-pipewire lib32-systemd lib32-dbus \
        lib32-freetype2 lib32-libpng lib32-libjpeg-turbo lib32-zlib \
    && pacman -Scc --noconfirm
