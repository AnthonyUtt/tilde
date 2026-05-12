return {
  "AnthonyUtt/lspcontainers.nvim",
  "ethanholz/nvim-lastplace",
  "onsails/lspkind.nvim",
  {
    "michaelrommel/nvim-silicon",
    lazy = true,
    cmd = "Silicon",
    opts = {
      font = "ComicShannsMono Nerd Font=34",
      to_clipboard = true,
    },
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = require("configs.flash").opts,
  },
  -- {
  --   'mrcjkb/rustaceanvim',
  --   version = '^5', -- Recommended
  --   lazy = false, -- This plugin is already lazy
  --   config = function()
  --     vim.g.rustaceanvim = {
  --       server = {
  --         default_settings = {
  --           ["rust-analyzer"] = {
  --             cargo = {
  --               targetDir = "./.rust-analyzer"
  --             }
  --           }
  --         }
  --       }
  --     }
  --   end,
  -- },
  {
    "hrsh7th/nvim-cmp",
    opts = function()
      return require "configs.cmp"
    end,
  },
  {
    "nvim-tree/nvim-tree.lua",
    opts = function()
      return require "configs.nvimtree".opts
    end,
    init = function()
      require("configs.nvimtree").init()
    end,
  },
  {
  	"nvim-treesitter/nvim-treesitter",
  	opts = {
  		ensure_installed = {
        "bash",
        "c",
        "cmake",
        "cpp",
        "css",
        "csv",
        "diff",
        "dockerfile",
        "dot",
        "gdscript",
        "gdshader",
        "git_config",
        "git_rebase",
        "gitattributes",
        "gitcommit",
        "gitignore",
        "glsl",
        "graphql",
        "hlsl",
        "html",
        "javascript",
        "jinja",
        "json",
        "kdl",
        "liquid",
        "lua",
        "luadoc",
        "make",
        "markdown",
        "markdown_inline",
        "nix",
        "python",
        "ruby",
        "rust",
        "scss",
        "sql",
        "toml",
        "tsv",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
  		},
  	},
  },
  {
    -- Disable NvChad defaults
    {
      "neovim/nvim-lspconfig",
      enable = false,
    },
    {
      "williamboman/mason.nvim",
      enable = false,
    },
  },
  {
    -- Other
    {
      "Glench/Vim-Jinja2-Syntax",
      init = function()
        vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
          pattern = { "*.tera", "*.njk" },
          command = "set ft=jinja",
        })
      end,
    },
    {
      "tpope/vim-rails",
      config = function()
        -- disable autocmd set filetype=eruby.yaml
        vim.api.nvim_create_autocmd({ "BufNewFile", "BufReadPost" }, {
          pattern = { "*.yml" },
          callback = function()
            vim.bo.filetype = "yaml"
          end,
        })
      end,
    },
    {
      "EdenEast/nightfox.nvim",
      config = function()
        require('nightfox').setup({
          transparent = true,
          terminal_colors = false,
          dim_inactive = false,
        })
        vim.cmd("colorscheme duskfox")
      end,
    },
  },
}
