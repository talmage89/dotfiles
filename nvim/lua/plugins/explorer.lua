return {
  "stevearc/oil.nvim",
  lazy = false,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  keys = {
    { "-", "<cmd>Oil<CR>", desc = "Open parent directory" },
    { "<leader>-", "<cmd>Oil --float<CR>", desc = "Open oil in float" },
  },
  opts = {
    default_file_explorer = true,
    delete_to_trash = true,
    skip_confirm_for_simple_edits = false,
    prompt_save_on_select_new_entry = true,
    constrain_cursor = "editable",
    view_options = {
      show_hidden = true,
      is_always_hidden = function(name)
        return name == ".." or name == ".git"
      end,
    },
    float = {
      padding = 4,
      max_width = 100,
      max_height = 0,
      border = "rounded",
    },
    keymaps = {
      ["<C-h>"] = false,
      ["<C-l>"] = false,
    },
  },
}
