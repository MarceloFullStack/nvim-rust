-- ╭──────────────────────────────────────────────────────────╮
-- │  Neovim — Rust + AI  ·  marcelo                          │
-- │  Ponto de entrada. A ordem aqui importa.                  │
-- ╰──────────────────────────────────────────────────────────╯

-- leader precisa ser definido ANTES de qualquer plugin carregar,
-- senão os mapeamentos dos plugins pegam o leader antigo (\)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.lazy")     -- instala/bootstrapa o gerenciador + plugins
require("config.keymaps")
require("config.autocmds")
