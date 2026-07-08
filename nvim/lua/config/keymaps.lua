vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })

map("n", "<leader>w", "<cmd>write<CR>", { desc = "Write file" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit window" })
map("n", "<leader>Q", "<cmd>quitall<CR>", { desc = "Quit all" })

map("n", "<C-h>", "<C-w>h", { desc = "Window: left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window: down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window: up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window: right" })

map("v", "<", "<gv", { desc = "Indent left, keep selection" })
map("v", ">", ">gv", { desc = "Indent right, keep selection" })
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

map("n", "n", "nzzzv", { desc = "Next match, centered" })
map("n", "N", "Nzzzv", { desc = "Prev match, centered" })

map("n", "<leader>bn", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
-- <leader>bd lives in plugins/picker.lua (Snacks.bufdelete preserves window layout)

local function send_buffer_to_other_window()
  local wins = vim.tbl_filter(function(w)
    return vim.api.nvim_win_get_config(w).relative == "" -- ignore floating windows
  end, vim.api.nvim_tabpage_list_wins(0))
  if #wins < 2 then
    vim.notify("No other window to send to", vim.log.levels.WARN)
    return
  end
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()
  local alt = vim.fn.bufnr("#")
  if alt > 0 and alt ~= buf and vim.fn.buflisted(alt) == 1 then
    vim.api.nvim_win_set_buf(win, alt)
  else
    vim.cmd("bprevious")
  end
  vim.cmd("wincmd p")
  if vim.api.nvim_get_current_win() == win then
    vim.cmd("wincmd w")
  end
  vim.api.nvim_set_current_buf(buf)
end

map("n", "<leader>bs", send_buffer_to_other_window, { desc = "Send buffer to other split, restore previous here" })

map("i", "<M-BS>", "<C-w>", { desc = "Delete word backward (Opt+BS)" })
map("c", "<M-BS>", "<C-w>", { desc = "Delete word backward (Opt+BS)" })

map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

local function yank_path(modifier, label)
  return function()
    local path = vim.fn.expand("%" .. modifier)
    vim.fn.setreg("+", path)
    vim.notify("Copied " .. label .. ": " .. path)
  end
end

map("n", "<leader>yp", yank_path(":.", "relative path"), { desc = "Yank: relative path" })
map("n", "<leader>yP", yank_path(":p", "absolute path"), { desc = "Yank: absolute path" })
map("n", "<leader>yf", yank_path(":t", "filename"), { desc = "Yank: filename" })
