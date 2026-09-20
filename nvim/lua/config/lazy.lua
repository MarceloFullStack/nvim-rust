-- Bootstrap do lazy.nvim (gerenciador de plugins)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Falha ao clonar lazy.nvim:\n", "ErrorMsg" }, { out, "WarningMsg" } }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { import = "plugins" }, -- carrega tudo de lua/plugins/*.lua
  },
  defaults = { lazy = true },        -- plugins carregam sob demanda por padrão
  install = { colorscheme = { "tokyonight" } },
  checker = { enabled = true, notify = false }, -- checa updates em background
  change_detection = { notify = false },
  ui = { border = "rounded" },
  performance = {
    rtp = {
      -- desabilita plugins embutidos que não usamos
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "zipPlugin", "tutor", "netrwPlugin",
      },
    },
  },
})
