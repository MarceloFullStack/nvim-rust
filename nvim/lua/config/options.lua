-- Opções do editor. Tudo aqui é vanilla Neovim, sem plugin.
local opt = vim.opt

-- ── Aparência ────────────────────────────────────────────────
opt.number = true             -- número da linha
opt.relativenumber = true     -- números relativos: 5j, 12k viram triviais
opt.signcolumn = "yes"        -- coluna de sinais sempre visível (evita "pulo" do texto)
opt.cursorline = true         -- destaca a linha do cursor
opt.termguicolors = true      -- cores 24-bit (obrigatório pros temas modernos)
opt.showmode = false          -- a lualine já mostra o modo
opt.laststatus = 3            -- UMA statusline global, não uma por split
opt.cmdheight = 0             -- esconde a linha de comando quando ociosa (noice cuida)
opt.pumheight = 12            -- altura máx. do popup de autocomplete
opt.winborder = "rounded"     -- bordas arredondadas em janelas flutuantes (nvim 0.11+)
opt.fillchars = { eob = " ", foldopen = "▾", foldclose = "▸", fold = " ", diff = "╱" }
opt.list = true               -- mostra caracteres invisíveis...
opt.listchars = { tab = "→ ", trail = "·", nbsp = "␣" } -- ...só os que importam

-- ── Scroll e navegação ───────────────────────────────────────
opt.scrolloff = 8             -- sempre 8 linhas de contexto acima/abaixo
opt.sidescrolloff = 8
opt.smoothscroll = true       -- scroll suave em linhas quebradas
opt.wrap = false              -- código não quebra linha

-- ── Indentação (Rust usa 4 espaços) ──────────────────────────
opt.expandtab = true          -- Tab insere espaços
opt.tabstop = 4               -- largura visual do Tab
opt.shiftwidth = 4            -- largura do >> e <<
opt.softtabstop = 4
opt.smartindent = true
opt.breakindent = true

-- ── Busca ────────────────────────────────────────────────────
opt.ignorecase = true         -- busca case-insensitive...
opt.smartcase = true          -- ...a menos que você digite uma maiúscula
opt.inccommand = "split"      -- preview ao vivo do :%s/foo/bar
opt.hlsearch = true

-- ── Splits ───────────────────────────────────────────────────
opt.splitright = true         -- split vertical abre à direita
opt.splitbelow = true         -- split horizontal abre abaixo
opt.splitkeep = "screen"      -- não deixa o texto "pular" ao splitar

-- ── Arquivos e histórico ─────────────────────────────────────
opt.undofile = true           -- undo PERSISTE entre sessões (salva-vidas)
opt.undolevels = 10000
opt.swapfile = false          -- sem .swp; o undofile + git cobrem
opt.backup = false
opt.updatetime = 200          -- diagnostics/CursorHold mais responsivos
opt.timeoutlen = 400          -- tempo de espera de um atalho composto (which-key)
opt.confirm = true            -- pergunta em vez de falhar ao sair com mudanças
opt.autowrite = true

-- ── Clipboard ────────────────────────────────────────────────
-- adiado: checar clipboard no startup custa ~30ms. Faz depois do UI subir.
vim.schedule(function()
  opt.clipboard = "unnamedplus" -- y e p usam o clipboard do sistema (Wayland/wl-copy)
end)

-- ── Completion ───────────────────────────────────────────────
opt.completeopt = "menu,menuone,noselect"
opt.shortmess:append({ W = true, I = true, c = true, C = true })

-- ── Folds (dobras) via treesitter ────────────────────────────
opt.foldlevel = 99            -- tudo aberto por padrão
opt.foldtext = ""
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"

-- ── Diagnostics (erros do LSP) ───────────────────────────────
vim.diagnostic.config({
  virtual_text = {            -- texto do erro ao lado da linha
    prefix = "●",
    spacing = 4,
    source = "if_many",
  },
  float = { border = "rounded", source = "if_many" },
  severity_sort = true,
  underline = true,
  update_in_insert = false,   -- não pisca erro enquanto você digita
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN]  = " ",
      [vim.diagnostic.severity.HINT]  = " ",
      [vim.diagnostic.severity.INFO]  = " ",
    },
  },
})

-- desliga providers que não usamos (ganha startup)
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_python3_provider = 0
