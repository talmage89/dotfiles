local function toggle_focus()
  vim.g.diffview_focused = not vim.g.diffview_focused
  local focused = vim.g.diffview_focused
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.wo[win].diff then
      vim.wo[win].foldenable = focused
      vim.wo[win].foldcolumn = focused and "1" or "0"
      if focused then
        vim.wo[win].foldlevel = 0
      end
    end
  end
  vim.cmd("diffupdate")
  vim.notify("Diff: " .. (focused and "focused" or "full context"))
end

local function diff_grep(pattern)
  local view = require("diffview.lib").get_current_view()
  -- -U0 so only changed lines are searched, never context lines
  local cmd = { "git", "diff", "-U0", "--no-color" }
  if view and view.rev_arg then
    for word in view.rev_arg:gmatch("%S+") do
      table.insert(cmd, word)
    end
  end
  local items, file, lnum = {}, nil, 0
  for _, line in ipairs(vim.fn.systemlist(cmd)) do
    local f = line:match("^%+%+%+ b/(.+)")
    local hunk = line:match("^@@ %-%d+,?%d* %+(%d+)")
    if f then
      file = f
    elseif hunk then
      lnum = tonumber(hunk)
    elseif file and line:match("^%+") then
      local text = line:sub(2)
      if text:find(pattern, 1, true) then
        items[#items + 1] = { filename = file, lnum = lnum, text = text }
      end
      lnum = lnum + 1
    end
  end
  if #items == 0 then
    vim.notify("DiffGrep: no matches for '" .. pattern .. "'")
    return
  end
  vim.fn.setqflist({}, " ", { title = "DiffGrep: " .. pattern, items = items })
  vim.cmd("copen")
end

local function diff_grep_prompt()
  vim.ui.input({ prompt = "DiffGrep: " }, function(input)
    if input and input ~= "" then
      diff_grep(input)
    end
  end)
end

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
        local focused = vim.g.diffview_focused or false
        vim.wo[winid].foldenable = focused
        vim.wo[winid].foldcolumn = focused and "1" or "0"
        if focused then
          vim.wo[winid].foldlevel = 0
        end
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
      win_config = { position = "left", width = 65 },
    },
    keymaps = {
      view = {
        { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
        { "n", "<Tab>", "<cmd>DiffviewToggleFiles<CR>", { desc = "Toggle file panel" } },
        { "n", "<leader>gf", toggle_focus, { desc = "Diff: toggle focused/full" } },
        { "n", "<leader>g/", diff_grep_prompt, { desc = "Diff: grep changed lines" } },
      },
      file_panel = {
        { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
        { "n", "<leader>g/", diff_grep_prompt, { desc = "Diff: grep changed lines" } },
      },
      file_history_panel = {
        { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
      },
    },
  },
  config = function(_, opts)
    require("patches.diffview")()
    require("diffview").setup(opts)
    vim.api.nvim_create_user_command("DiffGrep", function(o)
      diff_grep(o.args)
    end, { nargs = 1, desc = "Grep added lines in the current diff" })
  end,
}
