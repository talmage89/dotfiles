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

local function find_entry(view, path)
  for _, entry in view.files:iter() do
    if entry.path == path then
      return entry
    end
  end
end

local function jump_in_view(view, entry, line, col)
  local dva = require("diffview.async")
  dva.void(function()
    dva.await(view:set_file(entry, true, true))
    -- feedkeys, not norm!/win_set_cursor: only real input processing triggers
    -- 'cursorbind', which drags the old panel to the diff-aligned line
    vim.api.nvim_feedkeys(("%dG%d|zvzz"):format(line, math.max(col or 1, 1)), "nx", false)
  end)()
end

local function diff_grep(pattern)
  local view = require("diffview.lib").get_current_view()
  if view and not view.files then
    view = nil
  end
  local toplevel = view and view.adapter.ctx.toplevel
    or vim.trim(vim.fn.system({ "git", "rev-parse", "--show-toplevel" }))
  -- -U0 so only changed lines are searched, never context lines
  local cmd = { "git", "-C", toplevel, "diff", "-U0", "--no-color" }
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
      local col = text:find(pattern, 1, true)
      if col then
        items[#items + 1] = {
          text = ("%s:%d:%s"):format(file, lnum, text),
          file = file,
          pos = { lnum, col - 1 },
          line = text,
          cwd = toplevel,
        }
      end
      lnum = lnum + 1
    end
  end
  if #items == 0 then
    vim.notify("DiffGrep: no matches for '" .. pattern .. "'")
    return
  end
  Snacks.picker({
    title = "DiffGrep: " .. pattern,
    items = items,
    format = "file",
    confirm = function(picker, item)
      picker:close()
      if not item then
        return
      end
      local entry = view and find_entry(view, item.file)
      vim.schedule(function()
        if entry then
          jump_in_view(view, entry, item.pos[1], item.pos[2] + 1)
        else
          vim.cmd(("edit +%d %s"):format(item.pos[1], vim.fn.fnameescape(vim.fs.joinpath(item.cwd, item.file))))
        end
      end)
    end,
  })
end

local function diff_grep_prompt()
  vim.ui.input({ prompt = "DiffGrep: " }, function(input)
    if input and input ~= "" then
      diff_grep(input)
    end
  end)
end

local function layer_toggle()
  require("diffview-layers").toggle()
end

local function layer_assign()
  local layers = require("diffview-layers")
  if layers.is_armed() then
    layers.assign(vim.v.count)
  else
    require("diffview.actions").open_commit_log()
  end
end

local function layer_next()
  require("diffview-layers").cycle(1)
end

local function layer_prev()
  require("diffview-layers").cycle(-1)
end

local function layer_list()
  require("diffview-layers").list()
end

local function goto_definition()
  if #vim.lsp.get_clients({ bufnr = 0 }) == 0 then
    vim.cmd("norm! gd")
    return
  end
  local view = require("diffview.lib").get_current_view()
  if not (view and view.files) then
    return vim.lsp.buf.definition()
  end
  vim.lsp.buf.definition({
    on_list = function(opts)
      local target = opts.items[1]
      if not target then
        return
      end
      if #opts.items > 1 then
        vim.notify(("gd: %d definitions, jumping to first"):format(#opts.items))
      end
      local rel = vim.fs.relpath(view.adapter.ctx.toplevel, vim.fs.normalize(target.filename))
      local entry = rel and find_entry(view, rel)
      if entry then
        jump_in_view(view, entry, target.lnum, target.col)
      else
        vim.cmd(("tab drop %s"):format(vim.fn.fnameescape(target.filename)))
        pcall(vim.api.nvim_win_set_cursor, 0, { target.lnum, math.max(target.col - 1, 0) })
        vim.cmd("norm! zvzz")
      end
    end,
  })
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
    { "<leader>gl", layer_toggle, desc = "Diff: layered review" },
  },
  opts = {
    default_args = {
      DiffviewOpen = { "--imply-local" },
    },
    enhanced_diff_hl = true,
    hooks = {
      diff_buf_win_enter = function(bufnr, winid, ctx)
        -- gd set here, not in keymaps.view: diffview *deletes* (not restores)
        -- view keymaps on detach, which would strip the LspAttach gd from the
        -- real buffer. This mapping degrades to plain LSP definition outside
        -- a view, so it can safely persist on the buffer.
        if not vim.b[bufnr].diffview_gd then
          vim.b[bufnr].diffview_gd = true
          local set_gd = function()
            vim.keymap.set("n", "gd", goto_definition, { buffer = bufnr, desc = "LSP: definition (diff-aware)" })
          end
          set_gd()
          -- when the buffer first opens inside the view, lsp.lua's LspAttach
          -- fires after this hook and its plain gd would win; this autocmd is
          -- created later than lsp.lua's, so it runs after and re-applies ours
          vim.api.nvim_create_autocmd("LspAttach", { buffer = bufnr, callback = set_gd })
        end
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
        { "n", "<leader>gl", layer_toggle, { desc = "Diff: toggle layered review" } },
        -- L keeps its stock diffview behavior (open_commit_log) until armed
        { "n", "L", layer_assign, { desc = "Diff: assign file to ring [count]" } },
        { "n", "]l", layer_next, { desc = "Diff: next layer (outward)" } },
        { "n", "[l", layer_prev, { desc = "Diff: prev layer (inward)" } },
        { "n", "gL", layer_list, { desc = "Diff: list layer assignments" } },
      },
      file_panel = {
        { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
        { "n", "<leader>g/", diff_grep_prompt, { desc = "Diff: grep changed lines" } },
        { "n", "<leader>gl", layer_toggle, { desc = "Diff: toggle layered review" } },
        { "n", "L", layer_assign, { desc = "Diff: assign file to ring [count]" } },
        { "n", "]l", layer_next, { desc = "Diff: next layer (outward)" } },
        { "n", "[l", layer_prev, { desc = "Diff: prev layer (inward)" } },
        { "n", "gL", layer_list, { desc = "Diff: list layer assignments" } },
      },
      file_history_panel = {
        { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
      },
    },
  },
  config = function(_, opts)
    require("patches.diffview")()
    require("diffview").setup(opts)
    require("diffview-layers").attach()
    vim.api.nvim_create_user_command("DiffGrep", function(o)
      diff_grep(o.args)
    end, { nargs = 1, desc = "Grep added lines in the current diff" })
    vim.api.nvim_create_user_command("DiffLayersReset", function()
      require("diffview-layers").reset()
    end, { desc = "Clear diff layer assignments for this repo+branch" })
  end,
}
