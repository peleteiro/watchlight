// Copy this file to `src/secrets.h` and fill it in. `secrets.h` is gitignored —
// it holds credentials and must never be committed.
#pragma once

// WiFi networks the device may join, in priority order. On boot (and whenever it
// loses connection) Watchlight scans and joins the first one it can see. List every
// place the display travels to: home, office, wherever.
struct WifiNetwork {
  const char *ssid;
  const char *password;
};
static const WifiNetwork WIFI_NETWORKS[] = {
    {"my-home-wifi", "home-password"},
    {"my-office-wifi", "office-password"},
};

// The endpoint that returns the screens payload (see README for the contract).
// Must be HTTPS. The device is generic — this URL is where it points today.
#define API_URL "https://api.example.com/devices/watchlight"

// Sent as `Authorization: Bearer {API_TOKEN}`. Whoever holds it can read whatever
// the endpoint returns, so scope it read-only on the server side.
#define API_TOKEN "replace-with-your-token"

// Optional: PEM root CA to validate the endpoint's TLS certificate. Leave empty
// to skip validation (setInsecure) — simpler, but a machine on the same network
// could intercept the token. Prefer pinning the CA when the display lives on
// untrusted WiFi. Paste the root as a raw string literal:
//
//   #define API_ROOT_CA R"EOF(
//   -----BEGIN CERTIFICATE-----
//   ...
//   -----END CERTIFICATE-----
//   )EOF"
#define API_ROOT_CA ""

// Local hardware screens: the clock (DS3231 RTC) and the temperature/humidity
// panel (SHT3x). They live here rather than in config.h because they are a
// per-device choice — one unit sits next to a real clock and only needs the
// server screens, another is the clock. Set a flag to 0 to drop that screen from
// the rotation. The low-battery warning and the offline glyph are always shown.
#define SHOW_CLOCK_SCREEN 1
#define SHOW_TEMPHUM_SCREEN 1
