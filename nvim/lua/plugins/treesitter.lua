-- ╭─ Treesitter: parsing real do código (highlight, folds, textobjects) ─╮
-- Treesitter entende a ÁRVORE SINTÁTICA do seu código, não regex.
-- É o que faz "selecionar a função inteira" ou "dobrar este bloco" funcionar.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",          -- a branch `master` foi descontinuada
    lazy = false,             -- este plugin não suporta lazy-loading
    build = ":TSUpdate",
    dependencies = {
      { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
    },
    config = function()
      require("nvim-treesitter").setup()

      -- parsers que queremos sempre disponíveis
      local ensure = {
        "rust", "toml", "ron",                   -- Rust e seu ecossistema
        "lua", "vim", "vimdoc", "query",         -- config do próprio nvim
        "bash", "json", "yaml",
        "markdown", "markdown_inline",
        "regex", "diff", "git_config", "gitcommit", "gitignore",
        "c", "sql", "html", "css", "javascript", "typescript", "tsx", "python",
      }

      -- instala só o que falta (não trava o startup)
      local installed = require("nvim-treesitter.config").get_installed("parsers")
      local missing = vim.tbl_filter(function(p)
        return not vim.tbl_contains(installed, p)
      end, ensure)
      if #missing > 0 then
        require("nvim-treesitter").install(missing)
      end

      -- Na branch `main`, os recursos são habilitados manualmente por filetype.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("ts_enable", { clear = true }),
        callback = function(ev)
          local ft = vim.bo[ev.buf].filetype
          local lang = vim.treesitter.language.get_lang(ft)
          if not lang then return end
          -- só liga se o parser realmente existe (evita erro em ft exótico)
          if not vim.tbl_contains(require("nvim-treesitter.config").get_installed("parsers"), lang) then
            return
          end
          pcall(vim.treesitter.start, ev.buf, lang)                 -- highlight
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })

      -- ── Movimento por textobjects (]f = próxima função, etc.) ──
      local ts_move = require("nvim-treesitter-textobjects.move")
      local maps = {
        ["]f"] = { "@function.outer",  "Próxima função" },
        ["]c"] = { "@class.outer",     "Próximo struct/impl" },
        ["]a"] = { "@parameter.inner", "Próximo argumento" },
      }
      for lhs, spec in pairs(maps) do
        vim.keymap.set({ "n", "x", "o" }, lhs, function()
          ts_move.goto_next_start(spec[1], "textobjects")
        end, { desc = spec[2] })
        local prev = lhs:gsub("^%]", "[")
        vim.keymap.set({ "n", "x", "o" }, prev, function()
          ts_move.goto_previous_start(spec[1], "textobjects")
        end, { desc = spec[2]:gsub("Próxim[oa]", "Anterior:") })
      end

      -- troca argumentos de lugar: <leader>na / <leader>pa
      local ts_swap = require("nvim-treesitter-textobjects.swap")
      vim.keymap.set("n", "<leader>cna", function() ts_swap.swap_next("@parameter.inner") end,
        { desc = "Troca com o próximo argumento" })
      vim.keymap.set("n", "<leader>cpa", function() ts_swap.swap_previous("@parameter.inner") end,
        { desc = "Troca com o argumento anterior" })
    end,
  },

  -- mostra o contexto (assinatura da função/impl) grudado no topo da tela
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts = { max_lines = 3, multiline_threshold = 1 },
    keys = {
      { "<leader>ut", "<cmd>TSContextToggle<cr>", desc = "Toggle contexto do treesitter" },
    },
  },
}
