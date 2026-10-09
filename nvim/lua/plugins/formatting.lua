-- Work repos use eslint + prettier, personal repos use biome. Resolve per
-- buffer so the same config serves both with no manual switch.
local function uses_biome(bufnr)
  local cached = vim.b[bufnr].uses_biome
  if cached ~= nil then
    return cached
  end
  local found = vim.fs.root(bufnr, { "biome.json", "biome.jsonc" }) ~= nil
  vim.b[bufnr].uses_biome = found
  return found
end

---@param fallback string[] formatters to use when the project has no biome config
local function biome_or(fallback)
  return function(bufnr)
    return uses_biome(bufnr) and { "biome-check" } or fallback
  end
end

-- prettierd detaches a daemon per working directory and never idles out,
-- so record each directory it ran in and stop those daemons on exit.
local prettierd_dirs = {}

local function prettierd_cwd(self, ctx)
  local dir = require("conform.formatters.prettierd").cwd(self, ctx) or vim.fn.getcwd()
  prettierd_dirs[dir] = true
  return dir
end

local function stop_prettierd_daemons()
  for dir in pairs(prettierd_dirs) do
    vim.system({ "prettierd", "stop" }, { cwd = dir, detach = true })
  end
end

return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      mode = { "n", "v" },
      desc = "Format buffer or selection",
    },
    {
      "<leader>cF",
      function()
        vim.g.disable_autoformat = not vim.g.disable_autoformat
        vim.notify("Format on save " .. (vim.g.disable_autoformat and "disabled" or "enabled"))
      end,
      desc = "Toggle format on save (global)",
    },
  },
  opts = {
    formatters_by_ft = {
      typescript = biome_or({ "eslint_d", "prettierd" }),
      typescriptreact = biome_or({ "eslint_d", "prettierd" }),
      javascript = biome_or({ "eslint_d", "prettierd" }),
      javascriptreact = biome_or({ "eslint_d", "prettierd" }),
      json = biome_or({ "prettierd" }),
      jsonc = biome_or({ "prettierd" }),
      css = biome_or({ "prettierd" }),
      -- biome handles neither markdown nor yaml
      markdown = { "prettierd" },
      yaml = { "prettierd" },
      html = { "prettierd" },
      lua = { "stylua" },
      cs = { "csharpier" },
    },
    formatters = {
      prettierd = { cwd = prettierd_cwd },
      -- conform's builtin targets the csharpier >= 0.30 CLI
      -- (`format --stdin-path`); projects pinning 0.28.x in
      -- .config/dotnet-tools.json need `--write-stdout` instead.
      csharpier = {
        command = "dotnet",
        args = { "csharpier", "--write-stdout" },
        stdin = true,
        cwd = function(_, ctx)
          return vim.fs.root(ctx.dirname, function(name)
            return name == "global.json" or name:match("%.sln$") ~= nil
          end)
        end,
      },
    },
    format_on_save = function(bufnr)
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end
      local name = vim.api.nvim_buf_get_name(bufnr)
      local basename = vim.fs.basename(name)
      if basename:match("%.lock$") or basename:match("^.+%-lock%.json$") then
        return
      end
      return { timeout_ms = 1500, lsp_format = "fallback" }
    end,
  },
  init = function()
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = vim.api.nvim_create_augroup("stop_prettierd", { clear = true }),
      callback = stop_prettierd_daemons,
    })
  end,
}
