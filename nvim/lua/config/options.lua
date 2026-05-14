local o = vim.o

o.number = true
o.relativenumber = true
o.cursorline = true
o.signcolumn = "yes"
o.scrolloff = 8
o.sidescrolloff = 8

o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.softtabstop = 2
o.smartindent = true
o.breakindent = true
o.wrap = true
o.linebreak = true

o.ignorecase = true
o.smartcase = true
o.inccommand = "split"
o.hlsearch = true

o.splitright = true
o.splitbelow = true

o.termguicolors = true
o.background = "dark"

o.undofile = true
o.swapfile = false
o.backup = false

o.updatetime = 250
o.timeoutlen = 400

o.mouse = "a"
o.clipboard = "unnamedplus"
o.confirm = true

o.list = true
o.listchars = "tab:» ,trail:·,nbsp:␣"

o.completeopt = "menu,menuone,noselect"
o.pumheight = 12
o.winborder = "rounded"

o.cmdheight = 0

vim.g.have_nerd_font = true

local function tabline()
  local pieces = {}
  for i = 1, vim.fn.tabpagenr("$") do
    local buflist = vim.fn.tabpagebuflist(i)
    local bufnr = buflist[vim.fn.tabpagewinnr(i)]
    local name = vim.fn.bufname(bufnr)
    local label = name == "" and "[No Name]" or vim.fs.basename(name)
    local modified = false
    for _, b in ipairs(buflist) do
      if vim.bo[b].modified then
        modified = true
        break
      end
    end
    local hl = i == vim.fn.tabpagenr() and "%#TabLineSel#" or "%#TabLine#"
    pieces[#pieces + 1] = hl .. "%" .. i .. "T " .. (modified and "+ " or "") .. label .. " "
  end
  return table.concat(pieces) .. "%#TabLineFill#%T"
end

_G.tabline = tabline
vim.o.tabline = "%!v:lua.tabline()"
