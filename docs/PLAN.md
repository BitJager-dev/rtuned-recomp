# Plan

## What the game is

| | |
|---|---|
| Executable | `disk0/dsr`, ELF 32-bit i386, stripped, dynamically linked, md5 `b8c3887e8273c8caedecb1d0053af28f` |
| Libraries | `libsegaapi.so`, `libglut.so.3`, `libGLU.so.1`, `libGL.so.1`, `libXmu`, `libXext`, `libX11`, `libstdc++.so.6` (gcc 3.4), `libpthread`, `libm`, `libc`, `libgcc_s`, `libdl` |
| Start | `disk0/game`: mounts a save partition at `/home/disk2`, sets `GLIBCXX_FORCE_NEW=1`, runs `dsr -fs` |
| Data | `disk0/rom/` (`.farc` archives: objects, courses, sound, sprites, shaders), `disk0/ROM_LANG/en/` |
| Hardware | Lindbergh Yellow, native 640x480, JVS driving cabinet, HW210 card reader (not used by R-Tuned), 4-cab link |

## Phase 1: shim port (x86-64)

lindbergh-loader already lists R-Tuned as working (game table, Mesa shader patches `shaderWork/rtuned.h`,
network link patch, resolution patch). Steps:

1. Build the loader without root (32-bit deps in `../deps/prefix32`): `tools/build_deps32.sh`, `tools/build_linux.sh`.
2. First boot on CachyOS / Radeon 8060S (radeonsi), then on Zink (`RTUNED_ZINK=1`).
3. Controls: Xbox pad and a wheel through SDL3, force feedback.
4. Our fixes go in `patches/loader/` and upstream as PRs where they are general.
5. Launcher (monitor, resolution, controls, start) and release packaging like the XBLA ports; NAS shipping.

Phase 1 is the reference for phase 2: same input, same frames.

## Phase 2: static recomp (x86-64 + ARM64)

Goal: the game code as C compiled natively for both architectures, no x86 emulation on ARM, own renderer.

1. Analysis: Ghidra project of `dsr`; recover functions, the C++ class layout (gcc 3.4 ABI, RTTI if present) and
   all calls into GL/GLUT/Cg/segaapi/libc. The loader's patch addresses are a good map of the important places.
2. Lifter: x86-32 -> C, one C function per game function, guest memory and registers as in other static recomps;
   indirect calls through a function table. Open questions: x87 80-bit floats (check whether the game uses x87 or
   SSE), self-checks, jump tables.
3. Runtime: guest libc/libstdc++ calls mapped to host, GL 2 + Cg replaced by a Vulkan renderer (shaders translated
   to SPIR-V), SDL3 input/audio replacing JVS and segaapi.
4. Validation: run phase 1 and phase 2 with the same recorded input, compare frames and state.

Expected gain: on x86-64 little CPU speed (the original already runs natively in 32-bit mode); the value is ARM64
(native speed instead of FEX/Box86 emulation) and a modern renderer (resolution, widescreen, frame rate).
