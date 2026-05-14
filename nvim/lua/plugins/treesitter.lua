return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install({
      "typescript",
      "tsx",
      "javascript",
      "jsdoc",
      "json",
      "jsonc",
      "markdown",
      "markdown_inline",
      "bash",
      "lua",
      "luadoc",
      "vim",
      "vimdoc",
      "diff",
      "git_config",
      "gitcommit",
      "gitignore",
      "git_rebase",
      "yaml",
      "toml",
      "regex",
      "xml",
      "html",
      "css",
    })

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
      callback = function(args)
        local bufnr = args.buf
        if pcall(vim.treesitter.start, bufnr) then
          vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
