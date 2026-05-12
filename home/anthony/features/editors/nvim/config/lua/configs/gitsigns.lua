local M = {}

M.mappings = {
  -- { mode, mapping, effect, options },
  {
    "n",
    "<leader>gb",
    function()
      require("gitsigns").blame_line({ full = true })
    end,
    { desc = "Blame line" }
  },
}

return M
