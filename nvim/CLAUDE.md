# Neovim config — orientation for Claude Code

A modular, power-user-shaped configuration. The layout exists so any
change is small, local, and easy to roll back. Preserve that property.

## Layout

`init.lua` is a launcher; never put logic there. Editor behavior
(options, keymaps not tied to a plugin, autocmds) lives in
`lua/config/`. Each plugin gets its own file in `lua/plugins/`
returning a lazy.nvim spec. The filename describes the plugin's
purpose (`diffview.lua`), not the upstream repo name. Plugin-specific
keymaps belong in the plugin's file, not in the global keymaps file.

## When extending

Adding a plugin → new file in `lua/plugins/`. Lazy-load when sensible
(`event`, `cmd`, `ft`, `keys`). Set keymaps via the spec's `keys`
field when you can — it defers the plugin's load until the key fires.

Changing settings → editor-wide goes in `lua/config/`, plugin-specific
goes in the plugin's file. Never `init.lua`.

LSP uses the Neovim 0.11+ native API (`vim.lsp.config` /
`vim.lsp.enable`). Do not reintroduce `require('lspconfig').setup{}`.
Servers are installed by mason-tool-installer (`ensure_installed`
list in `lua/plugins/lsp.lua`).

Formatting goes through conform.nvim — add new filetypes to
`formatters_by_ft` in `lua/plugins/formatting.lua`. Lockfiles
(`*.lock`, `*-lock.json`) are skipped automatically; preserve that.

## Style

No tutorial comments — comments only when the *why* is non-obvious.
No backwards-compat shims; migrate forward, delete the old. Leader is
space. `<C-h>` / `<C-l>` are reserved for window navigation; if a
plugin binds them, disable those keys in its config.

## Pinned versions

- **nvim-treesitter is pinned to `branch = "main"`.** The previous
  `master` branch was archived in April 2026 and is not compatible
  with Neovim 0.12+. The main branch is a full rewrite with an
  incompatible API: no `nvim-treesitter.configs`, no `ensure_installed`,
  no lazy-load triggers (must be `lazy = false`). Parsers install via
  `require("nvim-treesitter").install({...})` and highlight is enabled
  per-FileType via `vim.treesitter.start()`.
- **blink.cmp is pinned to `version = "1.*"`** (currently the latest
  stable, `v1.10.2`). The `main` branch is in-progress v2 work — no v2
  tag yet. When v2.0.0 ships, switch to `"2.*"` and add `saghen/blink.lib`
  as a dependency (see upstream `UPGRADE.md` for the full diff).

## Repository

This directory lives inside the user's dotfiles repo at `~/.config/`
(`github.com:talmage89/dotfiles.git`). Commit and push after a
working change. Commit messages use lowercase conventional commits
scoped as `(nvim)`. `lazy-lock.json` is tracked — commit changes to
it alongside plugin additions or upgrades.
