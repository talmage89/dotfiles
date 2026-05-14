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
            ["<M-BS>"] = { "<c-s-w>", mode = "i", expr = true, desc = "Delete word (Opt+BS)" },
            ["<C-u>"]  = { "<c-s-u>", mode = "i", expr = true, desc = "Delete to start (Cmd+BS)" },
          },
        },
      },
    },
    bigfile = { enabled = true },
    quickfile = { enabled = true },
  },
  keys = {
    { "<leader>ff", function() Snacks.picker.files({ hidden = true }) end, desc = "Find files" },
    { "<leader>fF", function() Snacks.picker.files({ hidden = true, ignored = true }) end, desc = "Find files (incl. ignored)" },
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
    { "<leader>gp", function()
        Snacks.picker.git_log({
          confirm = function(picker, item)
            picker:close()
            if item and item.commit then
              vim.cmd("DiffviewOpen " .. item.commit .. "..HEAD")
            end
          end,
        })
      end, desc = "Git: pick commit → diff vs HEAD" },
    { "<leader>gP", function()
        Snacks.picker.git_log({
          confirm = function(picker, item)
            picker:close()
            if item and item.commit then
              vim.cmd("DiffviewOpen " .. item.commit .. "^.." .. item.commit)
            end
          end,
        })
      end, desc = "Git: pick commit → diff that commit only" },
  },
}
