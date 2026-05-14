# zellij

Zellij configuration. Text files are tracked here as-is; binary
plugins need a one-time manual install.

## Plugin binaries

Zellij does **not** download plugins referenced by `file:` URLs in
`config.kdl` or `layouts/*.kdl` — they must already exist on disk
when zellij starts, or the layout will fail to load.

| File | Tracked? | Notes |
|---|---|---|
| `plugins/zjstatus.wasm` | yes | committed for convenience |
| `plugins/zjstatus-hints.wasm` | no (gitignored) | install manually before first run |

### Installing `zjstatus-hints`

Renders the per-mode keybind hint strip in the status bar (consumed
by `{pipe_zjstatus_hints}` in `layouts/default.kdl`).

1. Download the latest `zjstatus-hints.wasm` release from its
   upstream repository.
2. Place it at `zellij/plugins/zjstatus-hints.wasm` (the path
   referenced by the `plugins { ... }` block in `config.kdl`).
3. Restart zellij.

If the binary is missing, zellij will log a load error for the
`zjstatus-hints` plugin and the status bar hints area will be empty;
everything else will keep working.
