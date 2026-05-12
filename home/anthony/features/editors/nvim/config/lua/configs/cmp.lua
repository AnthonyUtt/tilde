local cmp = require "cmp"
local opts = {
  preselect = cmp.PreselectMode.None,
  completion = {
    completeopt = "menu,menuone,noselect,popup",
  },
  snippet = {
    expand = function(args)
      -- no op
    end,
  },
  window = {
    completion = {
      winhighlight = "Normal:CmpPmenu,CursorLine:CmpSel,Search:PmenuSel",
      scrollbar = false,
    },
    documentation = {
      -- border = border "CmpDocBorder",
      winhighlight = "Normal:CmpDoc",
    },
  },
  formatting = {
    fields = { "abbr", "kind", "menu" },
    format = function(entry, vim_item)
      vim_item.kind = require("lspkind").presets.default[vim_item.kind] .. " " .. vim_item.kind
      vim_item.menu = ({
        nvim_lsp = "[LSP]",
        buffer = "[BUF]",
        path = "[PATH]",
        calc = "[CALC]",
        vsnip = "[SNIP]",
        spell = "[SPELL]",
        emoji = "[EMOJI]",
      })[entry.source.name]
      return vim_item
    end,
  },
  mapping = {
    ["<CR>"] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Replace,
      select = false,
    }),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end, {
      "i",
      "s",
    }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end, {
      "i",
      "s",
    })
  },
  sources = {
    { name = "nvim_lsp" },
    { name = "buffer" },
    { name = "path" },
  },
}

return opts
