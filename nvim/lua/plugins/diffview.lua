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

-- Back-jump history for in-view navigation, keyed by view. The diff windows are
-- made with `tab split`, so they inherit the jumplist of wherever the view was
-- opened from, and a native <C-o> would drop a foreign buffer straight into a
-- diff window: the window falls out of diff mode and the panel keeps pointing at
-- the file that is no longer on screen. In-view jumps therefore record their
-- origin here, and <C-o> only falls through to the real jumplist for positions
-- inside the buffer that is already on screen.
local rings = setmetatable({}, { __mode = "k" })

local function ring_for(view)
  local ring = rings[view]
  if not ring then
    ring = { back = {}, arrivals = {} }
    rings[view] = ring
  end
  return ring
end

local function view_position(view)
  local entry = view.cur_entry
  if not entry then
    return nil
  end
  local win = vim.api.nvim_get_current_win()
  if not vim.wo[win].diff then
    local main = view.cur_layout and view.cur_layout:get_main_win()
    if not main then
      return nil
    end
    win = main.id
  end
  local ok, pos = pcall(vim.api.nvim_win_get_cursor, win)
  return ok and { path = entry.path, lnum = pos[1], col = pos[2] + 1 } or nil
end

-- `origin` is the position to record as the jump's origin: nil reads the cursor
-- now, `false` records nothing (that is what walking back does). Anything routed
-- through a picker must pass its own, captured before the picker took the cursor.
local function jump_in_view(view, entry, line, col, origin)
  local ring = ring_for(view)
  if ring.busy then
    return
  end
  if origin == nil then
    origin = view_position(view)
  end
  local dva = require("diffview.async")
  ring.busy = true
  dva.void(function()
    local ok = true
    if view.cur_entry ~= entry then
      ok = pcall(dva.await, view:set_file(entry, true, true))
    else
      local main = view.cur_layout and view.cur_layout:get_main_win()
      if main then
        pcall(vim.api.nvim_set_current_win, main.id)
      end
    end
    if ok then
      -- feedkeys, not norm!/win_set_cursor: only real input processing triggers
      -- 'cursorbind', which drags the old panel to the diff-aligned line
      vim.api.nvim_feedkeys(("%dG%d|zvzz"):format(line, math.max(col or 1, 1)), "nx", false)
      if origin then
        table.insert(ring.back, origin)
      end
      -- that G also pushes a jumplist entry for the position we land on; mark it
      -- so <C-o> steps over it instead of spending a press going nowhere
      local list = vim.fn.getjumplist()[1]
      local last = list[#list]
      if last then
        ring.arrivals[last.bufnr .. ":" .. last.lnum] = true
      end
    end
    ring.busy = false
  end)()
end

-- How many real jumplist steps back land on a position inside the buffer this
-- window already shows. `near` stops at the first arrival marker -- anything
-- beyond it predates the file on screen, so only the ring can reach it without
-- breaking the layout. `far` looks past the markers, for when the ring is spent.
local function native_steps(ring, count)
  local list, idx = unpack(vim.fn.getjumplist())
  local bufnr = vim.api.nvim_get_current_buf()
  local remaining, blocked, near, far = count, false, nil, nil
  for i = idx, 1, -1 do
    local e = list[i]
    if ring.arrivals[e.bufnr .. ":" .. e.lnum] then
      blocked = true
    elseif e.bufnr == bufnr then
      remaining = remaining - 1
      if remaining == 0 then
        far = idx - i + 1
        near = not blocked and far or nil
        break
      end
    end
  end
  return near, far
end

local function jump_back()
  local view = require("diffview.lib").get_current_view()
  if not view then
    return vim.api.nvim_feedkeys(vim.keycode("<C-o>"), "n", false)
  end
  local ring = ring_for(view)
  if ring.busy then
    return
  end
  local near, far = native_steps(ring, vim.v.count1)
  if near then
    return vim.api.nvim_feedkeys(near .. vim.keycode("<C-o>"), "nx", false)
  end
  while #ring.back > 0 do
    local pos = table.remove(ring.back)
    local entry = view.files and find_entry(view, pos.path)
    if entry then
      return jump_in_view(view, entry, pos.lnum, pos.col, false)
    end
  end
  if far then
    return vim.api.nvim_feedkeys(far .. vim.keycode("<C-o>"), "nx", false)
  end
  vim.notify("Diff: no earlier position inside this diff")
end

-- A target outside the diff has no business in a diff window, and a fresh tab
-- per jump piles them up: land it in the tab the review was opened from, the
-- same place diffview's own `gf` goes.
local function jump_outside_view(item, tagname)
  local tab = require("diffview.lib").get_prev_non_view_tabpage()
  local edit = "edit " .. vim.fn.fnameescape(item.filename)
  if tab then
    vim.api.nvim_set_current_tabpage(tab)
    -- arrive as a plain jump would in that tab, so <C-o>/<C-t> there lead back
    -- to what it was showing
    vim.cmd("normal! m'")
    if tagname then
      vim.fn.settagstack(vim.api.nvim_get_current_win(), {
        items = { { tagname = tagname, from = { vim.fn.bufnr("%"), vim.fn.line("."), vim.fn.col("."), 0 } } },
      }, "t")
    end
    vim.cmd(edit)
  else
    vim.cmd("tabnew")
    local scratch = vim.api.nvim_get_current_buf()
    vim.cmd("keepalt " .. edit)
    if scratch ~= vim.api.nvim_get_current_buf() then
      pcall(vim.api.nvim_buf_delete, scratch, { force = true })
    end
  end
  pcall(vim.api.nvim_win_set_cursor, 0, { item.lnum, math.max((item.col or 1) - 1, 0) })
  vim.cmd("norm! zvzz")
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
  local origin = view and view_position(view)
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
        local path = vim.fs.joinpath(item.cwd, item.file)
        if entry then
          jump_in_view(view, entry, item.pos[1], item.pos[2] + 1, origin)
        elseif view then
          jump_outside_view({ filename = path, lnum = item.pos[1], col = item.pos[2] + 1 })
        else
          vim.cmd(("edit +%d %s"):format(item.pos[1], vim.fn.fnameescape(path)))
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

local function jump_to_item(view, item, tagname, origin)
  local entry
  if view.files and view.adapter then
    local rel = vim.fs.relpath(view.adapter.ctx.toplevel, vim.fs.normalize(item.filename))
    entry = rel and find_entry(view, rel)
  end
  if entry then
    jump_in_view(view, entry, item.lnum, item.col, origin)
  else
    jump_outside_view(item, tagname)
  end
end

local function pick_and_jump(view, items, title, tagname, origin)
  Snacks.picker({
    title = title,
    items = vim.tbl_map(function(item)
      return {
        text = ("%s:%d:%s"):format(vim.fn.fnamemodify(item.filename, ":."), item.lnum, item.text or ""),
        file = item.filename,
        pos = { item.lnum, math.max((item.col or 1) - 1, 0) },
        line = item.text,
      }
    end, items),
    format = "file",
    confirm = function(picker, item)
      picker:close()
      if not item then
        return
      end
      vim.schedule(function()
        jump_to_item(view, { filename = item.file, lnum = item.pos[1], col = item.pos[2] + 1 }, tagname, origin)
      end)
    end,
  })
end

-- Every LSP jump out of a diff buffer needs the same treatment: stock behavior
-- edits the target in the current window, which is a diff window.
local lsp_jumps = {
  { key = "gd", method = "definition", label = "definition" },
  { key = "gD", method = "declaration", label = "declaration" },
  { key = "gi", method = "implementation", label = "implementation" },
  { key = "gy", method = "type_definition", label = "type definition" },
  { key = "gr", method = "references", label = "references", pick = true },
}

local function lsp_jump(spec)
  return function()
    if #vim.lsp.get_clients({ bufnr = 0 }) == 0 then
      -- no server here: let the key mean whatever it means in plain vim
      return vim.api.nvim_feedkeys(vim.keycode(spec.key), "n", false)
    end
    local view = require("diffview.lib").get_current_view()
    if not view then
      return vim.lsp.buf[spec.method]()
    end
    local tagname = vim.fn.expand("<cword>")
    local origin = view_position(view)
    local list_opts = {
      on_list = function(result)
        if #result.items > 1 and spec.pick then
          return pick_and_jump(view, result.items, result.title or spec.label, tagname, origin)
        end
        local target = result.items[1]
        if not target then
          return
        end
        if #result.items > 1 then
          vim.notify(("%s: %d results, jumping to first"):format(spec.key, #result.items))
        end
        jump_to_item(view, target, tagname, origin)
      end,
    }
    if spec.method == "references" then
      -- references() takes a leading context argument; the others take opts only
      vim.lsp.buf.references(nil, list_opts)
    else
      vim.lsp.buf[spec.method](list_opts)
    end
  end
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
        -- LSP jumps set here, not in keymaps.view: diffview *deletes* (not
        -- restores) view keymaps on detach, which would strip the LspAttach
        -- mappings from the real buffer. These degrade to the plain LSP jump
        -- outside a view, so they can safely persist on the buffer.
        if not vim.b[bufnr].diffview_lsp_jumps then
          vim.b[bufnr].diffview_lsp_jumps = true
          local set_jumps = function()
            for _, spec in ipairs(lsp_jumps) do
              vim.keymap.set("n", spec.key, lsp_jump(spec), {
                buffer = bufnr,
                desc = ("LSP: %s (diff-aware)"):format(spec.label),
              })
            end
          end
          set_jumps()
          -- when the buffer first opens inside the view, lsp.lua's LspAttach
          -- fires after this hook and its plain mappings would win; this autocmd
          -- is created later than lsp.lua's, so it runs after and re-applies ours
          vim.api.nvim_create_autocmd("LspAttach", { buffer = bufnr, callback = set_jumps })
        end
        -- the view's windows inherit the jumplist of the window it was split
        -- from, which is full of files that have nothing to do with this diff
        if not vim.w[winid].diffview_jumps_cleared then
          vim.w[winid].diffview_jumps_cleared = true
          vim.api.nvim_win_call(winid, function()
            vim.cmd("clearjumps")
          end)
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
      listing_style = "tree",
      win_config = { position = "left", width = 65 },
    },
    keymaps = {
      view = {
        { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diffview" } },
        { "n", "<Tab>", "<cmd>DiffviewToggleFiles<CR>", { desc = "Toggle file panel" } },
        { "n", "<C-o>", jump_back, { desc = "Diff: jump back (stay in the diff)" } },
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
        { "n", "<C-o>", jump_back, { desc = "Diff: jump back (stay in the diff)" } },
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
