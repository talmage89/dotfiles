return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    picker = {
      ui_select = true,
      win = {
        input = {
          keys = {
            ["<Esc>"] = { "close", mode = { "n", "i" } },
          },
        },
      },
    },
    bigfile = { enabled = true },
    quickfile = { enabled = true },
  },
  keys = {
    { "<leader>ff", function() Snacks.picker.files() end, desc = "Find files" },
    { "<leader>fF", function() Snacks.picker.files({ hidden = true, ignored = true }) end, desc = "Find files (incl. hidden/ignored)" },
    { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent files" },
    { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>fg", function() Snacks.picker.grep() end, desc = "Grep workspace" },
    { "<leader>f/", function() Snacks.picker.lines() end, desc = "Grep current buffer" },
    { "<leader>fw", function() Snacks.picker.grep_word() end, mode = { "n", "x" }, desc = "Grep word under cursor" },
    { "<leader>fs", function() Snacks.picker.lsp_workspace_symbols() end, desc = "Workspace symbols (LSP)" },
    { "<leader>fS", function() Snacks.picker.lsp_symbols() end, desc = "Document symbols (LSP)" },
    { "<leader>fh", function() Snacks.picker.help() end, desc = "Help tags" },
    { "<leader>fd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics (workspace)" },
    { "<leader>fk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
    { "<leader>fc", function() Snacks.picker.command_history() end, desc = "Command history" },
    { "<leader>fp", function() Snacks.picker.pickers() end, desc = "All pickers" },
    { "<leader>fR", function() Snacks.picker.resume() end, desc = "Resume last picker" },
  },
}
