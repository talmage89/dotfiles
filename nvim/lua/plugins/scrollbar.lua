return {
  "lewis6991/satellite.nvim",
  event = "VeryLazy",
  opts = {
    current_only = false,
    winblend = 50,
    handlers = {
      cursor = { enable = true },
      search = { enable = true },
      diagnostic = { enable = true, signs = { "-", "=", "≡" } },
      gitsigns = { enable = true },
      marks = { enable = true, show_builtins = false },
      quickfix = { enable = true },
    },
  },
}
