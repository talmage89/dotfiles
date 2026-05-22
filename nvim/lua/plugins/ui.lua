return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "tokyonight",
        globalstatus = true,
        section_separators = "",
        component_separators = "│",
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = {
          {
            "branch",
            fmt = function(branch)
              if not branch or branch == "" then
                return branch or ""
              end
              local stripped = branch:gsub("^[^/]+/", "")
              return stripped:match("^(%a+%-%d+)") or stripped
            end,
          },
          "diff",
          "diagnostics",
        },
        lualine_c = {
          { "filename", path = 1 },
          {
            function()
              local reg = vim.fn.reg_recording()
              return reg ~= "" and ("recording @" .. reg) or ""
            end,
            color = { fg = "#ff9e64", gui = "bold" },
          },
        },
        lualine_x = { "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      delay = 300,
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Local keymaps (which-key)",
      },
    },
  },
}
