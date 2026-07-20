# Watchlight

A watchful light for a 32×8 pixel display. It polls a JSON endpoint, rotates
through the screens it returns, and lights an alert when it can no longer reach
fresh data.

The name **Watchlight** captures the device's one job and the rule it never breaks:
keep watch over the data and, the moment it can't see anything fresh, light an
alert rather than show a stale number wearing a fresh face.

Watchlight is **content-agnostic**: it knows nothing about the *business* it shows.
Every server screen arrives fully formed — text, color, and an 8×8 icon bitmap —
so adding, removing, or restyling one is a server change, never a reflash. The
firmware's only opinions are *how to draw* and *when to admit it's offline*.

The one exception is a few **local screens** for data no server could provide —
the on-board clock, the temperature/humidity sensor, and a low-battery warning.
They ride in the same rotation (see [Local screens](#local-screens)).

Target hardware is the **Ulanzi TC001** (ESP32 + WS2812B matrix), but any ESP32
board with a compatible 32×8 matrix works by adjusting the pins in `main.cpp`.

## The contract

Watchlight expects `GET {API_URL}` (sent with an `x-device-token` header) to return:

```json
{
  "ts": 1784027753,
  "staleAfter": 1800,
  "rotateSeconds": 8,
  "screens": [
    { "id": "users", "text": "258k", "color": "#3b82f6", "icon": "<384 hex chars>" }
  ]
}
```

| field | meaning |
| :--- | :--- |
| `ts` | epoch seconds when the numbers were read (for the server; the firmware tracks its own last-success clock) |
| `staleAfter` | seconds of no successful fetch before the offline glyph replaces the screens |
| `rotateSeconds` | seconds each screen is shown before advancing |
| `screens[].text` | short string, pre-formatted for the display (`"258k"`, not `"258482"`) |
| `screens[].color` | `#rrggbb` text color |
| `screens[].icon` | 8×8 bitmap: 64 pixels × `rrggbb`, row-major, left→right, top→bottom (= 384 hex chars). `000000` is an off pixel. |

The device renders the icon on the left 8×8 and the text — a small pixel font —
**centered** in the remaining 24px. Icons may use full RGB: gradients and
anti-aliased edges render fine (the panel is RGB per pixel), so a soft-edged 8×8
looks the part. The firmware never interprets the values — a screen is just pixels.

**Why the bitmap travels in the payload:** so a new screen or icon is a server
deploy, never a firmware flash. At ~1.6 KB per poll it's a rounding error.

## Buttons

The three top-edge buttons drive navigation locally, without touching the server:

| button | action |
| :--- | :--- |
| left | previous screen |
| middle — single click | pause / resume auto-rotation |
| middle — double click | **standby** (panel off, still running) — press to wake |
| middle — hold ~5s | **deep sleep** (powers down to save battery) — press to wake |
| right | next screen |

Stepping left or right resets the rotation timer, so a manual move never fights an
auto-advance. A single click freezes the current screen; new data still fetches in
the background and the frozen screen refreshes in place.

**Standby vs. deep sleep.** A double click blanks the panel but keeps the device
running, so the next middle press wakes it instantly. Holding ~5s enters ESP32
deep sleep — a real power-down for battery life; the middle button wakes it, which
reboots (reconnect WiFi, re-sync the clock, ~2–4s). Either way a press turns it
back on.

The pins (left `26` / middle `27` / right `14`) match the TC001. The piezo buzzer
(`15`) is held low at boot so it stays quiet.

## Local screens

The device also renders a few screens from data it reads itself, so they work with
or without the server (and even offline). The hardware was confirmed with an I2C
scan: an **SHT3x** temp/humidity sensor at `0x44` and a **DS3231** RTC at `0x68`,
both on the I2C bus (`SDA 21` / `SCL 22`).

- **Clock** — a 9px-wide white calendar page with a red header and the
  day-of-month **cut out of the white** (dark digits on the page), then `HH:MM`
  (24h) to the right with a colon that **fades out and in** each second. The RTC
  keeps time across reboots; whenever WiFi is up the firmware calibrates it from
  **NTP**. Timezone and NTP servers live in `src/config.h` (default: São Paulo,
  UTC-3). Until the clock is set it shows dashes.
- **Temperature / humidity** — one panel showing **both at once**: a thermometer
  with the temperature (°C) and, beside it, the humidity (%RH).
- **Low battery** — appears only when the charge falls to **15% or less**: a gray
  battery whose red bar **breathes** (fades in and out), with the % beside it. It
  joins the rotation; and if rotation is paused, a low battery **forces** this
  screen to the front until the charge recovers. The battery is read on ADC pin
  `34` — the empty/full raw values in `main.cpp` need **calibrating on hardware**
  (`mise run monitor` prints `batt=NN% (adc XXXX)` to help).

Numbers on these screens use the same hand-drawn 3×5 digits, for a consistent
pixel-clock look. They sit after the server screens in the rotation and are
reachable with the left/right buttons like any other screen.

## The offline glyph

If the last successful fetch is older than `staleAfter` (or none has happened
yet), Watchlight drops the server screens from the rotation and shows an amber
warning triangle in their place. This is deliberate: a panel showing yesterday's
number with a fresh face is worse than one that admits it's blind. The local
screens (clock, temp/humidity) keep rotating — they're never stale.

## Setup

1. Copy `src/secrets.example.h` → `src/secrets.h` and fill in your WiFi
   networks, `API_URL`, and `API_TOKEN`. `secrets.h` is gitignored.
   Non-secret knobs (clock timezone, NTP servers) live in `src/config.h`, which
   *is* committed — edit it in place.
2. Build and flash — the task runner is [`mise`](https://mise.jdx.dev) (wrapping
   [PlatformIO](https://platformio.org)):
   ```bash
   mise run build     # compile
   mise run check     # static analysis (cppcheck)
   mise run lint      # format the firmware (clang-format)
   mise run upload    # build + flash over USB
   mise run monitor   # serial logs at 115200
   ```
   The upload uses `upload_speed = 115200` (higher rates were unreliable on the
   test adapter). If a flash drops mid-transfer, retry — it's usually the USB cable.
3. To revert to stock, reflash the Ulanzi firmware (keep a backup `.bin`).

`API_ROOT_CA` is optional. Empty = skip TLS validation (`setInsecure`), which is
fine on trusted WiFi but lets a machine on the same network read the token. Pin
the endpoint's root CA when the display lives on untrusted WiFi.

## Hardware notes

Confirmed on the Ulanzi TC001. On a different board, check these first:

- **Matrix.** 32×8 on `MATRIX_PIN = 32`, wired **serpentine** — the code uses
  `NEO_MATRIX_ZIGZAG`. With `PROGRESSIVE` a compact drawing splits into a left half
  and a mirrored right half (the tell-tale of the wrong flag).
- **Buttons / buzzer.** Left `26`, middle `27`, right `14` (active-low, internal
  pull-ups); piezo buzzer `15`, held low so it stays silent.
- **Sensors.** I2C `SDA 21` / `SCL 22`; SHT3x temp/humidity at `0x44`, DS3231 RTC
  at `0x68`.
- **Battery.** Read on ADC pin `34`; the empty/full raw values in `main.cpp` are a
  starting point — calibrate from `mise run monitor` (`batt=NN% (adc XXXX)`). The
  SHT3x reads a few degrees high from nearby self-heating.
- **Deep-sleep wake.** The middle button wakes the ESP32 from deep sleep via `ext0`
  on GPIO 27. If a press won't wake it, that's the pin to check.
- **Text fit.** With the small font, values up to ~8 characters fit centered in the
  24px text area; longer ones crop on the right.

The clock digits, calendar, thermometer, and the °/% marks are hand-drawn bitmaps
in `main.cpp` — tweak them there for a different look. `mise run monitor` prints
boot, WiFi, fetch, NTP, sensor, and button events for troubleshooting.

## References & links

**Hardware**

- [Ulanzi TC001](https://www.aliexpress.com/wholesale?SearchText=Ulanzi%20TC001) — the target 32×8 pixel-clock display (ESP32 + WS2812B), on AliExpress

**Tooling**

- [mise](https://mise.jdx.dev) — task runner and hermetic tool manager (`mise run …`)
- [PlatformIO](https://platformio.org) — build/flash/monitor toolchain for the ESP32

**Libraries** (see `platformio.ini`)

- [Adafruit NeoMatrix](https://github.com/adafruit/Adafruit_NeoMatrix) + [NeoPixel](https://github.com/adafruit/Adafruit_NeoPixel) — drive the 32×8 WS2812B matrix
- [Adafruit GFX](https://github.com/adafruit/Adafruit-GFX-Library) — text and graphics primitives (incl. the TomThumb font)
- [ArduinoJson](https://arduinojson.org) — streaming parse of the payload
- [RTClib](https://github.com/adafruit/RTClib) — DS3231 real-time clock
- [Adafruit SHT31](https://github.com/adafruit/Adafruit_SHT31) — SHT3x temperature/humidity sensor

**Icons**

- [LaMetric icon gallery](https://developer.lametric.com/icons) — the 8×8 icons the server sends (each has a numeric ID; the payload carries the RGB bitmap)
