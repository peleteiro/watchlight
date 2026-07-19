---
name: build
description: Build, check, format, flash, and monitor the Atalaia firmware via mise
---

# build

Compile, check, format, flash, and observe the Atalaia firmware. Always go through
`mise`, never raw `pio` or `platformio`.

## Commands

- `mise run build` — compile only. First run downloads the ESP32 toolchain and
  libraries (several minutes); later runs are fast.
- `mise run check` — run PlatformIO static analysis.
- `mise run lint` — format the tracked firmware sources with clang-format.
- `mise run upload` — build and flash over USB. The device must be connected; the
  serial port is auto-detected.
- `mise run monitor` — open the serial monitor at 115200 baud to read logs.
- `mise run upgrade` — update the ESP32 platform and firmware libraries.
- `mise run clean` — remove build artifacts (`.pio/`).

## After flashing — verify on hardware

The compiler can't confirm these; check them the first time you flash real hardware:

- **Matrix orientation.** Mirrored or rotated output → adjust the `NEO_MATRIX_*`
  flags in `src/main.cpp`.
- **Data pin.** `MATRIX_PIN` defaults to the Ulanzi TC001's GPIO 32.
- **Text fit.** Up to 4 characters fit beside the icon; longer values clip.
- **Offline glyph.** Pull the network or point `API_URL` at a dead host and
  confirm the amber alert replaces the screens after `staleAfter`.

## Prerequisite

`src/secrets.h` must exist (copy from `src/secrets.example.h`). Without it the
build fails on a missing include — that's expected, not a bug.
