return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    style = "night",
    styles = {
      comments = { italic = true },
      keywords = { italic = false },
    },
    on_colors = function(c)
      c.bg = "#14181c"
      c.bg_dark = "#0f1318"
      c.bg_float = "#1a1f25"
      c.bg_popup = "#1a1f25"
      c.bg_sidebar = "#14181c"
      c.bg_statusline = "#1a1f25"
    end,
  },
  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.cmd.colorscheme("tokyonight-night")
  end,
}
