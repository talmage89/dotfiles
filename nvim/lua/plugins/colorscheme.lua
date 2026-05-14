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
      c.bg_statusline = "#14181c"
    end,
  },
  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.cmd.colorscheme("tokyonight-night")

    local set_hl = vim.api.nvim_set_hl

    set_hl(0, "DiffAdd", { bg = "#1e3a1e" })
    set_hl(0, "DiffDelete", { bg = "#3a1e1e" })
    set_hl(0, "DiffChange", { bg = "#3a341e" })
    set_hl(0, "DiffText", { bg = "#5a4d28" })
    set_hl(0, "DiffviewDiffAddAsDelete", { bg = "#3a1e1e" })

    set_hl(0, "TabLine", { fg = "#6C7086", bg = "NONE" })
    set_hl(0, "TabLineSel", { fg = "#c4b28a", bg = "NONE", bold = true, italic = true })
    set_hl(0, "TabLineFill", { bg = "NONE" })
  end,
}
