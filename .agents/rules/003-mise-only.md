# Rule: mise for tasks, never raw pio

Build, flash, and monitor go through `mise` — `mise run build`, `mise run upload`,
`mise run monitor`, `mise run clean`. Tasks are file-based scripts in
`.config/mise/tasks/`; never define tasks inline in `mise.toml`. When documenting
or scripting, reference the `mise run …` form, not `pio …` directly.
