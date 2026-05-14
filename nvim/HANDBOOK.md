# Neovim handbook

A personal reference for this configuration. Written once, intended to age
slowly. Read top-to-bottom once; come back to specific sections as needed.

This document is opinionated about *your* setup — it references the actual
plugins and keymaps in `lua/plugins/`. When something here disagrees with
your config, your config is the source of truth.

---

## Table of contents

1. [How to read this](#how-to-read-this)
2. [The mental model](#the-mental-model)
3. [Daily survival kit](#daily-survival-kit)
4. [The vim grammar](#the-vim-grammar)
5. [Buffers, windows, tabs](#buffers-windows-tabs)
6. [Search and replace](#search-and-replace)
7. [The help system](#the-help-system)
8. [Lazy.nvim — the plugin manager](#lazynvim--the-plugin-manager)
9. [LSP — language intelligence](#lsp--language-intelligence)
10. [Treesitter — structural syntax](#treesitter--structural-syntax)
11. [Plugin-by-plugin reference](#plugin-by-plugin-reference)
12. [Core workflows](#core-workflows)
13. [Power features to grow into](#power-features-to-grow-into)
14. [Lua basics for configuration](#lua-basics-for-configuration)
15. [Getting unstuck](#getting-unstuck)
16. [Learning roadmap](#learning-roadmap)
17. [References](#references)

---

## How to read this

You don't need to internalize all of this. The minimum viable Neovim user
knows ~30 keystrokes and the rest is muscle memory accreted over months.
This document exists so when you hit "I know there's a thing for this,"
you can find it.

A few conventions:

- `<space>` = your leader key. Anywhere you see it in a chord, type the
  spacebar.
- `<CR>` = Enter / Return.
- `<C-x>` = Control + x. `<S-x>` = Shift + x. `<M-x>` = Alt/Meta + x.
- `:foo` = a command — type colon, then `foo`, then Enter.
- Keymaps shown without modifier (like `dd` or `gg`) are pressed in
  normal mode, in sequence.

---

## The mental model

Neovim is built around a different premise than most editors: editing is
a *language*, not a series of clicks. The keys you type form sentences
that operate on text. Once the grammar clicks (it takes weeks, not days),
text manipulation becomes faster than thinking about what you want to do.

### Modes

Neovim has several modes. The one you're in determines what your keys do.

| Mode | How you enter it | What it's for |
|---|---|---|
| **Normal** | Default; press `<Esc>` from anywhere | Navigate and run editing commands. You spend most of your time here. |
| **Insert** | `i`, `a`, `o`, `I`, `A`, `O`, `s`, `S`, `c<motion>` | Type literal text. Same as any text editor. |
| **Visual** | `v` (chars), `V` (lines), `<C-v>` (block) | Select text. Then operate on the selection. |
| **Command-line** | `:`, `/`, `?` | Run an Ex command or search. |
| **Operator-pending** | After typing an operator like `d`, `c`, `y` | Waiting for a motion or text object. |
| **Replace** | `R` (continuous), `r<char>` (single) | Overwrite instead of insert. Rarely needed. |
| **Terminal** | Inside `:terminal`, `i` to type | Interactive shell. `<C-\><C-n>` returns to normal mode. |

The single most important thing: **return to normal mode often.** Don't
stay in insert mode any longer than the literal characters you're typing.
A common beginner mistake is treating insert mode like a normal editor and
arrow-keying around. Press `<Esc>` (or `jk` if you map it later), navigate
in normal mode, then `i` to type again. The cost of leaving insert mode is
near-zero; the gain is everything vim offers.

### The window of attention

What you see on screen is one or more **windows**. Each window displays
a **buffer**, which is the in-memory representation of a file (or a
scratch). One buffer can be shown in zero, one, or many windows
simultaneously. **Tabs** are groups of windows — like virtual desktops.

The mental flip from VSCode: a "tab" in VSCode is a buffer in Neovim. A
"tab" in Neovim is a workspace layout. Most users barely use Neovim tabs;
they switch between buffers in a single window or split layout.

---

## Daily survival kit

The 30-ish keystrokes you need on day one.

### Moving the cursor

| Keys | Move to |
|---|---|
| `h` `j` `k` `l` | Left, down, up, right (one char) |
| `w` | Start of next word |
| `b` | Start of previous word |
| `e` | End of next word |
| `0` | Start of line |
| `^` | First non-blank on line |
| `$` | End of line |
| `gg` | Top of file |
| `G` | Bottom of file |
| `<number>G` | Line number |
| `<C-d>` | Half-page down |
| `<C-u>` | Half-page up |
| `<C-f>` | Full page down |
| `<C-b>` | Full page up |
| `zz` | Center current line on screen |
| `zt` | Current line to top of screen |
| `zb` | Current line to bottom of screen |
| `%` | Jump to matching bracket/paren |
| `f<char>` | Forward to next `<char>` on this line |
| `F<char>` | Backward to previous `<char>` on this line |
| `;` | Repeat last `f`/`F` |
| `,` | Repeat last `f`/`F`, opposite direction |

### Entering insert mode

| Keys | Effect |
|---|---|
| `i` | Insert before cursor |
| `a` | Insert after cursor (append) |
| `I` | Insert at first non-blank of line |
| `A` | Insert at end of line |
| `o` | Open a new line below, enter insert mode |
| `O` | Open a new line above, enter insert mode |
| `s` | Delete char under cursor and enter insert mode |
| `S` | Delete line and enter insert mode |
| `c<motion>` | Change (delete + insert) the range of `<motion>` |

### Editing

| Keys | Effect |
|---|---|
| `x` | Delete character under cursor |
| `dd` | Delete (cut) line |
| `yy` | Yank (copy) line |
| `p` | Paste after cursor |
| `P` | Paste before cursor |
| `u` | Undo |
| `<C-r>` | Redo |
| `.` | Repeat last edit (extremely powerful — see [power features](#power-features-to-grow-into)) |
| `J` | Join current line with next (no newline) |
| `~` | Toggle case of character under cursor |

### Saving and quitting

| Command | Effect |
|---|---|
| `:w` | Save current buffer |
| `:w <path>` | Save as new file |
| `:q` | Quit current window (fails if unsaved changes) |
| `:q!` | Quit, discarding changes |
| `:wq` or `:x` or `ZZ` | Save and quit |
| `:wa` | Save all buffers |
| `:qa` | Quit all (fails if any unsaved) |
| `:qa!` | Force quit all |
| `<space>w` | Save (your keymap; `lua/config/keymaps.lua`) |
| `<space>q` | Quit window (your keymap) |
| `<space>Q` | Quit all (your keymap) |

> **Practical exercise**: open `~/.config/nvim/init.lua`, navigate around
> using only the keys above for 10 minutes. No arrow keys, no mouse.

---

## The vim grammar

The thing that makes vim *vim*. Once this clicks, you write text
manipulations like English sentences.

### The sentence: verb + motion

Every editing command is a **verb** followed by what to operate on.
The "what" is either a **motion** (move from here to there) or a **text
object** (a structural region).

```
<count> <verb> <motion-or-text-object>
```

Verbs you use constantly:

| Verb | Meaning |
|---|---|
| `d` | Delete (cut) |
| `c` | Change (delete + enter insert mode) |
| `y` | Yank (copy) |
| `v` | Select (start visual mode) |
| `>` | Indent right |
| `<` | Indent left |
| `=` | Auto-indent / format |
| `gu` | Lowercase |
| `gU` | Uppercase |
| `g~` | Toggle case |

Motions are anything that moves the cursor — every entry in the
"Moving the cursor" table above is a motion.

### Examples

Read these as English:

| Sentence | Meaning |
|---|---|
| `dw` | "Delete word" (delete from cursor to start of next word) |
| `d$` | "Delete to end of line" |
| `c2w` | "Change two words" |
| `y0` | "Yank to start of line" |
| `>5j` | "Indent five lines down" |
| `gUiw` | "Uppercase the word I'm on" |

The doubled-letter shortcut (`dd`, `yy`, `cc`, `>>`) means "operate on
the whole line." So `dd` = delete line, `yy` = yank line, etc.

### Text objects

Text objects describe **structural** regions: a word, a quoted string,
a function body, a HTML tag. Always two-letter pairs:

- `i<X>` = "inner X" (the content, excluding delimiters)
- `a<X>` = "a X" or "around X" (the content + delimiters)

| Object | Meaning |
|---|---|
| `iw` / `aw` | word |
| `iW` / `aW` | WORD (whitespace-separated, includes punctuation) |
| `i"` / `a"` | double-quoted string |
| `i'` / `a'` | single-quoted string |
| `` i` `` / `` a` `` | backtick string |
| `i(` / `a(` (also `ib` / `ab`) | parentheses |
| `i{` / `a{` (also `iB` / `aB`) | braces |
| `i[` / `a[` | brackets |
| `i<` / `a<` | angle brackets |
| `it` / `at` | HTML/XML tag |
| `ip` / `ap` | paragraph |
| `is` / `as` | sentence |
| `ih` / `ah` | hunk (from gitsigns) |

Combine with verbs:

| Sentence | Meaning |
|---|---|
| `daw` | Delete a word (with surrounding whitespace) |
| `ciw` | Change inner word |
| `ci"` | Change inside the double quotes (cursor anywhere on the string) |
| `dap` | Delete a paragraph |
| `yi(` | Yank inside parens (cursor anywhere inside them) |
| `vit` | Visually select inside the HTML tag |
| `dih` | Delete the current git hunk |

**This is where vim becomes powerful.** "Change the contents of these
parens" is `ci(` — three keystrokes, regardless of where your cursor is
inside the parens.

### Visual mode is a different sentence

In visual mode you select first, then apply a verb. So `viwd` does the
same thing as `diw`. Visual mode is useful when you want to *see* the
selection before acting, or when the operation isn't a single verb.

`gv` re-selects the last visual selection. Comes in handy.

### Counts

Almost any command takes a count prefix:

| Sentence | Meaning |
|---|---|
| `5j` | Move down 5 lines |
| `3dw` | Delete 3 words |
| `2dd` | Delete 2 lines |
| `5>>` | Indent 5 lines |
| `100G` | Go to line 100 |

### The dot command (`.`)

`.` repeats the last *edit*. Combined with movement, this is a poor
person's macro:

1. Make an edit somewhere (e.g., `cw newname<Esc>`).
2. Move to another place where you want the same edit.
3. Press `.` to apply.

It's why you should make small, repeatable edits instead of grand multi-
step changes. The dot command is the soul of efficient editing.

---

## Buffers, windows, tabs

Three distinct concepts. Confusion between them is universal at the
start.

```
A tab is a layout.
   A tab contains one or more windows.
       A window is a viewport.
           A window displays one buffer at a time.
A buffer is the in-memory text of a file.
   A buffer exists independently of any window.
```

Most editing sessions have **one tab, several windows, many buffers**.

### Buffers (your "open files")

| Command | Effect |
|---|---|
| `:e <path>` | Open a file into a new buffer |
| `:ls` or `:buffers` | List all buffers |
| `:b <number>` | Switch to buffer by number |
| `:b <partial-name>` | Switch by name (tab-completes) |
| `:bd` | Delete (close) current buffer |
| `:bn` / `:bp` | Next / previous buffer |
| `<C-^>` | Switch to the alternate (most recent other) buffer |
| `<space>fb` | Fuzzy-pick a buffer (snacks.picker) |
| `<space>bn` / `<space>bp` | Next/prev buffer (your keymap) |
| `<space>bd` | Delete buffer (your keymap) |

The picker (`<space>fb`) is the daily-driver way to switch.

### Windows (splits)

| Command | Effect |
|---|---|
| `:split` or `:sp` or `<C-w>s` | Horizontal split (same buffer) |
| `:vsplit` or `:vsp` or `<C-w>v` | Vertical split (same buffer) |
| `:new` | Horizontal split with new empty buffer |
| `:vnew` | Vertical split with new empty buffer |
| `<C-w>h/j/k/l` | Move to window left/down/up/right |
| `<C-h/j/k/l>` | Same (your keymap shortcut) |
| `<C-w>c` or `:close` | Close current window |
| `<C-w>o` | Close all other windows |
| `<C-w>=` | Equalize window sizes |
| `<C-w>_` | Maximize current window height |
| `<C-w>|` | Maximize current window width |
| `<C-w>r` | Rotate windows |
| `<C-w>T` | Move current window to its own tab |

Two windows can show two different buffers — or the same buffer at
different positions (`:sp` keeps the same buffer; useful for working on
two parts of one file).

### Tabs

| Command | Effect |
|---|---|
| `:tabnew` | New empty tab |
| `:tabedit <path>` | New tab with a file |
| `:tabclose` | Close current tab |
| `gt` | Next tab |
| `gT` | Previous tab |
| `<number>gt` | Go to tab N |

Most users rarely use tabs. Splits in a single tab cover most needs.

---

## Search and replace

### Searching

| Keys | Effect |
|---|---|
| `/<pattern><CR>` | Search forward for pattern |
| `?<pattern><CR>` | Search backward |
| `n` | Next match (centered on screen by your keymap) |
| `N` | Previous match (centered) |
| `*` | Search for word under cursor (forward) |
| `#` | Search for word under cursor (backward) |
| `<space>fg` | Workspace grep (snacks.picker) |
| `<space>fw` | Workspace grep for word under cursor |
| `<space>f/` | Grep inside current buffer |
| `<Esc>` | Clear search highlights (your keymap) |

Patterns are vim's regex flavor. Use `\v` at the start to switch to
"very magic" mode where regex looks more like PCRE: `/\v(foo|bar)`.

### Substituting

The `:s` command. Standard form:

```
:[range]s/pattern/replacement/flags
```

| Command | Effect |
|---|---|
| `:s/foo/bar/` | Replace first `foo` with `bar` on current line |
| `:s/foo/bar/g` | Replace all on current line |
| `:%s/foo/bar/g` | Replace all in current buffer |
| `:%s/foo/bar/gc` | Same but confirm each |
| `:'<,'>s/foo/bar/g` | Replace within visual selection |
| `:%s/\v(\w+)@(\w+)/\2_\1/g` | Capture groups: swap username and domain |

`inccommand = "split"` (set in `options.lua`) gives you a live preview
window while you type the substitution.

### Multi-file replace

1. `<space>fw` (or `<space>fg`) to grep the term across the workspace.
2. In the picker, send results to the quickfix list: `<C-q>` or
   `<tab>` to multi-select then enter.
3. `:cdo s/foo/bar/g | update` — runs the substitution on every entry
   in the quickfix and saves.

Alternative for big renames: use LSP `<space>rn` — it understands
syntax and only renames symbols, not text matches.

---

## The help system

Neovim's docs are inside the editor. `:help` is the single most valuable
command you'll learn.

| Command | Effect |
|---|---|
| `:help` | Open the help index |
| `:help <topic>` | Help on a specific topic |
| `:help :w` | Help on the `:w` command |
| `:help i_<C-r>` | Help on `<C-r>` in insert mode (note the prefix) |
| `:help motion.txt` | The motion overview file |
| `K` (in normal mode on a Lua identifier) | LSP hover (also opens help for known identifiers) |
| `<space>fh` | Fuzzy-search help tags (snacks.picker) |
| `<C-]>` | Follow a help-tag link |
| `<C-t>` | Jump back from a help-tag |
| `<C-o>` / `<C-i>` | Older / newer position in the jump list (works in help too) |

Help is namespaced by mode:

- `:help dd` — normal mode `dd`
- `:help i_<C-w>` — insert mode `<C-w>`
- `:help v_d` — visual mode `d`
- `:help c_<C-r>` — command-line mode `<C-r>`
- `:help :<command>` — Ex command

When you're confused about anything, `:help <thing>` first. The answer
is almost always there.

---

## Lazy.nvim — the plugin manager

Plugins in Neovim are downloaded Lua/Vimscript code. Lazy.nvim (the
`folke/lazy.nvim` plugin) handles fetching, loading, updating, and
managing the lifecycle of every plugin in your config.

### Mental model

Each file in `lua/plugins/` returns a **plugin spec** — a Lua table
describing one or more plugins. Lazy reads them all on startup, builds
a dependency graph, and lazy-loads each plugin according to its trigger.

A minimal spec:

```lua
return {
  "owner/repo-name",
  event = "BufReadPost",
  opts = { foo = true },
}
```

The string is the GitHub `user/repo`. `event` tells lazy: "don't load
this plugin until the `BufReadPost` autocmd fires." `opts` is passed to
the plugin's `setup()` function automatically.

### Spec keys you'll see

| Key | Meaning |
|---|---|
| `"user/repo"` (1st positional) | The plugin source |
| `event` | Lazy-load on a vim autocmd (e.g., `BufReadPost`, `InsertEnter`) |
| `cmd` | Lazy-load when a command is invoked |
| `ft` | Lazy-load when a filetype is detected |
| `keys` | Lazy-load when a keymap is pressed; also defines that keymap |
| `dependencies` | Plugins that must load first |
| `opts` | Table merged into the plugin's `setup()` |
| `config = function() ... end` | Custom setup logic (instead of opts) |
| `init = function() ... end` | Runs before the plugin loads (always) |
| `lazy = false` | Force load on startup |
| `priority` | Higher = loads earlier (use for colorscheme: 1000) |
| `version` / `branch` / `commit` / `tag` | Pin to a specific reference |
| `build` | Command to run after install/update (e.g., `:TSUpdate`) |

### Common commands

| Command | Effect |
|---|---|
| `:Lazy` | Open the lazy UI — install / update / clean / etc. |
| `:Lazy sync` | Install missing + update existing |
| `:Lazy update` | Update all plugins |
| `:Lazy install` | Install missing plugins only |
| `:Lazy clean` | Remove plugins not in your spec |
| `:Lazy restore` | Restore plugins to the versions in `lazy-lock.json` |
| `:Lazy log` | View update log per plugin |
| `:Lazy reload <name>` | Re-load a single plugin (after editing its config) |
| `:Lazy profile` | See startup-time profile (find slow plugins) |

### The lock file

`lazy-lock.json` records the exact commit hash of every plugin. When
you sync your config across machines (or roll back), `:Lazy restore`
brings every plugin to those exact versions. Commit it to git
alongside plugin changes.

### How lazy-loading works

Most plugins shouldn't load on startup — they should load only when
needed. Three useful patterns:

1. **`event = "BufReadPre"`** — Load before reading a file buffer. Good
   for plugins that decorate buffers (gitsigns, treesitter).
2. **`cmd = "DiffviewOpen"`** — Load when you run `:DiffviewOpen` for
   the first time. Good for plugins you invoke explicitly.
3. **`keys = { "<leader>ff", ... }`** — Load when you press the keymap.
   The keymap is registered immediately; the plugin loads on first
   press.

Colorscheme is an exception: it should load on startup (`lazy = false`,
`priority = 1000`) so there's no flash of unstyled content.

### Updating safely

```
:Lazy update
```

If anything breaks after the update:

```
:Lazy restore       " roll back to lazy-lock.json
```

Then `git diff lazy-lock.json` to see exactly what changed, and
`:Lazy update <plugin>` to update individual plugins one at a time
to find the culprit.

---

## LSP — language intelligence

LSP (Language Server Protocol) is the standard that powers
go-to-definition, hover docs, rename, code actions, and diagnostics in
every modern editor. VSCode, Neovim, Helix, JetBrains — they all speak
LSP to the same language servers.

### Mental model

```
                  Language server (e.g., vtsls)
                   |
        LSP protocol (JSON-RPC over stdio)
                   |
   Neovim's built-in LSP client
                   |
   Your config:  vim.lsp.config + vim.lsp.enable
                   |
              Your keymaps (gd, K, gr, ...)
```

The language server is a separate process — for TypeScript that's
`vtsls`, a Node.js process. It parses your project, answers questions
about it, and notifies Neovim of diagnostics. Neovim's LSP client
sends requests and renders the responses.

### What runs in your config

Installed via mason.nvim (which is just a package manager for editor
tools — LSP servers, formatters, linters, debuggers):

| Server | What it serves |
|---|---|
| `vtsls` | TypeScript / TSX / JS / JSX |
| `lua_ls` | Lua (your config files) |
| `jsonls` | JSON / JSONC |
| `bashls` | Bash scripts |
| `marksman` | Markdown |

Mason installs the binaries to `~/.local/share/nvim/mason/bin/` and
those become available to Neovim. Run `:Mason` for the UI; in there,
`i` to install, `u` to update, `X` to uninstall.

### The keymaps (defined in `lua/plugins/lsp.lua`)

| Keys | Effect |
|---|---|
| `gd` | Go to definition (jump-to-def) |
| `gD` | Go to declaration (usually = definition in JS) |
| `gr` | List references (where is this symbol used?) |
| `gi` | Go to implementation (for interfaces) |
| `gy` | Go to type definition |
| `K` | Hover docs in a floating window |
| `<space>rn` | Rename symbol (across all files) |
| `<space>ca` | Show available code actions |
| `<space>e` | Open floating diagnostic for current line |
| `[d` / `]d` | Previous / next diagnostic |
| `<space>ih` | Toggle inlay hints in current buffer |
| `<space>fs` | Workspace symbols (search all symbols in project) |
| `<space>fS` | Document symbols (current file's symbols) |
| `<space>fd` | Workspace diagnostics in a picker |

### Hover (`K`) is the most underused

When you don't know what something is, put your cursor on it and press
`K`. You get a popup with:

- Type signature
- Documentation
- Source link

Press `K` again to enter the popup (then `q` to leave). It's how you
explore unfamiliar code.

### Code actions (`<space>ca`)

The language server suggests refactorings: "add missing import,"
"convert to named export," "extract function," etc. Available actions
depend on what's at the cursor. Press `<space>ca`, pick from the menu.

### Rename (`<space>rn`)

A semantic rename, not text-find-and-replace. Renames the symbol you're
on across every file in the project where it's used. Skips strings and
comments. Much safer than `:%s/old/new/g`.

### vtsls specifics

vtsls is a community fork of `typescript-language-server` with better
completion, smarter import handling, and richer configuration. Your
config (in `lua/plugins/lsp.lua`) enables:

- `importModuleSpecifier = "non-relative"` — auto-imports use the `~/`
  alias instead of `../../../`.
- All inlay hints (parameter names, return types, etc.).
- Server-side fuzzy completion matching.
- Auto-update imports when files move.

You can also run vtsls-specific commands via `<space>ca`:

- "Sort imports"
- "Add missing imports"
- "Remove unused imports"
- "Organize imports"

### Diagnostics

Diagnostics are warnings and errors. They show up:

- In the sign column (the symbols `✘`, `▲`, `⚑`, `»`)
- Inline as virtual text (the `●` marker)
- In a float on `<space>e`
- In the picker via `<space>fd`

`[d` and `]d` jump between them.

---

## Treesitter — structural syntax

Treesitter parses your code into a **syntax tree** in real time. Unlike
regex-based syntax highlighting, treesitter knows the structure of your
code — what's a function, what's a string, what's a comment. This
powers:

1. **Accurate syntax highlighting.** No more mis-colored strings.
2. **Structural text objects.** `i.` `a.` and language-aware navigation.
3. **Folding by structure.**
4. **Incremental selection** — grow your selection by syntactic node.

### Mental model

Each language gets a **parser** (a compiled C library) and **queries**
(rules that say "this AST node is a function name", "this is a string
literal", etc.). Both are managed by `nvim-treesitter`.

Run `:TSUpdate` after upgrading parsers. Run `:checkhealth nvim-treesitter`
to see what's installed.

### What runs in your config

`lua/plugins/treesitter.lua` ensures parsers for: typescript, tsx,
javascript, json, jsonc, markdown, bash, lua, vim, vimdoc, diff,
gitcommit, gitignore, yaml, toml, regex, xml, html, css, and more.

Adding a language: edit the `ensure_installed` list, save, run
`:TSUpdate`.

### Two key behaviors

1. **`auto_install = true`** — when you open a file in a language not
   yet parsed, treesitter downloads and compiles its parser on the fly.
2. **`highlight = true`** — enables treesitter-based highlighting
   (the default).

> **Pinned to `branch = "master"`** — the default `main` branch has a
> totally different API. Don't remove the `branch = "master"` line in
> the plugin spec.

---

## Plugin-by-plugin reference

Every plugin in your setup, what it does, and its keymaps. Each one
lives in its own file under `lua/plugins/`.

### colorscheme.lua — kanagawa.nvim

A dark Japanese-inspired colorscheme. You're on the "dragon" variant
(darkest). Three variants exist:

- `kanagawa-wave` — default, navy-toned
- `kanagawa-dragon` — your current; very dark, warm accents
- `kanagawa-lotus` — light theme

Switch with `:colorscheme kanagawa-wave` (temporary) or by editing the
plugin file (permanent).

### completion.lua — blink.cmp

The autocomplete engine. As you type, it shows a popup with suggestions
from multiple sources: LSP, snippets, current buffer, file paths.

Keys (inside the popup):

| Keys | Effect |
|---|---|
| `<C-n>` / `<Down>` | Next item |
| `<C-p>` / `<Up>` | Previous item |
| `<CR>` | Accept selected item |
| `<C-Space>` | Manually trigger menu (useful where auto-show is off) |
| `<Esc>` | Dismiss |
| `<C-d>` / `<C-u>` | Scroll docs |

Signature help (the popup showing function args while you're inside a
call) appears automatically and follows the same display.

Auto-show is disabled for markdown so the menu doesn't intrude on prose.
Manual trigger (`<C-Space>`) still works there.

> **Pinned to `version = "1.*"`** — v2 is breaking.

### formatting.lua — conform.nvim

Format-on-save engine. Formatters by filetype:

| Filetype | Formatters (run in order) |
|---|---|
| `typescript`, `typescriptreact`, `javascript`, `javascriptreact` | `eslint_d` → `prettierd` |
| `json`, `jsonc`, `markdown`, `yaml`, `html`, `css` | `prettierd` |
| `lua` | `stylua` |

On `:w`, conform runs the formatter chain. ESLint auto-fixes first,
then prettier reflows. Daemon variants (`eslint_d`, `prettierd`) are
used for speed — they keep a long-running process so each save is
near-instant.

Manual / control:

| Keys | Effect |
|---|---|
| `<space>cf` | Format buffer or visual selection manually |
| `<space>cF` | Toggle format-on-save globally for this session |

Format-on-save skips `*.lock` and `*-lock.json` so prettier doesn't
choke on lockfiles.

To add a filetype: edit `formatters_by_ft` in the file.

### lsp.lua — Neovim LSP + mason

Covered in the [LSP section](#lsp--language-intelligence) above.

### treesitter.lua

Covered in the [Treesitter section](#treesitter--structural-syntax).

### diffview.nvim

The killer feature for your workflow — full git diff browser inside
Neovim, with LSP active on the new-side pane.

| Keys | Effect |
|---|---|
| `<space>gd` | Open working-tree diff |
| `<space>gm` | Branch diff: `origin/main...HEAD` (your MR's full diff) |
| `<space>gM` | Branch diff: `origin/master...HEAD` |
| `<space>gh` | File history (current file) |
| `<space>gH` | File history (entire branch) |
| `<space>gD` | Close diffview |

Inside diffview:

| Keys | Effect |
|---|---|
| `Tab` | Toggle the file panel |
| `j` / `k` | Move between files in the file panel |
| `<CR>` | Open the selected file in the diff view |
| `q` | Close diffview |

On the new-side (right) pane, full LSP is active. `gd`, `gr`, `K`,
`<space>ca` all work. The old-side (left) pane is a read-only git-blob
buffer; LSP can't attach there because the file isn't on disk.

For merge conflict resolution, diffview opens in a 3-way layout
automatically when you have conflicts. See "Merge conflicts" in
[workflows](#core-workflows).

### gitsigns.nvim

In-buffer git status — sign-column markers for added/changed/deleted
lines, plus hunk-level operations.

| Keys | Effect |
|---|---|
| `]c` / `[c` | Next / previous hunk in current buffer |
| `<space>hp` | Preview hunk inline |
| `<space>hs` | Stage / unstage hunk (toggle) |
| `<space>hr` | Reset hunk to HEAD |
| `<space>hS` | Stage all hunks in buffer |
| `<space>hR` | Reset all hunks in buffer |
| `<space>hd` | Diff this buffer in a split |
| `<space>hb` | Show full git blame for current line |
| `<space>tb` | Toggle inline blame for all lines |
| `<space>td` | Toggle "show deleted lines inline" |

Text object:

- `ih` (in/around hunk) — usable with any verb. `dih` = delete hunk,
  `vih` = select hunk.

### git-conflict.nvim

Activates automatically when a buffer has `<<<<<<<` conflict markers.

| Keys | Effect |
|---|---|
| `co` | Choose ours |
| `ct` | Choose theirs |
| `cb` | Choose both |
| `c0` | Choose none |
| `]x` / `[x` | Next / previous conflict |
| `<space>gx` | List all conflicts in the quickfix list |

### picker.lua — snacks.nvim

The fuzzy finder. Replaces "where is that file" and "where is this
string" and "where is this symbol."

| Keys | Effect |
|---|---|
| `<space>ff` | Find files |
| `<space>fF` | Find files (including hidden + ignored) |
| `<space>fr` | Recent files |
| `<space>fb` | Buffers |
| `<space>fg` | Grep workspace (live) |
| `<space>fw` | Grep word under cursor (also works in visual) |
| `<space>f/` | Grep inside current buffer |
| `<space>fs` | Workspace LSP symbols |
| `<space>fS` | Document LSP symbols |
| `<space>fh` | Help tags |
| `<space>fd` | Workspace diagnostics |
| `<space>fk` | Keymaps (great for learning) |
| `<space>fc` | Command history |
| `<space>fp` | Picker of pickers (forgot which one?) |
| `<space>fR` | Resume the last picker |

Inside any picker:

| Keys | Effect |
|---|---|
| `<C-n>` / `<C-p>` | Next / previous result |
| `<CR>` | Open selected |
| `<C-s>` | Open in horizontal split |
| `<C-v>` | Open in vertical split |
| `<C-t>` | Open in new tab |
| `<Tab>` | Multi-select (toggles) |
| `<C-q>` | Send results to quickfix list |
| `<Esc>` | Close picker |

snacks.nvim is actually a bundle of utilities by folke; you only have
the `picker` and a couple of low-overhead helpers enabled.

### explorer.lua — oil.nvim

Filesystem as a buffer. Cover earlier in your handbook journey;
recapping the keys:

| Keys | Effect |
|---|---|
| `-` | Open parent directory as an editable buffer |
| `<space>-` | Open oil in a floating window |

Inside an oil buffer:

| Keys | Effect |
|---|---|
| `<CR>` | Open file under cursor / descend into directory |
| `-` | Go up one directory |
| `_` | Go to current working directory |
| `` ` `` | `:cd` to the directory shown in this oil buffer |
| `<C-p>` | Preview file under cursor in a floating window |
| `<C-c>` | Close oil |
| `<C-s>` | Open file in vertical split |
| `g?` | Show help / cheatsheet |
| `g.` | Toggle showing hidden files |
| `g\` | Toggle trash view |
| `gs` | Change sort order |
| `gx` | Open with system handler (e.g., images in default app) |

To edit: just edit the buffer text. Each operation becomes a change:

- Delete a line (`dd`) → delete that file
- Change a line (`cw` or `R`) → rename
- Type a new line with a name → create file
- Append `/` to a name → create directory
- Yank/paste a line → copy a file

Press `:w` to commit. You'll see a confirmation showing every change
that will be applied.

### ui.lua — lualine + which-key

**lualine.nvim** — the status line at the bottom showing mode, branch,
diff, diagnostics, filename, filetype, position, percentage. No
keymaps; just visual.

**which-key.nvim** — the popup that appears 300ms after pressing
`<space>` (or any prefix key), showing what keys are bound to what.
Critical learning aid. Press `<space>` and wait to see all available
leader keymaps grouped by description.

| Keys | Effect |
|---|---|
| `<space>?` | Show keymaps for the current buffer (local) |

### lazydev.nvim

A Lua-only helper. When editing files in `~/.config/nvim/`, lazydev
configures `lua_ls` to know about Neovim's runtime APIs (`vim.api.*`,
`vim.lsp.*`, etc.). You get completion and docs for them. No keymaps;
it just works.

---

## Core workflows

The recurring sequences you'll do every day. Memorize the *flow*, not
the keystrokes — the keystrokes get faster with reps.

### Opening a file when you know roughly the name

`<space>ff`, type a few characters, `<CR>`. Done. Sub-second on any
project.

### Opening a file when you don't know the name

`-` to open the parent directory in oil. `<CR>` to descend, `-` to go
up. Navigate to the file, `<CR>` to open.

### Finding "where is this string used?"

`<space>fg`, type your query. As you type, results refine in real
time. `<C-n>`/`<C-p>` to scroll, `<CR>` to open a result.

For the symbol under your cursor: `<space>fw`.

### Going from a usage to a definition

Cursor on the symbol, `gd`. Returns to your previous location with
`<C-o>` (older jump). `<C-i>` goes back forward.

### Reading unfamiliar code

1. Open the entry-point file.
2. Press `K` on unfamiliar identifiers to read hover docs.
3. `gd` to jump to a definition; `<C-o>` to come back.
4. `<space>fS` for document symbols (current file outline).
5. `<space>fs` for workspace symbols (project-wide outline).

### Reviewing your branch's diff (MR review)

Three layers of granularity:

1. **Big picture** — `<space>gm` opens `origin/main...HEAD`. File panel
   shows every changed file. Walk through with `j`/`k`+`<CR>`.
2. **Hunk-by-hunk in one file** — open the file, `]c` jumps to each
   hunk. `<space>hp` previews context. `K` for hover, `gd` for jump
   to definition (LSP works on the new-side pane).
3. **Per-file history** — `<space>gh` shows every commit that touched
   the current file with its diff.

### Editing while reviewing a diff

Diffview's right pane is a real buffer. Edits work. `:w` saves. You
can pull out the lower-level `<space>hp` / `<space>hr` to stage or
reset hunks without leaving the file.

### Working tree → commit

1. `<space>gd` to see all uncommitted changes.
2. Walk through the file panel, stage hunks (`<space>hs`) or whole
   files in the file panel.
3. Outside Neovim, `git commit` (or use lazygit for staging UI).

A common idiom: keep `lazygit` open in a separate zellij pane for the
staging UI, do all your *editing* in Neovim.

### Resolving merge conflicts

`git rebase` lands you in a conflicted state. From Neovim:

1. `<space>fd` to see all diagnostics (conflict markers count as
   diagnostics in the buffer).
2. Or `<space>gx` to list every conflict across the working tree in
   the quickfix.
3. Navigate to a conflict: `]x` for next, `[x` for prev.
4. Choose: `co` (ours), `ct` (theirs), `cb` (both), `c0` (none).
5. After the file is resolved, `:w`.
6. When all files are resolved: from a terminal, `git add -A && git
   rebase --continue`.

Alternative: `git mergetool` opens diffview's 3-way merge mode (OURS
| RESULT | THEIRS) — useful when the conflict is complex and seeing
the structured layout helps.

### Renaming a symbol across the codebase

Cursor on the symbol, `<space>rn`, type the new name, `<CR>`. LSP
finds and renames every occurrence in semantic position (not strings,
not comments). Modified buffers stay open until you `:wa` to save all.

For a non-semantic rename (a string used in templates, a directory
name, an env var name), use the multi-file replace pattern:

1. `<space>fg` to grep.
2. Multi-select results with `<Tab>`.
3. `<C-q>` to push to quickfix.
4. `:cdo s/OLD/NEW/g | update`

### Format a file ad hoc

`<space>cf`. Useful when you've disabled format-on-save with `<space>cF`.

### Splitting your view to read two parts of a file

`:vsp` (vertical split, same buffer). `<C-w>l` to move right.
`<C-w>=` to equalize. `:close` (or `<C-w>c`) when done.

### Comparing two files

```
:e file1.ts
:vsp file2.ts
:windo diffthis
```

Use `:diffoff!` to exit diff mode.

Or just `<space>gd` if both files are versions of the same git path.

---

## Power features to grow into

You don't need these on day one. Reach for them after a few weeks of
basic fluency. Each one is a force multiplier.

### Registers

Vim has many clipboards. The unnamed register `""` is the default — `yy`
copies into it, `p` pastes from it. But there are named registers:

| Register | Use |
|---|---|
| `"a` – `"z` | Named registers — yank with `"ayy`, paste with `"ap` |
| `"A` – `"Z` | Append to named register (capitalized) |
| `"0` | The last yank (`yy` only, not `dd`) |
| `"1` – `"9` | Recent deletes (most recent in `"1`) |
| `"+` | System clipboard (Cmd-C / Cmd-V on macOS) |
| `"*` | Selection clipboard (X11 — unused on macOS in practice) |
| `"/` | Last search pattern |
| `":` | Last Ex command |
| `".` | Last inserted text |
| `"%` | Current filename |
| `"#` | Alternate buffer's filename |
| `"=` | Expression register — `"=1+1<CR>p` pastes `2` |
| `"_` | Black hole — discard, don't store. `"_d` deletes without saving. |

The black hole is criminally underused. When you `dd` over text you
don't want, your *yank* register (`"0`) still has it. But if you've
been deleting and you want a clean yank to paste, `"_dd` deletes
without polluting the registers.

`:reg` shows the contents of every register.

### Marks

A mark is a saved cursor position you can jump back to.

| Keys | Effect |
|---|---|
| `m<letter>` | Set mark `<letter>` at current position |
| `` `<letter> `` | Jump to mark (exact position) |
| `'<letter>` | Jump to mark (line only) |
| `mA` – `mZ` | Global marks — work across files |
| `ma` – `mz` | Local marks — within a single file |
| `:marks` | List all marks |
| `` `. `` | Last edit position |
| `` `` `` | Position before the last jump |
| `` `[ `` / `` `] `` | Start / end of last yank or change |

### Macros

A macro records keystrokes and replays them.

| Keys | Effect |
|---|---|
| `q<letter>` | Start recording into register `<letter>` |
| `q` (while recording) | Stop recording |
| `@<letter>` | Replay macro |
| `@@` | Replay last macro |
| `<count>@<letter>` | Replay N times — `100@a` runs macro `a` 100 times |

Workflow: position on the first row, `qa`, do the edit, end on the
next row's start, `q`. Then `99@a` to repeat 99 times.

For dryer work, the dot command (`.`) is often enough.

### The jump list and change list

Vim tracks every "significant" cursor movement (a jump) and every
change. You can move back and forth through them.

| Keys | Effect |
|---|---|
| `<C-o>` | Older position in jump list |
| `<C-i>` | Newer position in jump list |
| `g;` | Older position in change list |
| `g,` | Newer position in change list |
| `:jumps` | List the jump list |
| `:changes` | List the change list |

Jumps include: `gd`, `gg`, `G`, `<C-]>`, `:tag`, `'<letter>`,
`<line>G`, `/pattern`. Anything that meaningfully relocates the cursor.

`<C-o>` is how you "go back" after jumping to a definition. Drill this
in early — it's the editor's "back button."

### Folds

Code folding by structure (using treesitter).

| Keys | Effect |
|---|---|
| `zc` | Close fold under cursor |
| `zo` | Open fold under cursor |
| `za` | Toggle fold |
| `zM` | Close all folds |
| `zR` | Open all folds |
| `zj` / `zk` | Jump to next / previous fold |

You haven't enabled folding by default — folding is set via `foldmethod`
and `foldexpr` options. Add to `options.lua` when you want it:

```lua
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.foldlevel = 99  -- open by default
```

### Quickfix and location lists

The quickfix list is a global list of file:line:col entries — useful
for grep results, LSP references, multi-file edits. The location list
is per-window.

| Command | Effect |
|---|---|
| `:copen` / `:cclose` | Open / close quickfix |
| `:cnext` (`:cn`) / `:cprevious` (`:cp`) | Navigate entries |
| `:cfirst` / `:clast` | First / last entry |
| `:cdo <cmd>` | Run `<cmd>` on every entry |
| `:cdo s/OLD/NEW/g \| update` | Multi-file substitute + save |
| `:lopen` etc. | Location list versions |

`gr` (LSP references) populates the quickfix. snacks.picker can send
its results to the quickfix with `<C-q>`.

### Command-line history and editing

`q:` opens a buffer of your Ex command history. You can edit it like
text, position on a line, press `<CR>` to run it.

`q/` and `q?` do the same for searches.

In command mode itself:

| Keys | Effect |
|---|---|
| `<C-r><register>` | Insert contents of a register |
| `<C-r><C-w>` | Insert word under cursor |
| `<Tab>` | Auto-complete |
| `<C-d>` | List all completions |
| `<C-f>` | Open command-line window (alt to `q:`) |

### Surround (vim-surround idiom)

Not in your config yet, but worth knowing: a `vim-surround`-style
plugin (e.g., `kylechui/nvim-surround`) adds operators for surrounding
text:

- `ysiw"` — surround inner-word with double quotes
- `cs"'` — change surrounding `"` to `'`
- `ds(` — delete surrounding parens

Worth adding when you find yourself wanting it.

### Substitution flags worth knowing

| Flag | Effect |
|---|---|
| `g` | All occurrences on line |
| `c` | Confirm each |
| `i` | Case insensitive |
| `I` | Case sensitive |
| `e` | Don't error if no match |
| `n` | Don't substitute; just count matches |

`:%s//new/g` (empty pattern) reuses the last search pattern — handy
when you've already searched (`/`) and want to substitute.

### Increment / decrement numbers

`<C-a>` increments the number under or after the cursor. `<C-x>`
decrements. In visual mode, `g<C-a>` increments each selected number
by the count *times their position* — handy for renumbering.

---

## Lua basics for configuration

You'll edit Lua to customize. The 5 things you need:

### 1. Tables

Lua's only data structure. Acts as both array and dict.

```lua
local opts = {
  number = true,
  height = 25,
  filetypes = { "lua", "vim" },
}

opts.number       -- access dict-style
opts.filetypes[1] -- access array-style (1-indexed!)
```

### 2. Functions

```lua
local function greet(name)
  return "Hello, " .. name
end

-- Anonymous function:
local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc })
end
```

`..` concatenates strings.

### 3. The vim namespace

Everything Neovim exposes is under `vim.*`:

| API | Use |
|---|---|
| `vim.o.<option>` | Get/set vim options. `vim.o.number = true` |
| `vim.bo` | Buffer-local options. `vim.bo.filetype` |
| `vim.wo` | Window-local options. |
| `vim.g.<global>` | Vim globals. `vim.g.mapleader = " "` |
| `vim.keymap.set(mode, lhs, rhs, opts)` | Set a keymap |
| `vim.api.*` | The raw Neovim API |
| `vim.lsp.*` | LSP client |
| `vim.diagnostic.*` | Diagnostics API |
| `vim.fn.*` | Vim functions callable from Lua (`vim.fn.expand`, etc.) |
| `vim.cmd("...")` | Run an Ex command |
| `vim.notify("msg", vim.log.levels.WARN)` | Show a notification |
| `vim.print(value)` | Pretty-print a value (great for debugging) |

### 4. Requires and modules

Files under `lua/` are auto-discoverable as modules.
`lua/config/options.lua` is `require("config.options")`. The dotted
path matches the directory structure (with `/` replaced by `.`).

`require()` caches modules. To force a reload during development:

```lua
package.loaded["config.options"] = nil
require("config.options")
```

Or use lazy's `:Lazy reload <plugin>`.

### 5. Lazy.nvim spec syntax

Every file in `lua/plugins/` returns either:

- A single spec table: `return { "owner/repo", ... }`
- A list of spec tables: `return { {...}, {...}, {...} }`

Inside `opts`, anything that looks like a function will be called with
the spec's `opts` and is expected to mutate or return them. Most
plugins simply receive the table as-is.

---

## Getting unstuck

### `:checkhealth`

Run this any time something seems off. It tests every component:

```
:checkhealth
```

Or focus on one:

```
:checkhealth nvim-treesitter
:checkhealth lazy
:checkhealth mason
:checkhealth vim.lsp
```

You'll get a colored report showing what passed and what failed.

### `:messages`

Shows the message history. If a popup flashed and disappeared, `:messages`
has it.

### `:Lazy log`

Per-plugin update logs. Useful for "what changed after the update?"

### `:LspInfo`

Shows which LSP clients are attached to the current buffer and their
state. If a feature isn't working, start here — confirm the LSP is
attached.

### `:LspLog`

Tail the LSP communication log. Verbose, but the source of truth.

### `:ConformInfo`

For formatter issues. Shows which formatters apply to the current
filetype and whether they're available.

### `:Mason`

The Mason UI. `i` to install, `u` to update, `X` to remove a tool.

### Plugin breaks after update

```
:Lazy restore                " roll back lock-pinned versions
:Lazy update <plugin-name>   " update one at a time
```

Find the commit in `git log nvim/lazy-lock.json`, copy the SHA,
manually pin in the spec if needed.

### Performance feels slow

```
:Lazy profile
```

Shows startup time per plugin. Anything over 50ms warrants
investigation.

```
:checkhealth vim.lsp
```

LSP can hang on huge monorepos. Check the server's resource usage
externally.

---

## Learning roadmap

You don't learn this all at once. Realistic milestones:

### Week 1: survival

- Stay in normal mode by default; press `<Esc>` immediately after typing.
- Move with `hjkl`, `w`/`b`, `gg`/`G`.
- Edit with `i`/`a`/`o`, `dd`, `yy`, `p`, `u`.
- Save/quit: `:w`, `:q`, `:wq`, `:q!`.
- Open files: `<space>ff`.
- Switch buffers: `<space>fb`.
- Search: `/`, `n`, `N`.
- Run `:Tutor` once. Maybe twice.

Goal: edit a real file without falling back to VSCode out of frustration.

### Weeks 2-4: the vim grammar

- Verbs + motions: `dw`, `c$`, `yip`.
- Text objects: `ciw`, `da(`, `vit`.
- Counts: `5j`, `3dd`.
- The dot command (`.`).
- Word boundaries: `e`, `b`, `*`, `#`.
- Jump list: `<C-o>` and `<C-i>`.
- LSP basics: `gd`, `K`, `<space>rn`, `<space>ca`.
- Splits: `:vsp`, `<C-w>` movements.

Goal: stop thinking about *how* to move; think about *where* to move.

### Months 2-3: efficient editing

- Marks (`m<letter>`, `` `<letter> ``).
- Registers, especially `"+` (system clipboard) and `"_` (black hole).
- Macros (`qa`, `@a`).
- Multi-file edits via quickfix + `:cdo`.
- Search/substitute fluency, `inccommand` preview.
- Diffview workflow for MR review.
- which-key exploration of `<space>` keymaps.

Goal: edit faster in Neovim than you ever did in VSCode.

### Month 3+: depth

- Folds.
- Window layout management — multiple splits, tabs.
- Custom keymaps for your repetitive patterns.
- Writing small Lua snippets in `lua/config/` for project-specific
  helpers.
- Plugins you want: surround, autopair, possibly a debugger
  (`nvim-dap`), possibly `flash.nvim` or `leap.nvim` for whole-screen
  motion.
- Maybe a `vim-be-good`-style game for muscle memory.

### Always

- `:help <topic>` whenever you're confused.
- Read your own config every few months — you'll notice things that
  should change.
- Browse `:Lazy update` notes — you'll learn about new features.

---

## References

### Built-in

- `:help` — the docs. Always start here.
- `:Tutor` — built-in tutorial; 30 minutes; do it more than once.
- `:checkhealth` — diagnostic.

### Cheatsheets

- `vimcasts.org` — short focused screencasts on specific techniques.
- `vim-galore` (GitHub: mhinz/vim-galore) — sprawling cheat sheet.
- `learn-vim` (GitHub: iggredible/Learn-Vim) — modern beginner book.

### Plugin docs

Every plugin in your config has a README at `github.com/<owner>/<name>`.
The Lazy UI (`:Lazy`) shows links for each.

For the ones you use most:

- Diffview: `sindrets/diffview.nvim` (`:h diffview`)
- Gitsigns: `lewis6991/gitsigns.nvim` (`:h gitsigns`)
- Snacks: `folke/snacks.nvim`
- Oil: `stevearc/oil.nvim` (`:h oil`)
- Conform: `stevearc/conform.nvim` (`:h conform`)
- Blink: `saghen/blink.cmp` (`:h blink-cmp`)
- LSP: `:h lsp` for the built-in client, `:h lspconfig` for server
  defaults.

### Community

- `r/neovim` — Reddit. Hit-or-miss but lots of dotfiles inspiration.
- `dotfyle.com/neovim` — searchable index of public configs.
- The Neovim discord and the lazy.nvim/folke ecosystem repos are
  responsive to issues.

---

## A note on patience

The first month feels slower than VSCode. That's normal. Around week
four, the grammar starts to feel like a language, and somewhere in
month two you stop thinking about keys entirely. By month three the
editor is faster than thought. The investment compounds.

You don't have to be a power user to be effective. The 30 keys in the
[daily survival kit](#daily-survival-kit) and the LSP keymaps are
80% of the value. Everything in this handbook beyond that is
optimization.

Read this doc once, bookmark sections, and come back when you hit
something specific. The config itself is the source of truth — when
in doubt, read your `lua/plugins/<name>.lua`.
