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
  end,
}
