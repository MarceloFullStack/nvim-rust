-- ╭──────────────────────────────────────────────────────────────╮
-- │  IA — duas camadas que NÃO se sobrepõem                      │
-- │                                                              │
-- │  1. Supermaven  → autocomplete INLINE (ghost text, <Tab>)    │
-- │     Preditivo, sub-100ms, enquanto você digita.              │
-- │                                                              │
-- │  2. Sidekick    → AGENTES CLI (claude/gemini/codex/opencode) │
-- │     Um painel lateral que roda o CLI de verdade, com o       │
-- │     contexto do seu buffer/seleção/diagnostics injetado.     │
-- │                                                              │
-- │  Por que não Copilot nem CodeCompanion também: os três       │
-- │  disputariam o MESMO ghost text e as mesmas keybinds <Tab>,  │
-- │  e você já paga Claude Code. Um inline + um agente cobre     │
-- │  100% do fluxo sem ambiguidade.                              │
-- ╰──────────────────────────────────────────────────────────────╯
return {

  -- ── 1. Autocomplete inline ─────────────────────────────────
  {
    "supermaven-inc/supermaven-nvim",
    event = "InsertEnter",
    opts = {
      keymaps = {
        accept_suggestion = "<Tab>",      -- aceita a sugestão inteira
        accept_word = "<C-Right>",        -- aceita só a próxima palavra
        clear_suggestion = "<C-]>",       -- dispensa
      },
      ignore_filetypes = { gitcommit = true, gitrebase = true },
      color = {
        suggestion_color = "#565f89",     -- cinza-azulado do tokyonight
        cterm = 244,
      },
      disable_inline_completion = false,
      disable_keymaps = false,
      condition = function()
        -- nunca sugerir dentro de arquivos de segredo
        local f = vim.fn.expand("%:t")
        return f == ".env" or f:match("%.pem$") ~= nil or f:match("secret") ~= nil
      end,
    },
    keys = {
      { "<leader>uS", "<cmd>SupermavenToggle<cr>", desc = "Toggle Supermaven (inline AI)" },
    },
  },

  -- ── 2. Agentes de IA no painel lateral ─────────────────────
  {
    "folke/sidekick.nvim",
    event = "VeryLazy",
    opts = {
      -- NES (Next Edit Suggestion) exige assinatura do Copilot LSP.
      -- Deixado OFF porque você usa Supermaven no inline.
      -- Se um dia assinar Copilot: mude para `enabled = true`.
      nes = { enabled = false },

      cli = {
        watch = true, -- recarrega o buffer quando a IA edita o arquivo no disco
        win = {
          layout = "right",
          split = { width = 90 },
        },
        tools = {
          -- os 4 abaixo já vêm pré-configurados; listados aqui só pra
          -- você saber que existem. `agy` é seu binário próprio.
          claude   = {},
          gemini   = {},
          codex    = {},
          opencode = {},
          agy      = { cmd = { "agy" } },
        },
        picker = "snacks",
      },
    },
    keys = {
      -- ── abrir / focar ──
      { "<leader>aa", function() require("sidekick.cli").toggle() end, desc = "AI: abrir/fechar painel" },
      { "<leader>ac", function() require("sidekick.cli").toggle({ name = "claude", focus = true }) end, desc = "AI: Claude Code" },
      { "<leader>ag", function() require("sidekick.cli").toggle({ name = "gemini", focus = true }) end, desc = "AI: Gemini" },
      { "<leader>ax", function() require("sidekick.cli").toggle({ name = "codex", focus = true }) end, desc = "AI: Codex" },
      { "<leader>ao", function() require("sidekick.cli").toggle({ name = "opencode", focus = true }) end, desc = "AI: opencode" },
      { "<leader>ay", function() require("sidekick.cli").toggle({ name = "agy", focus = true }) end, desc = "AI: agy" },
      { "<leader>as", function() require("sidekick.cli").select({ filter = { installed = true } }) end, desc = "AI: escolher agente" },
      { "<leader>ad", function() require("sidekick.cli").close() end, desc = "AI: encerrar sessão" },

      -- ── mandar contexto pro agente ──
      { "<leader>at", function() require("sidekick.cli").send({ msg = "{this}" }) end, mode = { "n", "x" }, desc = "AI: mandar isto (função/linha)" },
      { "<leader>af", function() require("sidekick.cli").send({ msg = "{file}" }) end, desc = "AI: mandar o arquivo" },
      { "<leader>av", function() require("sidekick.cli").send({ msg = "{selection}" }) end, mode = "x", desc = "AI: mandar a seleção" },
      { "<leader>ap", function() require("sidekick.cli").prompt() end, mode = { "n", "x" }, desc = "AI: escolher prompt pronto" },

      -- ── foco rápido (funciona até dentro do terminal) ──
      { "<C-.>", function() require("sidekick.cli").focus() end, mode = { "n", "x", "i", "t" }, desc = "AI: focar painel" },
    },
  },
}
