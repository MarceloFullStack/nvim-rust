-- ╭──────────────────────────────────────────────────────────────╮
-- │  Tema — identidade Git Hydra                                 │
-- │                                                              │
-- │  O tokyonight entra como MOTOR, não como paleta: ele já traz │
-- │  highlights prontos para blink.cmp, snacks, lualine, trouble │
-- │  e dezenas de outros. Trocamos as cores por baixo via        │
-- │  `on_colors` e refinamos o que importa em `on_highlights`.   │
-- │  Resultado: identidade própria, zero plugin sem suporte.     │
-- ╰──────────────────────────────────────────────────────────────╯
local h = require("hydra.palette")

return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night",
      transparent = false,
      terminal_colors = true,
      styles = {
        comments  = { italic = true },
        keywords  = { italic = true },
        functions = { bold = true },
        variables = {},
        sidebars  = "dark",
        floats    = "dark",
      },

      -- ── A paleta inteira vira Hydra ──
      on_colors = function(c)
        c.bg              = h.bg
        c.bg_dark         = h.bg_dark
        c.bg_dark1        = h.bg_dark
        c.bg_float        = h.bg_float
        c.bg_popup        = h.bg_float
        c.bg_sidebar      = h.bg_dark
        c.bg_statusline   = h.bg_dark
        c.bg_highlight    = h.bg_raised
        c.bg_visual       = h.bg_visual
        c.bg_search       = h.purple_dim
        c.fg              = h.fg
        c.fg_dark         = h.fg_dark
        c.fg_float        = h.fg
        c.fg_sidebar      = h.fg_dark
        c.fg_gutter       = h.fg_gutter
        c.comment         = h.comment
        c.border          = h.border
        c.border_highlight= h.border_glow

        -- neon
        c.green    = h.emerald
        c.green1   = h.emerald_dim
        c.green2   = h.emerald_dim
        c.teal     = h.teal
        c.cyan     = h.cyan
        c.blue     = h.cyan          -- funções e chamadas em ciano
        c.blue0    = h.cyan_dim
        c.blue1    = h.cyan
        c.blue2    = h.cyan_dim
        c.blue5    = h.cyan
        c.blue6    = "#a5f3fc"
        c.blue7    = h.border
        c.purple   = h.purple
        c.magenta  = h.purple        -- keywords em violeta
        c.magenta2 = h.purple_dim
        c.red      = h.red
        c.red1     = h.red
        c.orange   = h.orange
        c.yellow   = h.yellow

        -- diagnostics
        c.error = h.red
        c.warning = h.orange
        c.info = h.cyan
        c.hint = h.emerald
        c.todo = h.purple

        c.dark3 = "#2b3a4f"
        c.dark5 = "#3b4c66"
        c.terminal_black = h.bg_raised
      end,

      -- ── Refinos onde a troca automática não basta ──
      on_highlights = function(hl, c)
        -- janelas flutuantes com borda neon discreta
        hl.NormalFloat  = { bg = h.bg_float, fg = h.fg }
        hl.FloatBorder  = { bg = h.bg_float, fg = h.border_glow }
        hl.FloatTitle   = { bg = h.bg_float, fg = h.emerald, bold = true }
        hl.WinSeparator = { fg = h.border, bg = "NONE" }

        -- cursor e linha atual
        hl.CursorLine   = { bg = "#0c141e" }
        hl.CursorLineNr = { fg = h.emerald, bold = true }
        hl.LineNr       = { fg = h.fg_gutter }
        hl.ColorColumn  = { bg = "#0c1219" }

        -- busca
        hl.Search    = { bg = h.purple_dim, fg = h.fg, bold = true }
        hl.IncSearch = { bg = h.emerald, fg = h.bg, bold = true }
        hl.CurSearch = { bg = h.emerald, fg = h.bg, bold = true }
        hl.MatchParen = { fg = h.emerald, bold = true, underline = true }

        -- ── Rust: cada categoria com sua cor do neon ──
        hl["@keyword"]            = { fg = h.purple, italic = true }
        hl["@keyword.function"]   = { fg = h.purple, italic = true }
        hl["@keyword.return"]     = { fg = h.purple, italic = true, bold = true }
        hl["@keyword.operator"]   = { fg = h.purple }
        hl["@conditional"]        = { fg = h.purple, italic = true }
        hl["@repeat"]             = { fg = h.purple, italic = true }

        hl["@function"]           = { fg = h.cyan, bold = true }
        hl["@function.call"]      = { fg = h.cyan }
        hl["@function.method"]    = { fg = h.cyan }
        hl["@function.macro"]     = { fg = h.magenta }
        hl["@constructor"]        = { fg = h.teal }

        hl["@type"]               = { fg = h.emerald }
        hl["@type.builtin"]       = { fg = h.emerald, italic = true }
        hl["@type.definition"]    = { fg = h.emerald, bold = true }
        hl["@lsp.type.struct"]    = { fg = h.emerald }
        hl["@lsp.type.enum"]      = { fg = h.emerald }
        hl["@lsp.type.interface"] = { fg = h.teal }   -- traits

        hl["@string"]             = { fg = h.emerald_dim }
        hl["@number"]             = { fg = h.orange }
        hl["@boolean"]            = { fg = h.orange, bold = true }
        hl["@constant"]           = { fg = h.orange }
        hl["@constant.builtin"]   = { fg = h.orange, bold = true }

        hl["@variable"]           = { fg = h.fg }
        hl["@variable.parameter"] = { fg = "#cbd5e1", italic = true }
        hl["@variable.member"]    = { fg = "#a5f3fc" }   -- campos de struct
        hl["@property"]           = { fg = "#a5f3fc" }
        hl["@attribute"]          = { fg = h.purple_dim } -- #[derive(...)]
        hl["@punctuation.bracket"]= { fg = h.fg_dark }
        hl["@comment"]            = { fg = h.comment, italic = true }
        hl["@lsp.type.lifetime"]  = { fg = h.magenta, italic = true }

        -- inlay hints: presentes, mas discretos
        hl.LspInlayHint = { fg = "#475569", bg = "NONE", italic = true }

        -- diagnostics com fundo levemente tingido
        hl.DiagnosticVirtualTextError = { fg = h.red,     bg = "#1a1014" }
        hl.DiagnosticVirtualTextWarn  = { fg = h.orange,  bg = "#1a1710" }
        hl.DiagnosticVirtualTextInfo  = { fg = h.cyan,    bg = "#0f1a1e" }
        hl.DiagnosticVirtualTextHint  = { fg = h.emerald, bg = "#0d1a16" }

        -- git na gutter
        hl.GitSignsAdd    = { fg = h.emerald }
        hl.GitSignsChange = { fg = h.cyan }
        hl.GitSignsDelete = { fg = h.red }

        -- autocomplete
        hl.BlinkCmpMenu           = { bg = h.bg_float }
        hl.BlinkCmpMenuBorder     = { fg = h.border_glow, bg = h.bg_float }
        hl.BlinkCmpMenuSelection  = { bg = h.bg_visual, bold = true }
        hl.BlinkCmpLabelMatch     = { fg = h.emerald, bold = true }
        hl.BlinkCmpDoc            = { bg = h.bg_float }
        hl.BlinkCmpDocBorder      = { fg = h.border_glow, bg = h.bg_float }

        -- guias de indentação: o escopo ativo acende
        hl.SnacksIndent      = { fg = "#18222f" }
        hl.SnacksIndentScope = { fg = h.emerald_dim }

        -- dashboard: gradiente ciano -> esmeralda do logotipo,
        -- e os nós do grafo em violeta
        local grad = { "#22d3ee", "#26d3e1", "#2ad3d4", "#2ed3c7", "#31d3b3", "#34d399" }
        for i, c in ipairs(grad) do
          hl["HydraGrad" .. i] = { fg = c, bold = true }
        end
        hl.HydraNode = { fg = h.purple }
        hl.HydraEdge = { fg = "#3b4c66" }

        hl.SnacksDashboardHeader = { fg = h.cyan }
        hl.SnacksDashboardIcon   = { fg = h.purple }
        hl.SnacksDashboardDesc   = { fg = h.fg_dark }
        hl.SnacksDashboardKey    = { fg = h.emerald, bold = true }
        hl.SnacksDashboardFooter = { fg = h.comment, italic = true }

        -- palavra sob o cursor
        hl.SnacksWordsUnderCursor = { bg = "#16233a" }
        hl.LspReferenceText  = { bg = "#16233a" }
        hl.LspReferenceRead  = { bg = "#16233a" }
        hl.LspReferenceWrite = { bg = "#1f2440", underline = true }
      end,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")

      -- cores do :terminal embutido, para que lazygit e os CLIs de IA
      -- apareçam na mesma paleta
      vim.g.terminal_color_0  = h.bg_raised
      vim.g.terminal_color_8  = h.fg_gutter
      vim.g.terminal_color_1  = h.red
      vim.g.terminal_color_9  = h.red
      vim.g.terminal_color_2  = h.emerald
      vim.g.terminal_color_10 = h.emerald
      vim.g.terminal_color_3  = h.orange
      vim.g.terminal_color_11 = h.yellow
      vim.g.terminal_color_4  = h.cyan
      vim.g.terminal_color_12 = h.cyan
      vim.g.terminal_color_5  = h.purple
      vim.g.terminal_color_13 = h.purple
      vim.g.terminal_color_6  = h.teal
      vim.g.terminal_color_14 = h.teal
      vim.g.terminal_color_7  = h.fg_dark
      vim.g.terminal_color_15 = h.fg
    end,
  },
}
