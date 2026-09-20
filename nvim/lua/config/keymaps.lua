-- ╭─ Atalhos globais (os de plugin ficam junto de cada plugin) ─╮
local map = vim.keymap.set

-- ── Básicos de sobrevivência ───────────────────────────────
map("i", "jk", "<Esc>", { desc = "Sair do insert sem sair da home row" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Limpa o highlight da busca" })
map({ "n", "x" }, "<leader>w", "<cmd>w<cr>", { desc = "Salvar" })
map("n", "<leader>W", "<cmd>wa<cr>", { desc = "Salvar tudo" })

-- ── Navegação entre janelas (splits) ───────────────────────
map("n", "<C-h>", "<C-w>h", { desc = "Janela à esquerda" })
map("n", "<C-j>", "<C-w>j", { desc = "Janela abaixo" })
map("n", "<C-k>", "<C-w>k", { desc = "Janela acima" })
map("n", "<C-l>", "<C-w>l", { desc = "Janela à direita" })
map("n", "<C-Up>",    "<cmd>resize +2<cr>", { desc = "Aumentar altura" })
map("n", "<C-Down>",  "<cmd>resize -2<cr>", { desc = "Diminuir altura" })
map("n", "<C-Left>",  "<cmd>vertical resize -2<cr>", { desc = "Diminuir largura" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Aumentar largura" })
map("n", "<leader>-", "<C-W>s", { desc = "Split horizontal" })
map("n", "<leader>|", "<C-W>v", { desc = "Split vertical" })

-- ── Buffers ────────────────────────────────────────────────
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Buffer anterior" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Próximo buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Alternar com o último buffer" })
map("n", "<leader>bd", function() Snacks.bufdelete() end, { desc = "Fechar buffer (mantém a janela)" })
map("n", "<leader>bo", function() Snacks.bufdelete.other() end, { desc = "Fechar os OUTROS buffers" })

-- ── Movimento mais inteligente ─────────────────────────────
-- j/k respeitam linhas visuais quando há wrap, e alimentam a jumplist
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
-- centraliza a tela ao pular meia página ou navegar na busca
map("n", "<C-d>", "<C-d>zz", { desc = "Meia página abaixo (centralizado)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Meia página acima (centralizado)" })
map("n", "n", "nzzzv", { desc = "Próxima ocorrência (centralizada)" })
map("n", "N", "Nzzzv", { desc = "Ocorrência anterior (centralizada)" })

-- ── Edição ─────────────────────────────────────────────────
map("v", "<", "<gv", { desc = "Desindenta e MANTÉM a seleção" })
map("v", ">", ">gv", { desc = "Indenta e MANTÉM a seleção" })
-- cola por cima sem perder o que estava no registrador
map("x", "<leader>p", [["_dP]], { desc = "Colar sem sobrescrever o registrador" })
-- deleta sem sujar o registrador
map("x", "<leader>D", [["_d]], { desc = "Deletar pro buraco negro" })
-- undo em pontos melhores (cada pontuação vira um checkpoint)
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- ── Diagnostics ────────────────────────────────────────────
local function diag_goto(count, severity)
  return function()
    vim.diagnostic.jump({
      count = count,
      severity = severity and vim.diagnostic.severity[severity] or nil,
      float = true,
    })
  end
end
map("n", "]d", diag_goto(1),  { desc = "Próximo diagnostic" })
map("n", "[d", diag_goto(-1), { desc = "Diagnostic anterior" })
map("n", "]e", diag_goto(1, "ERROR"),  { desc = "Próximo ERRO" })
map("n", "[e", diag_goto(-1, "ERROR"), { desc = "Erro anterior" })
map("n", "]w", diag_goto(1, "WARN"),   { desc = "Próximo warning" })
map("n", "[w", diag_goto(-1, "WARN"),  { desc = "Warning anterior" })

-- ── Picker (snacks) — o coração da navegação ───────────────
map("n", "<leader><space>", function() Snacks.picker.files() end, { desc = "Buscar arquivo" })
map("n", "<leader>ff", function() Snacks.picker.files() end, { desc = "Buscar arquivo" })
map("n", "<leader>fg", function() Snacks.picker.git_files() end, { desc = "Arquivos do git" })
map("n", "<leader>fr", function() Snacks.picker.recent() end, { desc = "Arquivos recentes" })
map("n", "<leader>fb", function() Snacks.picker.buffers() end, { desc = "Buffers abertos" })
map("n", "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, { desc = "Config do nvim" })
map("n", "<leader>fe", function() Snacks.explorer() end, { desc = "Explorer (árvore)" })
map("n", "<leader>fp", function() Snacks.picker.projects() end, { desc = "Projetos" })

map("n", "<leader>sg", function() Snacks.picker.grep() end, { desc = "Grep no projeto" })
map({ "n", "x" }, "<leader>sw", function() Snacks.picker.grep_word() end, { desc = "Grep da palavra sob o cursor" })
map("n", "<leader>sb", function() Snacks.picker.lines() end, { desc = "Buscar nas linhas do buffer" })
map("n", "<leader>sh", function() Snacks.picker.help() end, { desc = "Ajuda (:help)" })
map("n", "<leader>sk", function() Snacks.picker.keymaps() end, { desc = "Todos os atalhos" })
map("n", "<leader>sd", function() Snacks.picker.diagnostics() end, { desc = "Diagnostics do projeto" })
map("n", "<leader>sc", function() Snacks.picker.command_history() end, { desc = "Histórico de comandos" })
map("n", "<leader>sq", function() Snacks.picker.qflist() end, { desc = "Quickfix" })
map("n", "<leader>su", function() Snacks.picker.undo() end, { desc = "Árvore de undo" })
map("n", "<leader>sm", function() Snacks.picker.marks() end, { desc = "Marks" })
map("n", "<leader>s\"", function() Snacks.picker.registers() end, { desc = "Registradores" })
map("n", "<leader>sp", function() Snacks.picker.resume() end, { desc = "Retomar última busca (previous)" })

-- ── Git ────────────────────────────────────────────────────
map("n", "<leader>gg", function() Snacks.lazygit() end, { desc = "Lazygit" })
map("n", "<leader>gl", function() Snacks.picker.git_log() end, { desc = "Log do git" })
map("n", "<leader>gL", function() Snacks.picker.git_log_file() end, { desc = "Log deste arquivo" })
map("n", "<leader>gs", function() Snacks.picker.git_status() end, { desc = "Status do git" })
map("n", "<leader>gb", function() Snacks.picker.git_branches() end, { desc = "Branches" })
map({ "n", "x" }, "<leader>gB", function() Snacks.gitbrowse() end, { desc = "Abrir no GitHub/GitLab" })

-- ── Terminal ───────────────────────────────────────────────
map("n", "<C-/>", function() Snacks.terminal() end, { desc = "Terminal flutuante" })
map("n", "<leader>ft", function() Snacks.terminal() end, { desc = "Terminal flutuante" })
map("t", "<C-/>", "<cmd>close<cr>", { desc = "Fechar terminal" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Terminal: ir pro modo normal" })

-- ── Toggles de UI ──────────────────────────────────────────
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    Snacks.toggle.option("wrap", { name = "Quebra de linha" }):map("<leader>uw")
    Snacks.toggle.option("relativenumber", { name = "Números relativos" }):map("<leader>ur")
    Snacks.toggle.option("spell", { name = "Corretor ortográfico" }):map("<leader>us")
    Snacks.toggle.diagnostics():map("<leader>ud")
    Snacks.toggle.line_number():map("<leader>ul")
    Snacks.toggle.treesitter():map("<leader>uT")
    Snacks.toggle.inlay_hints():map("<leader>uh")
    Snacks.toggle.zen():map("<leader>uz")
    Snacks.toggle.dim():map("<leader>uD")
    Snacks.toggle.indent():map("<leader>ui")
    Snacks.toggle.option("conceallevel", { off = 0, on = 2, name = "Conceal" }):map("<leader>uc")
    Snacks.toggle({
      name = "Blame na linha",
      get = function() return require("gitsigns.config").config.current_line_blame end,
      set = function(state) require("gitsigns").toggle_current_line_blame(state) end,
    }):map("<leader>ub")
  end,
})

-- ── Camada com cara de IDE (Ctrl+B, Ctrl+P, Ctrl+S...) ─────
-- Comente a linha abaixo se quiser só os atalhos puros do Vim.
require("config.keymaps-ide")

-- ── Utilitários ────────────────────────────────────────────
map("n", "<leader>L", "<cmd>Lazy<cr>", { desc = "Gerenciador de plugins" })
map("n", "<leader>M", "<cmd>Mason<cr>", { desc = "Mason (LSP/tools)" })
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Sair de tudo" })
map("n", "<leader>un", function() Snacks.notifier.hide() end, { desc = "Dispensar notificações" })
-- copia o caminho do arquivo atual
map("n", "<leader>fy", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("Copiado: " .. path)
end, { desc = "Copiar caminho do arquivo" })
