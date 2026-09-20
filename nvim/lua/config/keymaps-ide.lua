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
map({ "n", "t" }, "<C-`>", function() Snacks.terminal() end,
  { desc = "Terminal" })

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
map("n", "<M-Left>",  "<C-o>", { desc = "Voltar" })
map("n", "<M-Right>", "<C-i>", { desc = "Avançar" })
