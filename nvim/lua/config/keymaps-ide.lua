-- ╭──────────────────────────────────────────────────────────────╮
-- │  Camada "cara de IDE"                                        │
-- │                                                              │
-- │  Os atalhos do Vim continuam todos valendo. Isto aqui é uma  │
-- │  ponte: os mesmos comandos, nas teclas que você já tem no    │
-- │  dedo depois de anos de VSCode.                              │
-- │                                                              │
-- │  Não gosta? Comente a linha que chama este arquivo no        │
-- │  lua/config/keymaps.lua e nada mais muda.                    │
-- ╰──────────────────────────────────────────────────────────────╯
local map = vim.keymap.set

-- ── Barra lateral de arquivos (Ctrl+B, como no VSCode) ──────
map({ "n", "i", "v" }, "<C-b>", function() Snacks.explorer() end,
  { desc = "Explorer: abrir/fechar a árvore lateral" })

-- ── Paleta de comandos e busca de arquivo ───────────────────
map({ "n", "i", "v" }, "<C-p>", function()
  vim.cmd("stopinsert")
  Snacks.picker.files()
end, { desc = "Buscar arquivo" })

map({ "n", "i", "v" }, "<C-S-p>", function()
  vim.cmd("stopinsert")
  Snacks.picker.commands()
end, { desc = "Paleta de comandos" })

-- ── Salvar (Ctrl+S) ─────────────────────────────────────────
-- Em insert ele salva e CONTINUA no insert, como num editor comum.
map("n", "<C-s>", "<cmd>write<cr>", { desc = "Salvar" })
map("i", "<C-s>", "<cmd>write<cr>", { desc = "Salvar" })
map("v", "<C-s>", "<Esc><cmd>write<cr>", { desc = "Salvar" })

-- ── Comentar (Ctrl+/) ───────────────────────────────────────
-- Terminais divergem: uns mandam <C-/>, outros <C-_>. Mapeamos os dois.
for _, key in ipairs({ "<C-/>", "<C-_>" }) do
  map("n", key, "gcc", { remap = true, desc = "Comentar a linha" })
  map("v", key, "gc",  { remap = true, desc = "Comentar a seleção" })
  map("i", key, "<Esc>gccA", { remap = true, desc = "Comentar a linha" })
end

-- ── Terminal (Ctrl+crase, como no VSCode) ───────────────────
-- Mesmo terminal do workspace: abre sob o código, alterna o foco e,
-- quando fechado, preserva o que estava rodando.
map({ "n", "t" }, "<C-`>", function()
  require("hydra.workspace").toggle_terminal()
end, { desc = "Terminal (abre sob o código)" })

-- ── Buscar no projeto (Ctrl+Shift+F) ────────────────────────
map({ "n", "i", "v" }, "<C-S-f>", function()
  vim.cmd("stopinsert")
  Snacks.picker.grep()
end, { desc = "Buscar no projeto" })

-- ── Fechar o arquivo atual (Ctrl+W) ─────────────────────────
-- <C-w> é o prefixo de janelas do Vim, sagrado. Usamos <C-w><C-w>
-- em sequência para fechar o buffer, sem atrapalhar o prefixo.
map("n", "<C-w><C-w>", function() Snacks.bufdelete() end,
  { desc = "Fechar o arquivo atual" })

-- ── Duplicar linha (Ctrl+Shift+D) e mover (Alt+setas) ───────
map("n", "<C-S-d>", "yyp", { desc = "Duplicar a linha" })
map("i", "<C-S-d>", "<Esc>yypA", { desc = "Duplicar a linha" })
map("n", "<M-Down>", "<cmd>m .+1<cr>==", { desc = "Mover linha pra baixo" })
map("n", "<M-Up>",   "<cmd>m .-2<cr>==", { desc = "Mover linha pra cima" })
map("v", "<M-Down>", ":m '>+1<cr>gv=gv", { desc = "Mover seleção pra baixo" })
map("v", "<M-Up>",   ":m '<-2<cr>gv=gv", { desc = "Mover seleção pra cima" })

-- ── Selecionar tudo (Ctrl+A) ────────────────────────────────
map("n", "<C-a>", "ggVG", { desc = "Selecionar o arquivo inteiro" })

-- ── Renomear símbolo (F2, como no VSCode) ───────────────────
map("n", "<F2>", vim.lsp.buf.rename, { desc = "Renomear símbolo" })
-- ── Ir pra definição (F12) e voltar (Alt+seta) ──────────────
map("n", "<F12>", function() Snacks.picker.lsp_definitions() end, { desc = "Ir pra definição" })
map("n", "<M-[>", "<C-o>", { desc = "Voltar (histórico)" })
map("n", "<M-]>", "<C-i>", { desc = "Avançar (histórico)" })

-- ── Abas: transitar entre os arquivos abertos ──────────────
-- Alt+1..9 pula direto para a aba N (o número aparece na própria aba).
for i = 1, 9 do
  map({ "n", "i", "t" }, "<M-" .. i .. ">", function()
    require("bufferline").go_to(i, true)
  end, { desc = "Ir para a aba " .. i })
end

-- Ctrl+Tab circula entre as abas, como em qualquer editor
map({ "n", "i" }, "<C-Tab>", "<cmd>BufferLineCycleNext<cr>", { desc = "Próxima aba" })
map({ "n", "i" }, "<C-S-Tab>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Aba anterior" })
-- e o par que funciona em qualquer terminal
map("n", "<M-Right>", "<cmd>BufferLineCycleNext<cr>", { desc = "Próxima aba" })
map("n", "<M-Left>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Aba anterior" })
-- reordenar
map("n", "<M-S-Right>", "<cmd>BufferLineMoveNext<cr>", { desc = "Mover a aba pra direita" })
map("n", "<M-S-Left>", "<cmd>BufferLineMovePrev<cr>", { desc = "Mover a aba pra esquerda" })
map("n", "<leader>bp", "<cmd>BufferLinePick<cr>", { desc = "Escolher aba por letra" })

-- ── Workspace: o layout inteiro de uma vez ──────────────────
local ws = function() return require("hydra.workspace") end

map("n", "<leader>W", function() ws().toggle({ ai = "claude" }) end,
  { desc = "Workspace completo (arquivos + terminal + IA)" })
map("n", "<leader>ww", function() ws().toggle() end,
  { desc = "Workspace (arquivos + terminal)" })
map("n", "<leader>wq", function() ws().close() end,
  { desc = "Fechar os painéis, deixar só o código" })

-- ── Abrir um projeto sem sofrer ─────────────────────────────
map({ "n", "i", "v" }, "<C-o>", function()
  vim.cmd("stopinsert")
  ws().pick_project()
end, { desc = "Abrir projeto (lista os repositórios do seu HOME)" })
map("n", "<leader>op", function() ws().pick_project() end,
  { desc = "Abrir projeto (lista detectada)" })
map("n", "<leader>ob", function() ws().browse() end,
  { desc = "Navegar pastas até o projeto" })
map({ "n", "i", "v" }, "<C-S-o>", function()
  vim.cmd("stopinsert")
  ws().browse()
end, { desc = "Navegar pastas até o projeto" })
map("n", "<leader>oP", function() ws().pick_project({ ai = "claude" }) end,
  { desc = "Abrir projeto com a IA junto" })
