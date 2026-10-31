# R-Tuned: Ultimate Street Racing (SEGA Lindbergh): native PC port

SEGA's R-Tuned: Ultimate Street Racing (Lindbergh Yellow, 2008, game ID `SBQW`, DVP-0060) on modern Linux, first
through a shim layer around the original executable, later as a static recompilation for x86-64 and ARM64 with a
Vulkan renderer.

No game data is in this repository. You need your own dump of the game (`disk0/` with the `dsr` executable).

## Why not ReXGlue like the XBLA recomps?

Lindbergh is a PC: a Pentium 4 / Core 2 with an NVIDIA GeForce 7/8 running MontaVista Linux. The game is a stripped
32-bit x86 Linux ELF (`disk0/dsr`, 4.4 MB) that uses OpenGL 2 + GLUT, NVIDIA Cg shaders, SEGA's `libsegaapi.so`
audio library and JVS cabinet I/O over serial. There is no PowerPC code to translate, so the plan is:

| Phase | What | Runs on |
|---|---|---|
| 1. Shim port (now) | Original `dsr` started through [lindbergh-loader](https://github.com/lindbergh-loader/lindbergh-loader) (LD_PRELOAD shim: JVS, controls, segaapi audio via FAudio, Cg/GPU fixes, hardware checks), our patches, launcher and packaging. Vulkan via Mesa Zink | x86-64 Linux |
| 2. Static recomp | `dsr` lifted to C, rebuilt 64-bit against our own runtime (Vulkan renderer, SDL3 input/audio, no Cg), checked frame by frame against phase 1 | x86-64 and ARM64 Linux |

Details and open questions: [docs/PLAN.md](docs/PLAN.md).

## Phase 1: build and run

```sh
tools/build_deps32.sh                                   # once: 32-bit SDL3, SDL3_image, SDL3_ttf, FAudio, freeglut
tools/build_linux.sh                                    # lindbergh-loader (pinned + patches/loader/) -> dist-linux/
tools/setup_game.sh "R-Tuned - Ultimate Street Racing (SBQW).zip"   # your dump -> game/
dist-linux/run.sh                                       # play; -t = test menu
RTUNED_ZINK=1 dist-linux/run.sh                         # OpenGL through Vulkan (Zink)
```

The 32-bit libraries go to `../deps/prefix32` (shared by all Lindbergh projects next to this one); nothing needs
root. Build needs: gcc with `-m32`, git, python3 and the 32-bit X11/GL/ALSA/udev/freetype libraries (Arch names in
`tools/build_deps32.sh`). For controllers and the serial emulation, your user should be in the `input` group.

Settings: `game/disk0/lindbergh.ini` (the loader's defaults, created on the first start), controls in
`game/disk0/controls.ini` (see the loader's [controls guide](https://github.com/lindbergh-loader/lindbergh-loader/blob/master/docs/CONTROLS.md)).

## Status

- [x] Repo, deps and build scripts
- [ ] First boot on Linux / AMD (Mesa radeonsi) and on Zink
- [ ] Controls (pad + wheel), force feedback, sound
- [ ] Launcher, release packaging

## License

Our scripts and docs: CC BY-NC-SA 4.0, the same license as lindbergh-loader, which this project builds and patches
(`patches/loader/`). R-Tuned is © SEGA; this project ships none of its files.
