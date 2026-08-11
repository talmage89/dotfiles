-- Layered diff review: assign files in a diffview to numbered rings
-- (1 = core), then step through the rings as isolated views — each ring
-- shows only its own files, and everything unassigned forms the outermost
-- "periphery" ring. Assignments persist per repo+branch across sessions.
--
-- The mode is opt-in per view: nothing here activates until toggle() arms
-- the current diffview (bound to <leader>gl). Unarmed views keep stock
-- diffview behavior — no winbar, no ring keys. Armed state is the
-- presence of `view.__layer_pos`, which cycling stamps onto every view it
-- reopens, so the mode follows the review until toggled off.
--
-- Pathspecs are passed as absolute paths: diffview joins *relative* path
-- args onto the cwd, which corrupts them whenever cwd ~= toplevel, while
-- absolute ones pass through untouched. Git accepts absolute paths inside
-- `:(exclude)` magic, and a pathspec of only excludes means "everything
-- else" — which is exactly the periphery.
--
-- The state file is the public contract, so external tools (an AI brief,
-- a script) can seed rings without touching nvim. It is re-read on every
-- operation — never cached — so a write from outside lands on the next
-- keypress even in a running instance. Schema, at
-- `stdpath("state")/diff-layers.json`:
--
--   { "<abs git toplevel>::<branch>": {
--       "rev": "<DiffviewOpen rev arg>",
--       "files": { "<toplevel-relative path>": ring },
--       "names": { "<ring>": "<display name>" }
--   } }
--
-- where ring is a positive integer (1 = core) and both key parts come
-- verbatim from `git rev-parse --show-toplevel` / `--abbrev-ref HEAD`.
-- `names` is optional; an unnamed ring displays as "Ring <n>".
-- Unlisted files are the periphery; omit a repo's key entirely for an
-- unlayered diff. `rev` declares what the review diffs against — e.g.
-- "origin/main...HEAD", "origin/main", or a parent commit sha — and is
-- used when toggle() has to open the view itself; omit it for the
-- working tree. Arming an already-open view keeps that view's rev, and
-- a manual first assignment records the current view's rev as declared.

local M = {}

local state_file = vim.fs.joinpath(vim.fn.stdpath("state"), "diff-layers.json")

local function load_db()
  local ok, lines = pcall(vim.fn.readfile, state_file)
  local ok2, decoded = pcall(vim.json.decode, ok and table.concat(lines, "\n") or "")
  return ok2 and decoded or {}
end

local function save_db(db)
  vim.fn.writefile({ vim.json.encode(db) }, state_file)
end

local function get_view()
  local view = require("diffview.lib").get_current_view()
  if not (view and view.files) then
    vim.notify("DiffLayers: no active diffview", vim.log.levels.WARN)
    return nil
  end
  return view
end

local function key_for(view)
  local toplevel = view.adapter.ctx.toplevel
  local branch = vim.trim(vim.fn.system({ "git", "-C", toplevel, "rev-parse", "--abbrev-ref", "HEAD" }))
  return toplevel .. "::" .. branch
end

-- key derived from the cwd, for when no view exists yet
local function repo_key()
  local toplevel = vim.trim(vim.fn.system({ "git", "rev-parse", "--show-toplevel" }))
  if vim.v.shell_error ~= 0 then
    return nil
  end
  local branch = vim.trim(vim.fn.system({ "git", "-C", toplevel, "rev-parse", "--abbrev-ref", "HEAD" }))
  return toplevel .. "::" .. branch
end

local function rev_words(rev)
  local words = {}
  if rev then
    for word in rev:gmatch("%S+") do
      words[#words + 1] = word
    end
  end
  return words
end

local function files_of(entry)
  return entry and entry.files and next(entry.files) and entry.files or nil
end

local function ring_name(rec, n)
  local names = rec and rec.names
  return names and (names[tostring(n)] or names[n]) or ("Ring %d"):format(n)
end

local function get_armed_view()
  local view = get_view()
  if view and not view.__layer_pos then
    vim.notify("Layers: off — <leader>gl to start layered review")
    return nil
  end
  return view
end

function M.is_armed()
  local view = require("diffview.lib").get_current_view()
  return view ~= nil and view.__layer_pos ~= nil
end

---Assign the file under the cursor to ring `count` (default 1 = core).
---Assigning a file to the ring it is already in unassigns it.
function M.assign(count)
  local view = get_armed_view()
  if not view then
    return
  end
  local entry = view:infer_cur_file(false)
  if not entry then
    vim.notify("DiffLayers: no file under cursor", vim.log.levels.WARN)
    return
  end
  local ring = math.max(count or 0, 1)
  local key = key_for(view)
  local db = load_db()
  local rec = db[key] or { rev = view.rev_arg, files = {} }
  local files = rec.files or {}
  if files[entry.path] == ring then
    files[entry.path] = nil
    vim.notify(("Layers: %s ⇢ periphery"):format(entry.path))
  else
    files[entry.path] = ring
    vim.notify(("Layers: %s ⇢ ring %d"):format(entry.path, ring))
  end
  rec.files = files
  db[key] = next(files) and rec or nil
  save_db(db)
  M.refresh_winbar()
end

local function ring_numbers(layers)
  local nums, seen = {}, {}
  for _, n in pairs(layers) do
    if not seen[n] then
      seen[n] = true
      nums[#nums + 1] = n
    end
  end
  table.sort(nums)
  return nums
end

-- The position cycle is: 0 = all (unfiltered), 1..#nums = rings in
-- ascending order, #nums+1 = periphery. Fresh views carry no stamp and
-- count as "all"; reopened views are stamped with their position.
local function open_position(view, rec, pos)
  local toplevel = view.adapter.ctx.toplevel
  local layers = rec.files
  local nums = ring_numbers(layers)
  local args = rev_words(view.rev_arg)
  local name, detail
  if pos == 0 then
    name = "All"
  else
    args[#args + 1] = "--"
    if pos <= #nums then
      local n, count = nums[pos], 0
      for path, ring in pairs(layers) do
        if ring == n then
          args[#args + 1] = vim.fs.joinpath(toplevel, path)
          count = count + 1
        end
      end
      name = ring_name(rec, n)
      detail = ("%d file%s"):format(count, count == 1 and "" or "s")
    else
      for path in pairs(layers) do
        args[#args + 1] = ":(exclude)" .. vim.fs.joinpath(toplevel, path)
      end
      name = "Periphery"
    end
  end
  local label = ("%s (%d/%d)"):format(name, pos + 1, #nums + 2)
  vim.cmd("DiffviewClose")
  require("diffview").open(args)
  local new_view = require("diffview.lib").get_current_view()
  if new_view then
    new_view.__layer_pos = pos
    new_view.__layer_label = label
  end
  M.refresh_winbar()
  vim.notify("Layers: " .. label .. (detail and " — " .. detail or ""))
end

---Step `dir` (+1 outward / -1 inward) through the layer cycle, wrapping.
function M.cycle(dir)
  local view = get_armed_view()
  if not view then
    return
  end
  local rec = load_db()[key_for(view)]
  if not files_of(rec) then
    vim.notify("DiffLayers: nothing assigned — use [count]L on a file first", vim.log.levels.WARN)
    return
  end
  local seq_len = #ring_numbers(rec.files) + 2
  open_position(view, rec, (view.__layer_pos + dir) % seq_len)
end

function M.list()
  local view = get_armed_view()
  if not view then
    return
  end
  local rec = load_db()[key_for(view)]
  local layers = files_of(rec)
  if not layers then
    vim.notify("DiffLayers: nothing assigned")
    return
  end
  local by_ring = {}
  for path, ring in pairs(layers) do
    by_ring[ring] = by_ring[ring] or {}
    table.insert(by_ring[ring], path)
  end
  local lines = {}
  for _, n in ipairs(ring_numbers(layers)) do
    table.sort(by_ring[n])
    lines[#lines + 1] = ("%s (ring %d):\n  %s"):format(ring_name(rec, n), n, table.concat(by_ring[n], "\n  "))
  end
  vim.notify(table.concat(lines, "\n"))
end

function M.reset()
  local view = get_view()
  if not view then
    return
  end
  local db = load_db()
  db[key_for(view)] = nil
  save_db(db)
  M.refresh_winbar()
  vim.notify("Layers: assignments cleared")
end

---Toggle layered review for the current diffview, opening a working-tree
---view first when none is open. Disarming from a filtered ring reopens
---the full diff.
function M.toggle()
  local lib = require("diffview.lib")
  local view = lib.get_current_view()
  if view and not view.files then
    view = nil
  end
  if not view then
    local key = repo_key()
    local rec = key and load_db()[key]
    require("diffview").open(rev_words(rec and rec.rev))
    view = lib.get_current_view()
    if not view then
      return
    end
  end
  if view.__layer_pos then
    local pos = view.__layer_pos
    view.__layer_pos = nil
    view.__layer_label = nil
    if pos > 0 then
      local args = rev_words(view.rev_arg)
      vim.cmd("DiffviewClose")
      require("diffview").open(args)
    end
    M.refresh_winbar()
    vim.notify("Layers: off")
  else
    view.__layer_pos = 0
    M.refresh_winbar()
    vim.notify("Layers: on")
  end
end

---Show the layer position in the file panel's winbar of an armed view;
---cleared everywhere else.
function M.refresh_winbar()
  vim.schedule(function()
    local view = require("diffview.lib").get_current_view()
    if not (view and view.files and view.panel and view.panel:is_open()) then
      return
    end
    local win = view.panel.winid
    if not (win and vim.api.nvim_win_is_valid(win)) then
      return
    end
    if not view.__layer_pos then
      vim.wo[win].winbar = ""
      return
    end
    local layers = files_of(load_db()[key_for(view)])
    local label = not layers and "no rings assigned"
      or view.__layer_label
      or ("All (1/%d)"):format(#ring_numbers(layers) + 2)
    vim.wo[win].winbar = "%#DiffviewFilePanelTitle# " .. label .. "%*"
  end)
end

---Keep the winbar alive across panel toggles and fresh view opens; called
---once from the diffview spec's config.
function M.attach()
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup("DiffviewLayers", { clear = true }),
    callback = function(ev)
      if vim.bo[ev.buf].filetype == "DiffviewFiles" then
        M.refresh_winbar()
      end
    end,
  })
end

return M
