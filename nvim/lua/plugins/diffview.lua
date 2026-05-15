return {
  "sindrets/diffview.nvim",
  cmd = {
    "DiffviewOpen",
    "DiffviewClose",
    "DiffviewToggleFiles",
    "DiffviewFocusFiles",
    "DiffviewFileHistory",
    "DiffviewRefresh",
  },
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Diff: working tree" },
    { "<leader>gD", "<cmd>DiffviewClose<CR>", desc = "Diff: close" },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "Diff: history (this file)" },
    { "<leader>gH", "<cmd>DiffviewFileHistory<CR>", desc = "Diff: history (branch)" },
    { "<leader>gm", "<cmd>DiffviewOpen origin/main...HEAD<CR>", desc = "Diff: branch vs origin/main" },
    { "<leader>gM", "<cmd>DiffviewOpen origin/master...HEAD<CR>", desc = "Diff: branch vs origin/master" },
  },
  opts = {
    default_args = {
      DiffviewOpen = { "--imply-local" },
    },
    enhanced_diff_hl = true,
    hooks = {
      diff_buf_win_enter = function(_, winid, ctx)
        vim.wo[winid].foldenable = false
        vim.wo[winid].foldcolumn = "0"
        local sym = ctx and ctx.symbol
        local extra
        if sym == "a" then
          extra = "DiffChange:DiffDelete,DiffText:DiffTextAsDelete"
        elseif sym == "b" then
          extra = "DiffChange:DiffAdd,DiffText:DiffTextAsAdd"
        end
        if extra then
          local cur = vim.wo[winid].winhl
          vim.wo[winid].winhl = cur == "" and extra or cur .. "," .. extra
        end
      end,
    },
    view = {
      default = { layout = "diff2_horizontal" },
      merge_tool = { layout = "diff3_mixed" },
      file_history = { layout = "diff2_horizontal" },
    },
    file_panel = {
      listing_style = "list",
      win_config = { position = "left", width = 35 },
    },
    keymaps = {
      view = {
        { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
        { "n", "<Tab>", "<cmd>DiffviewToggleFiles<CR>", { desc = "Toggle file panel" } },
      },
      file_panel = {
        { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
      },
      file_history_panel = {
        { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
      },
    },
  },
  config = function(_, opts)
    require("patches.diffview")()
    require("diffview").setup(opts)
  end,
}
