return {
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    build = ":MasonUpdate",
    opts = {
      ui = { border = "rounded" },
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    cmd = { "MasonToolsInstall", "MasonToolsUpdate" },
    event = "VeryLazy",
    opts = {
      ensure_installed = {
        "vtsls",
        "eslint-lsp",
        "json-lsp",
        "bash-language-server",
        "marksman",
        "prisma-language-server",
      },
      auto_update = false,
      run_on_start = true,
    },
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      vim.diagnostic.config({
        virtual_text = { prefix = "●", spacing = 2 },
        severity_sort = true,
        update_in_insert = false,
        float = { border = "rounded", source = true },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "✘",
            [vim.diagnostic.severity.WARN] = "▲",
            [vim.diagnostic.severity.HINT] = "⚑",
            [vim.diagnostic.severity.INFO] = "»",
          },
        },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_attach_keymaps", { clear = true }),
        callback = function(event)
          local bufnr = event.buf
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
          end
          map("n", "gd", vim.lsp.buf.definition, "LSP: definition")
          map("n", "gD", vim.lsp.buf.declaration, "LSP: declaration")
          map("n", "gr", vim.lsp.buf.references, "LSP: references")
          map("n", "gi", vim.lsp.buf.implementation, "LSP: implementation")
          map("n", "gy", vim.lsp.buf.type_definition, "LSP: type definition")
          map("n", "K", vim.lsp.buf.hover, "LSP: hover docs")
          map("n", "<leader>rn", vim.lsp.buf.rename, "LSP: rename symbol")
          map("n", "<leader>ca", vim.lsp.buf.code_action, "LSP: code action")
          map("x", "<leader>ca", vim.lsp.buf.code_action, "LSP: code action")
          map("n", "<leader>cd", vim.diagnostic.open_float, "LSP: diagnostic float")
          map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Prev diagnostic")
          map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next diagnostic")
          map("n", "<leader>ih", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
          end, "Toggle inlay hints")
        end,
      })

      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      vim.lsp.config("vtsls", {
        settings = {
          typescript = {
            tsserver = {
              maxTsServerMemory = 8192,
            },
            preferences = {
              importModuleSpecifier = "non-relative",
              importModuleSpecifierEnding = "auto",
            },
            updateImportsOnFileMove = { enabled = "always" },
            inlayHints = {
              parameterNames = { enabled = "all" },
              parameterTypes = { enabled = true },
              variableTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              enumMemberValues = { enabled = true },
            },
            format = { enable = false },
            suggest = { completeFunctionCalls = true },
          },
          javascript = {
            inlayHints = {
              parameterNames = { enabled = "all" },
              parameterTypes = { enabled = true },
              variableTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              enumMemberValues = { enabled = true },
            },
            format = { enable = false },
          },
          vtsls = {
            experimental = {
              completion = { enableServerSideFuzzyMatch = true },
            },
          },
        },
      })

      vim.lsp.enable({ "vtsls", "eslint", "jsonls", "bashls", "marksman", "prismals" })
    end,
  },
}
