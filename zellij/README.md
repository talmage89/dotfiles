# zellij

Zellij configuration. Text files (`config.kdl`, layouts) are tracked
here as-is; plugin binaries are not (`plugins/` is gitignored).

## Plugin binaries

Zellij does **not** download plugins referenced by `file:` URLs in
`config.kdl` or `layouts/*.kdl` — they must already exist on disk
when zellij starts, or the layout will fail to load.

### `zjstatus.wasm`

Renders the status bar. Required by `config.kdl` and
`layouts/default.kdl`.

1. Download the latest `zjstatus.wasm` release from its upstream
   repository.
2. Place it at `zellij/plugins/zjstatus.wasm`.
3. Restart zellij.

If the binary is missing, zellij logs a load error and the status bar
stays empty; everything else keeps working.
