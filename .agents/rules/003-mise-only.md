---
trigger: always_on
---

# Rule: mise for tasks, never raw pio

Build, check, format, flash, and monitor go through `mise` — `mise run build`,
`mise run check`, `mise run lint`, `mise run upload`, `mise run monitor`, and
`mise run clean`. Tasks are file-based scripts in `.config/mise/tasks/`; never
define tasks inline in `mise.toml`. When documenting or scripting, reference the
`mise run …` form, not `pio …` or `platformio …` directly.
