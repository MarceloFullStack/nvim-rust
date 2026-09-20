-- ╭─ Aparência: tema, statusline, abas, notificações, dashboard ─╮
return {

  -- (o tema mora em lua/plugins/theme.lua)

  -- ── snacks.nvim: o canivete suíço do folke ─────────────────
  -- Substitui telescope, nvim-tree, notify, dressing, indent-blankline,
  -- alpha/dashboard e mais — tudo num plugin só, sem conflito entre eles.
  {
    "folke/snacks.nvim",
    priority = 900,
    lazy = false,
    opts = {
      bigfile = { enabled = true },   -- desliga syntax/LSP em arquivos gigantes
      quickfile = { enabled = true },
      indent = {                      -- guias de indentação + escopo animado
        enabled = true,
        animate = { enabled = true, duration = { step = 15, total = 200 } },
      },
      input = { enabled = true },     -- vim.ui.input bonito (usado pelo rename do LSP)
      notifier = {                    -- notificações no canto
        enabled = true,
        timeout = 3000,
        style = "compact",
      },
      picker = {                      -- fuzzy finder (substitui telescope)
        enabled = true,
        layout = { preset = "telescope" },
        sources = {
          files = { hidden = true },
          grep  = { hidden = true },
          explorer = { hidden = true },
        },
      },
      explorer = { enabled = true },   -- árvore de arquivos lateral
      scope = { enabled = true },      -- textobjects de escopo por indentação
      scroll = { enabled = true },     -- scroll suave
      statuscolumn = { enabled = true },
      words = { enabled = true },      -- destaca todas as ocorrências da palavra sob o cursor
      terminal = { enabled = true },
      lazygit = { enabled = true },
      dashboard = {
        enabled = true,
        sections = {
-- header desenhado à mão: gradiente ciano -> esmeralda nas
          -- linhas (as cores do logotipo) e o grafo da hidra em violeta.
          -- Os grupos HydraGrad*/HydraNode/HydraEdge vêm do tema.
          {
            align = "center",
            padding = 2,
            text = {
              { " ███╗   ██╗ ███████╗ ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗\n", hl = "HydraGrad1" },
              { " ████╗  ██║ ██╔════╝██╔═══██╗ ██║   ██║ ██║ ████╗ ████║\n", hl = "HydraGrad2" },
              { " ██╔██╗ ██║ █████╗  ██║   ██║ ██║   ██║ ██║ ██╔████╔██║\n", hl = "HydraGrad3" },
              { " ██║╚██╗██║ ██╔══╝  ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║\n", hl = "HydraGrad4" },
              { " ██║ ╚████║ ███████╗╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║\n", hl = "HydraGrad5" },
              { " ╚═╝  ╚═══╝ ╚══════╝ ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝\n", hl = "HydraGrad6" },
              { "\n" },
              { "        ⬡", hl = "HydraNode" }, { "───────", hl = "HydraEdge" },
              { "⬡",         hl = "HydraNode" }, { "───────", hl = "HydraEdge" },
              { "⬡",         hl = "HydraNode" }, { "───────", hl = "HydraEdge" },
              { "⬡",         hl = "HydraNode" }, { "───────", hl = "HydraEdge" },
              { "⬡\n",       hl = "HydraNode" },
            },
          },
          {
            align = "center",
            padding = 1,
            text = { { "rust  ·  ai  ·  speed", hl = "SnacksDashboardFooter" } },
          },
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup" },
        },
        preset = {
          keys = {
            { icon = "  ", key = "f", desc = "Buscar arquivo",   action = ":lua Snacks.dashboard.pick('files')" },
            { icon = "  ", key = "n", desc = "Arquivo novo",     action = ":ene | startinsert" },
            { icon = "  ", key = "g", desc = "Grep no projeto",  action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = "  ", key = "r", desc = "Recentes",         action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = "  ", key = "s", desc = "Restaurar sessão", section = "session" },
            { icon = "󰒲  ", key = "l", desc = "Lazy (plugins)",   action = ":Lazy" },
            { icon = "  ", key = "m", desc = "Mason (LSP/tools)", action = ":Mason" },
            { icon = "  ", key = "q", desc = "Sair",             action = ":qa" },
          },
        },
      },
      styles = {
        notification = { wo = { wrap = true } },
      },
    },
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          -- atalhos de debug globais, úteis pra inspecionar coisas
          _G.dd = function(...) Snacks.debug.inspect(...) end
          _G.bt = function() Snacks.debug.backtrace() end
          vim.print = _G.dd
        end,
      })
    end,
  },

  -- ── Statusline ─────────────────────────────────────────────
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = function()
      local h = require("hydra.palette")
      -- tema da statusline derivado da paleta: cada modo tem sua cor do neon
      local function mode(fg)
        return { a = { bg = fg, fg = h.bg, gui = "bold" },
                 b = { bg = h.bg_raised, fg = fg },
                 c = { bg = h.bg_dark, fg = h.fg_dark } }
      end
      local theme = {
        normal   = mode(h.emerald),
        insert   = mode(h.cyan),
        visual   = mode(h.purple),
        replace  = mode(h.red),
        command  = mode(h.orange),
        terminal = mode(h.teal),
        inactive = { a = { bg = h.bg_dark, fg = h.comment },
                     b = { bg = h.bg_dark, fg = h.comment },
                     c = { bg = h.bg_dark, fg = h.comment } },
      }
      return {
        options = {
          theme = theme,
          globalstatus = true,
          component_separators = { left = "│", right = "│" },
          section_separators = { left = "", right = "" },
          disabled_filetypes = { statusline = { "dashboard", "snacks_dashboard" } },
        },
        sections = {
          lualine_a = { { "mode", fmt = function(s) return s:sub(1, 3) end } },
          lualine_b = { "branch" },
          lualine_c = {
            { "diagnostics", symbols = { error = " ", warn = " ", info = " ", hint = " " } },
            { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
            { "filename", path = 1 }, -- 1 = caminho relativo ao cwd
          },
          lualine_x = {
            -- mostra o que o Sidekick/IA está fazendo
            {
              function() return require("sidekick.status").get() and "AI" or "" end,
              cond = function() return package.loaded["sidekick"] ~= nil end,
              color = { fg = h.emerald, gui = "bold" },
            },
            { "diff", symbols = { added = "+", modified = "~", removed = "-" } },
          },
          lualine_y = { "progress", "location" },
          lualine_z = { function() return " " .. os.date("%H:%M") end },
        },
        extensions = { "lazy", "mason", "trouble", "quickfix", "nvim-dap-ui" },
      }
    end,
  },

  -- ── Abas de buffers no topo ────────────────────────────────
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      highlights = function()
        local h = require("hydra.palette")
        return {
          fill = { bg = h.bg_dark },
          background = { bg = h.bg_dark, fg = h.comment },
          buffer_selected = { bg = h.bg, fg = h.emerald, bold = true, italic = false },
          buffer_visible = { bg = h.bg_dark, fg = h.fg_dark },
          separator = { bg = h.bg_dark, fg = h.bg_dark },
          separator_selected = { bg = h.bg, fg = h.bg_dark },
          indicator_selected = { bg = h.bg, fg = h.emerald },
          modified_selected = { bg = h.bg, fg = h.orange },
          error_selected = { bg = h.bg, fg = h.red, bold = true },
          warning_selected = { bg = h.bg, fg = h.orange, bold = true },
        }
      end,
      options = {
        close_command = function(n) Snacks.bufdelete(n) end,
        right_mouse_command = function(n) Snacks.bufdelete(n) end,
        diagnostics = "nvim_lsp",
        always_show_bufferline = false,
        separator_style = "thin",
        diagnostics_indicator = function(_, _, diag)
          return (diag.error and " " .. diag.error .. " " or "") .. (diag.warning and " " .. diag.warning or "")
        end,
        offsets = {
          { filetype = "snacks_layout_box", text = "Explorer", highlight = "Directory", text_align = "left" },
        },
      },
    },
  },

  -- ── which-key: mostra os atalhos disponíveis quando hesita ─
  -- Esse é o plugin que te transforma em ninja: aperte <space> e espere.
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
      delay = 300,
      spec = {
        { "<leader>f", group = "find / files" },
        { "<leader>s", group = "search" },
        { "<leader>g", group = "git" },
        { "<leader>c", group = "code / lsp" },
        { "<leader>a", group = "ai" },
        { "<leader>d", group = "debug" },
        { "<leader>r", group = "rust" },
        { "<leader>x", group = "diagnostics / trouble" },
        { "<leader>b", group = "buffer" },
        { "<leader>u", group = "ui / toggles" },
        { "<leader>q", group = "quit / session" },
        { "g", group = "goto" },
        { "z", group = "fold" },
        { "]", group = "próximo" },
        { "[", group = "anterior" },
      },
    },
    keys = {
      { "<leader>?", function() require("which-key").show({ global = false }) end, desc = "Atalhos do buffer" },
    },
  },

  -- ── noice: cmdline flutuante, LSP hover bonito, mensagens ──
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      routes = {
        -- silencia o "written" e mensagens de busca sem resultado
        { filter = { event = "msg_show", any = { { find = "%d+L, %d+B" }, { find = "; after #%d+" }, { find = "; before #%d+" } } }, view = "mini" },
      },
      presets = {
        bottom_search = true,
        command_palette = true,   -- cmdline + popupmenu juntos, no centro
        long_message_to_split = true,
        lsp_doc_border = true,
      },
    },
  },

  -- ── Ícones (dependência de vários dos acima) ───────────────
  { "nvim-tree/nvim-web-devicons", lazy = true },
}
