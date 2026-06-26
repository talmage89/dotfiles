return {
  "kylechui/nvim-surround",
  version = "*",
  -- v4 sets keymaps on plugin load (not via setup). Disable the default
  -- normal/visual maps (ys/ds/cs/S) so flash.nvim owns s in operator-
  -- pending mode (ds = delete-to-symbol, etc.). Surround moves to a gs
  -- prefix; insert-mode <C-g>s defaults are kept (no flash conflict).
  init = function()
    vim.g.nvim_surround_no_normal_mappings = true
    vim.g.nvim_surround_no_visual_mappings = true
  end,
  keys = {
    { "gsa", "<Plug>(nvim-surround-normal)", desc = "Surround: add (motion)" },
    { "gss", "<Plug>(nvim-surround-normal-cur)", desc = "Surround: add (line)" },
    { "gsA", "<Plug>(nvim-surround-normal-line)", desc = "Surround: add (motion, new lines)" },
    { "gsS", "<Plug>(nvim-surround-normal-cur-line)", desc = "Surround: add (line, new lines)" },
    { "gsd", "<Plug>(nvim-surround-delete)", desc = "Surround: delete" },
    { "gsc", "<Plug>(nvim-surround-change)", desc = "Surround: change" },
    { "gsC", "<Plug>(nvim-surround-change-line)", desc = "Surround: change (new lines)" },
    { "gsa", "<Plug>(nvim-surround-visual)", mode = "x", desc = "Surround: wrap selection" },
    { "gsS", "<Plug>(nvim-surround-visual-line)", mode = "x", desc = "Surround: wrap selection (new lines)" },
  },
  opts = {},
}
