require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })

-- Allow moving the cursor through wrapped lines with j, k, <Up> and <Down>
-- http://www.reddit.com/r/vim/comments/2k4cbr/problem_with_gj_and_gk/
-- empty mode is same as using <cmd> :map
-- also don't use g[j|k] when in operator pending mode, so it doesn't alter d, y or c behaviour
map('n', 'j', 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', { expr = true })
map('n', 'k', 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', { expr = true })

map('v', '<', '<gv', { noremap = true, silent = true })
map('v', '>', '>gv', { noremap = true, silent = true })

map("x", "<leader>ss", ":Silicon <CR>", { desc = "Screenshot selection (silicon)" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

local function load_mappings(mappings)
  for _, v in ipairs(mappings) do
    map(v[1], v[2], v[3], v[4])
  end
end

local nvimtree = require("configs.nvimtree").mappings
load_mappings(nvimtree)

local lsp = require("configs.lspconfig").mappings
load_mappings(lsp)

local gitsigns = require("configs.gitsigns").mappings
load_mappings(gitsigns)

local flash = require("configs.flash").mappings
load_mappings(flash)
