local M = {}

local errorformat = table.concat({
  "%f(%l\\,%c): %trror TS%n: %m",
  "%f(%l\\,%c): %tarning TS%n: %m",
}, ",")

---@type vim.SystemObj?
local job

local spinner = { timer = nil, frame = 0, prefix = "" }

local function spinner_stop()
  if not spinner.timer then
    return
  end
  spinner.timer:stop()
  spinner.timer:close()
  spinner.timer = nil
  vim.api.nvim_echo({ { "" } }, false, {})
  if vim.api.nvim_get_mode().mode ~= "c" then
    vim.o.cmdheight = 0
  end
end

local function spinner_start(prefix)
  if spinner.timer then
    return
  end
  spinner.prefix = prefix
  spinner.frame = 0
  spinner.timer = vim.uv.new_timer()
  spinner.timer:start(
    0,
    350,
    vim.schedule_wrap(function()
      local frames = { ".", "..", "..." }
      spinner.frame = (spinner.frame % #frames) + 1
      if vim.o.cmdheight == 0 then
        vim.o.cmdheight = 1
      end
      vim.api.nvim_echo({ { spinner.prefix .. frames[spinner.frame], "DiagnosticHint" } }, false, {})
    end)
  )
end

local function find_root()
  local start = vim.fn.expand("%:p:h")
  if start == "" then
    start = vim.fn.getcwd()
  end
  local marker = vim.fs.find({ "tsconfig.json", "package.json" }, { upward = true, path = start })[1]
  return marker and vim.fs.dirname(marker) or vim.fn.getcwd()
end

function M.check()
  if job then
    vim.notify("tsgo: already running (use :TsCheckCancel)", vim.log.levels.WARN)
    return
  end
  local cwd = find_root()
  spinner_start("tsgo: checking " .. vim.fs.basename(cwd))
  job = vim.system(
    { "npx", "tsgo", "--noEmit", "--pretty", "false" },
    { cwd = cwd, text = true },
    function(result)
      vim.schedule(function()
        job = nil
        spinner_stop()
        local out = (result.stdout or "") .. (result.stderr or "")
        local lines = vim.split(out, "\n", { plain = true, trimempty = true })
        vim.fn.setqflist({}, " ", { title = "tsgo", lines = lines, efm = errorformat })
        local count = #vim.fn.getqflist()
        if count == 0 then
          vim.cmd("cclose")
          vim.notify("tsgo: no errors", vim.log.levels.INFO)
        else
          vim.cmd("botright cwindow")
          vim.notify(("tsgo: %d issue(s)"):format(count), vim.log.levels.WARN)
        end
      end)
    end
  )
end

function M.cancel()
  if not job then
    vim.notify("tsgo: nothing to cancel", vim.log.levels.INFO)
    return
  end
  job:kill(15)
  job = nil
  spinner_stop()
  vim.notify("tsgo: cancelled", vim.log.levels.WARN)
end

local function toggle_quickfix()
  for _, w in ipairs(vim.fn.getwininfo()) do
    if w.quickfix == 1 then
      vim.cmd("cclose")
      return
    end
  end
  vim.cmd("botright copen")
end

vim.api.nvim_create_user_command("TsCheck", M.check, { desc = "tsgo --noEmit → quickfix" })
vim.api.nvim_create_user_command("TsCheckCancel", M.cancel, { desc = "Cancel running tsgo check" })

local map = vim.keymap.set
map("n", "<leader>tc", M.check, { desc = "TS: check project (tsgo)" })
map("n", "<leader>tC", M.cancel, { desc = "TS: cancel check" })
map("n", "<leader>tt", toggle_quickfix, { desc = "Toggle quickfix window" })

map("n", "]q", "<cmd>cnext<CR>zz", { desc = "Next quickfix item" })
map("n", "[q", "<cmd>cprevious<CR>zz", { desc = "Prev quickfix item" })
map("n", "]Q", "<cmd>clast<CR>zz", { desc = "Last quickfix item" })
map("n", "[Q", "<cmd>cfirst<CR>zz", { desc = "First quickfix item" })

return M
