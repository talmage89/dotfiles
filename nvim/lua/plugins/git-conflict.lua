return {
  "akinsho/git-conflict.nvim",
  version = "*",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    default_mappings = true,
    default_commands = true,
    disable_diagnostics = false,
    list_opener = "copen",
    highlights = {
      incoming = "DiffAdd",
      current = "DiffText",
    },
  },
  keys = {
    { "<leader>gx", "<cmd>GitConflictListQf<CR>", desc = "Conflicts: list in quickfix" },
  },
}
