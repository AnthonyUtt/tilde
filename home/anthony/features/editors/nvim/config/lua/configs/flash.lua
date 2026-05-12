local M = {}

M.opts = {
  search = {
    mode = function(str)
      return "\\<" .. str
    end,
  },
  modes = {
    search = {
      enabled = true,
    },
  },
}

M.mappings = {
  -- { mode, mapping, effect, options },
  { {"n", "x", "o" }, "<leader>s", function() require("flash").treesitter() end, { desc = "Flash Treesitter" } },
}

return M
