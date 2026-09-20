-- ╭─ Edição: movimento, textobjects, git, busca, sessões ─╮
return {

  -- ── flash: pula pra qualquer lugar visível em 2-3 teclas ───
  -- Aperte `s` + as letras do alvo. Substitui hop/leap/easymotion.
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = { char = { jump_labels = true } }, -- f/t/F/T também ganham labels
    },
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash: pular" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash: selecionar nó AST" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Flash remoto (ex: yr + alvo)" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Flash treesitter search" },
    },
  },

  -- ── mini.nvim: módulos pequenos e cirúrgicos ───────────────
  {
    "echasnovski/mini.nvim",
    event = "VeryLazy",
    config = function()
      -- pares automáticos: digitou ( vira ()
      require("mini.pairs").setup()

      -- surround: gsa" envolve, gsd" remove, gsr"' troca
      require("mini.surround").setup({
        mappings = {
          add = "gsa", delete = "gsd", find = "gsf", find_left = "gsF",
          highlight = "gsh", replace = "gsr", update_n_lines = "gsn",
        },
      })

      -- textobjects extras: `ci(`, `caf` (função), `cia` (argumento)...
      local ai = require("mini.ai")
      require("mini.ai").setup({
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({ a = { "@block.outer", "@conditional.outer", "@loop.outer" },
                                       i = { "@block.inner", "@conditional.inner", "@loop.inner" } }),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
          a = ai.gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),
        },
      })

      -- move blocos com Alt+hjkl (normal e visual)
      require("mini.move").setup({
        mappings = {
          left = "<M-h>", right = "<M-l>", down = "<M-j>", up = "<M-k>",
          line_left = "<M-h>", line_right = "<M-l>", line_down = "<M-j>", line_up = "<M-k>",
        },
      })
    end,
  },

  -- ── Comentários: `gcc` linha, `gc` em visual ───────────────
  -- (nvim 0.10+ já tem nativo; mantemos só o contexto de treesitter)
  {
    "folke/ts-comments.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- ── Git: sinais na gutter, blame, hunks ────────────────────
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" }, change = { text = "▎" },
        delete = { text = "▁" }, topdelete = { text = "▔" },
        changedelete = { text = "▎" }, untracked = { text = "▎" },
      },
      current_line_blame = false, -- ligue com <leader>ub
      current_line_blame_opts = { delay = 300, virt_text_pos = "eol" },
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns
        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
        end
        map("n", "]h", function() gs.nav_hunk("next") end, "Próximo hunk")
        map("n", "[h", function() gs.nav_hunk("prev") end, "Hunk anterior")
        map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage hunk")
        map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset hunk")
        map("n", "<leader>ghS", gs.stage_buffer, "Stage buffer")
        map("n", "<leader>ghu", gs.undo_stage_hunk, "Desfaz stage")
        map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview do hunk")
        map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame da linha")
        map("n", "<leader>ghd", gs.diffthis, "Diff do arquivo")
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Textobject: hunk")
      end,
    },
  },

  -- ── Trouble: lista bonita de diagnostics/refs/symbols ──────
  {
    "folke/trouble.nvim",
    cmd = { "Trouble" },
    opts = { focus = true },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (projeto)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Diagnostics (buffer)" },
      { "<leader>xs", "<cmd>Trouble symbols toggle<cr>", desc = "Símbolos do arquivo" },
      { "<leader>xl", "<cmd>Trouble lsp toggle win.position=right<cr>", desc = "Definições / referências" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location list" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix list" },
      {
        "]x",
        function() require("trouble").next({ skip_groups = true, jump = true }) end,
        desc = "Próximo item (trouble)",
      },
      {
        "[x",
        function() require("trouble").prev({ skip_groups = true, jump = true }) end,
        desc = "Item anterior (trouble)",
      },
    },
  },

  -- ── TODO/FIXME/HACK destacados e pesquisáveis ──────────────
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = { signs = true },
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "Próximo TODO" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "TODO anterior" },
      { "<leader>st", "<cmd>TodoTrouble<cr>", desc = "TODOs (trouble)" },
      { "<leader>sT", "<cmd>TodoTelescope<cr>", desc = "TODOs (picker)" },
    },
  },

  -- ── oil: edite o sistema de arquivos como se fosse um buffer
  -- Renomear 20 arquivos = editar 20 linhas e salvar. Imbatível.
  {
    "stevearc/oil.nvim",
    lazy = false,
    opts = {
      default_file_explorer = true,
      view_options = { show_hidden = true },
      keymaps = {
        ["<C-h>"] = false, -- libera pra navegação de janelas
        ["q"] = "actions.close",
      },
    },
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Oil: abrir diretório do arquivo" },
    },
  },

  -- ── grug-far: search & replace no projeto inteiro ──────────
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    opts = { headerMaxWidth = 80 },
    keys = {
      {
        "<leader>sr",
        function()
          require("grug-far").open({ transient = true, prefills = { paths = vim.fn.expand("%") } })
        end,
        desc = "Search & Replace (arquivo atual)",
      },
      {
        "<leader>sR",
        function() require("grug-far").open({ transient = true }) end,
        desc = "Search & Replace (projeto)",
      },
    },
  },

  -- ── Sessões: reabre onde você parou ────────────────────────
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restaurar sessão deste dir" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restaurar última sessão" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Não salvar sessão ao sair" },
    },
  },
}
