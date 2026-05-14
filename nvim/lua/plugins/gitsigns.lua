return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "" },
      topdelete = { text = "" },
      changedelete = { text = "▎" },
      untracked = { text = "▎" },
    },
    signs_staged = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "" },
      topdelete = { text = "" },
      changedelete = { text = "▎" },
    },
    current_line_blame = false,
    current_line_blame_opts = {
      virt_text_pos = "eol",
      delay = 500,
    },
    preview_config = { border = "rounded" },
    on_attach = function(bufnr)
      local gs = require("gitsigns")
      local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
      end

      map("n", "]c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]c", bang = true })
        else
          gs.nav_hunk("next")
        end
      end, "Next hunk")

      map("n", "[c", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[c", bang = true })
        else
          gs.nav_hunk("prev")
        end
      end, "Prev hunk")

      map("n", "<leader>hp", gs.preview_hunk, "Hunk: preview")
      map("n", "<leader>hs", gs.stage_hunk, "Hunk: stage/unstage")
      map("v", "<leader>hs", function()
        gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, "Hunk: stage range")
      map("n", "<leader>hr", gs.reset_hunk, "Hunk: reset")
      map("v", "<leader>hr", function()
        gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
      end, "Hunk: reset range")
      map("n", "<leader>hS", gs.stage_buffer, "Buffer: stage all")
      map("n", "<leader>hR", gs.reset_buffer, "Buffer: reset all")
      map("n", "<leader>hd", gs.diffthis, "Diff this buffer")
      map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
      map("n", "<leader>tb", gs.toggle_current_line_blame, "Toggle: inline blame")
      map("n", "<leader>td", gs.toggle_deleted, "Toggle: deleted lines")

      map({ "o", "x" }, "ih", "<cmd>Gitsigns select_hunk<CR>", "Text object: hunk")
    end,
  },
}
