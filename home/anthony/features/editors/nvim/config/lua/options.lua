require "nvchad.options"

-- add yours here!

local o = vim.opt
o.colorcolumn = "80"

o.laststatus = 3 -- global statusline
o.showmode = false

o.clipboard = "unnamedplus"
o.cursorline = true

-- Indenting
o.expandtab = true
o.shiftwidth = 2
o.smartindent = true
o.tabstop = 2
o.softtabstop = 2

o.fillchars = { eob = " " }
o.ignorecase = true
o.smartcase = true
o.mouse = "a"

-- Numbers
o.number = true
o.numberwidth = 2
o.ruler = false

-- disable nvim intro
o.shortmess:append "sI"

o.signcolumn = "yes"
o.splitbelow = true
o.splitright = true
o.termguicolors = true
o.timeoutlen = 400
o.undofile = true

-- interval for writing swap file to disk, also used by gitsigns
o.updatetime = 250

-- go to previous/next line with h,l,left arrow and right arrow
-- when cursor reaches end/beginning of line
o.whichwrap:append "<>[]hl"

-- Update Avante highlight groups
vim.cmd [[
  hi! link AvanteSidebarWinSeparator NormalFloat
  hi! link AvanteSidebarWinHorizontalSeparator NormalFloat
]]

-- Windsurf settings
vim.g.codeium_disable_bindings = 1
