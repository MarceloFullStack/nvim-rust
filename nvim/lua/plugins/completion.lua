-- ╭─ Autocomplete (blink.cmp) ─╮
-- blink.cmp é o sucessor do nvim-cmp: fuzzy matcher escrito em Rust,
-- ~0.5ms por keystroke, configuração muito menor.
--
-- DIVISÃO DE TECLAS (proposital, pra não haver ambiguidade):
--   <C-y>  aceita o item do LSP (o que o compilador sabe)
--   <Tab>  aceita a sugestão da IA (Supermaven — ver ai.lua)
return {
  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    version = "1.*", -- usa binário pré-compilado do fuzzy matcher
    dependencies = {
      { "rafamadriz/friendly-snippets" },
      {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        build = "make install_jsregexp",
        config = function()
          require("luasnip.loaders.from_vscode").lazy_load()
        end,
      },
    },
    opts = {
      snippets = { preset = "luasnip" },

      keymap = {
        preset = "default",
        -- <C-space> abre o menu / abre a documentação
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-y>"]     = { "select_and_accept" },        -- aceitar
        ["<C-e>"]     = { "hide", "fallback" },         -- cancelar
        ["<C-n>"]     = { "select_next", "fallback" },
        ["<C-p>"]     = { "select_prev", "fallback" },
        ["<C-b>"]     = { "scroll_documentation_up", "fallback" },
        ["<C-f>"]     = { "scroll_documentation_down", "fallback" },
        -- navegar pelos placeholders do snippet
        ["<C-l>"]     = { "snippet_forward", "fallback" },
        ["<C-h>"]     = { "snippet_backward", "fallback" },
      },

      appearance = { nerd_font_variant = "mono" },

      completion = {
        accept = { auto_brackets = { enabled = true } }, -- completa fn -> fn()
        list = { selection = { preselect = false, auto_insert = false } },
        menu = {
          border = "rounded",
          draw = {
            treesitter = { "lsp" },
            columns = {
              { "kind_icon" },
              { "label", "label_description", gap = 1 },
              { "source_name" },
            },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = { border = "rounded" },
        },
        -- ghost text DESLIGADO: esse espaço visual é do Supermaven
        ghost_text = { enabled = false },
      },

      signature = { enabled = true, window = { border = "rounded" } },

      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        per_filetype = {
          lua = { inherit_defaults = true, "lazydev" },
        },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100, -- prioriza sobre o lua_ls
          },
        },
      },

      cmdline = {
        enabled = true,
        keymap = { preset = "cmdline" },
        completion = { menu = { auto_show = true } },
      },

      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
  },
}
