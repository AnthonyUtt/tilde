if vim.g.vscode then
  require "vscode-config"
else
  vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
  vim.g.mapleader = " "

  -- Shim for Neovim 0.13-dev: directive handlers now receive captures as
  -- TSNode[] lists instead of single TSNode values, but nvim-treesitter's
  -- handlers still expect single nodes. Wrap add_directive to auto-unwrap.
  if vim.fn.has "nvim-0.13" == 1 then
    local original_add_directive = vim.treesitter.query.add_directive
    vim.treesitter.query.add_directive = function(name, handler, opts)
      local wrapped = function(match, pattern, source, predicate, metadata)
        local unwrapped = {}
        for capture_id, nodes in pairs(match) do
          if type(nodes) == "table" and not nodes.range then
            unwrapped[capture_id] = nodes[1]
          else
            unwrapped[capture_id] = nodes
          end
        end
        return handler(unwrapped, pattern, source, predicate, metadata)
      end
      return original_add_directive(name, wrapped, opts)
    end
  end

  -- bootstrap lazy and all plugins
  local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

  if not vim.uv.fs_stat(lazypath) then
    local repo = "https://github.com/folke/lazy.nvim.git"
    vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
  end

  vim.opt.rtp:prepend(lazypath)

  local lazy_config = require "configs.lazy"

  -- load plugins
  require("lazy").setup({
    {
      "NvChad/NvChad",
      lazy = false,
      branch = "v2.5",
      import = "nvchad.plugins",
    },

    { import = "plugins" },
  }, lazy_config)

  -- load theme
  dofile(vim.g.base46_cache .. "defaults")
  dofile(vim.g.base46_cache .. "statusline")

  require "options"
  require "nvchad.autocmds"

  vim.schedule(function()
    require "mappings"
  end)
end
