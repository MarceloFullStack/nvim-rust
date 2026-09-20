-- ╭─ Comportamentos automáticos ─╮
local function augroup(name)
  return vim.api.nvim_create_augroup("cfg_" .. name, { clear = true })
end

-- destaca o texto copiado por um instante (feedback visual do yank)
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})

-- volta pro ponto exato onde você estava quando reabre um arquivo
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(ev)
    local exclude = { "gitcommit", "gitrebase" }
    if vim.tbl_contains(exclude, vim.bo[ev.buf].filetype) or vim.b[ev.buf].last_loc then
      return
    end
    vim.b[ev.buf].last_loc = true
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- `q` fecha janelas auxiliares (help, quickfix, man...) sem cerimônia
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "help", "man", "qf", "lspinfo", "startuptime", "checkhealth",
    "notify", "spectre_panel", "neotest-output", "dap-float", "grug-far",
  },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = ev.buf, silent = true })
  end,
})

-- redimensiona os splits quando a janela do terminal muda de tamanho
vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function()
    local tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. tab)
  end,
})

-- cria o diretório automaticamente ao salvar um arquivo em pasta inexistente
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("auto_create_dir"),
  callback = function(ev)
    if ev.match:match("^%w%w+:[\\/][\\/]") then return end
    local file = vim.uv.fs_realpath(ev.match) or ev.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- ativa o corretor ortográfico e quebra de linha em texto (não em código)
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("wrap_spell"),
  pattern = { "markdown", "gitcommit", "text" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "pt_br,en"
  end,
})

-- Rust: largura de 100 colunas marcada (padrão rustfmt) + gq inteligente
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("rust_opts"),
  pattern = "rust",
  callback = function()
    vim.opt_local.colorcolumn = "100"
    vim.opt_local.textwidth = 100
  end,
})

-- não insere comentário automaticamente na linha de baixo ao dar <Enter>
vim.api.nvim_create_autocmd("BufEnter", {
  group = augroup("no_auto_comment"),
  callback = function() vim.opt_local.formatoptions:remove({ "c", "r", "o" }) end,
})

-- fecha o nvim se o único buffer restante for o explorer
vim.api.nvim_create_autocmd("BufEnter", {
  group = augroup("close_lone_explorer"),
  nested = true,
  callback = function()
    if vim.bo.filetype == "snacks_picker_list" and vim.fn.winnr("$") == 1 then
      vim.cmd("quit")
    end
  end,
})
