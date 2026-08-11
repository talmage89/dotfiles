-- Layered diff review: assign files in a diffview to numbered rings
-- (1 = core), then step through the rings as isolated views — each ring
-- shows only its own files, and everything unassigned forms the outermost
-- "periphery" ring. Assignments persist per repo+branch across sessions.
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
--   { "<abs git toplevel>::<branch>": { "<toplevel-relative path>": ring } }
--
-- where ring is a positive integer (1 = core) and both key parts come
-- verbatim from `git rev-parse --show-toplevel` / `--abbrev-ref HEAD`.
-- Unlisted files are the periphery; omit a repo's key entirely for an
-- unlayered diff.

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

---Assign the file under the cursor to ring `count` (default 1 = core).
---Assigning a file to the ring it is already in unassigns it.
function M.assign(count)
  local view = get_view()
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
  local layers = db[key] or {}
  if layers[entry.path] == ring then
    layers[entry.path] = nil
    vim.notify(("Layers: %s ⇢ periphery"):format(entry.path))
  else
    layers[entry.path] = ring
    vim.notify(("Layers: %s ⇢ ring %d"):format(entry.path, ring))
  end
  db[key] = next(layers) and layers or nil
  save_db(db)
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
local function open_position(view, layers, pos)
  local toplevel = view.adapter.ctx.toplevel
  local rev_arg = view.rev_arg
  local nums = ring_numbers(layers)
  local args = {}
  if rev_arg then
    for word in rev_arg:gmatch("%S+") do
      args[#args + 1] = word
    end
  end
  local label
  if pos == 0 then
    label = "all files"
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
      label = ("ring %d (%d file%s)"):format(n, count, count == 1 and "" or "s")
    else
      for path in pairs(layers) do
        args[#args + 1] = ":(exclude)" .. vim.fs.joinpath(toplevel, path)
      end
      label = "periphery"
    end
  end
  vim.cmd("DiffviewClose")
  require("diffview").open(args)
  local new_view = require("diffview.lib").get_current_view()
  if new_view then
    new_view.__layer_pos = pos
  end
  vim.notify("Layers: " .. label)
end

---Step `dir` (+1 outward / -1 inward) through the layer cycle, wrapping.
function M.cycle(dir)
  local view = get_view()
  if not view then
    return
  end
  local layers = load_db()[key_for(view)]
  if not layers then
    vim.notify("DiffLayers: nothing assigned — use [count]L on a file first", vim.log.levels.WARN)
    return
  end
  local seq_len = #ring_numbers(layers) + 2
  open_position(view, layers, ((view.__layer_pos or 0) + dir) % seq_len)
end

function M.list()
  local view = get_view()
  if not view then
    return
  end
  local layers = load_db()[key_for(view)]
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
    lines[#lines + 1] = ("ring %d:\n  %s"):format(n, table.concat(by_ring[n], "\n  "))
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
  vim.notify("Layers: assignments cleared")
end

return M
