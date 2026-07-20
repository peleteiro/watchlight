---
trigger: always_on
---

# Rule: the display must never lie

Watchlight's core promise: it shows fresh data or it shows the offline glyph — never
a stale value dressed as current. When editing fetch, staleness, or render logic:

- keep the `staleAfter` check authoritative; if the last successful fetch is older
  than `staleAfter` (or none happened), draw the alert and nothing else,
- do not add "graceful" fallbacks to last-known values as if they were live,
- a screen only appears when its value came from a successful, recent fetch.

A blank/alerting panel is correct behavior, not a bug to paper over.
