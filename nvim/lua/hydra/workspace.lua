-- ╭──────────────────────────────────────────────────────────────╮
-- │  Workspace — o layout de trabalho, montado de uma vez        │
-- │                                                              │
-- │   ┌──────────┬─────────────────────┬──────────┐             │
-- │   │ arquivos │       código        │  agente  │             │
-- │   │          ├─────────────────────┤   (IA)   │             │
-- │   │          │      terminal       │          │             │
-- │   └──────────┴─────────────────────┴──────────┘             │
-- │                                                              │
-- │  Sem precisar decorar atalho nenhum: `nvim .` já abre assim. │
-- ╰──────────────────────────────────────────────────────────────╯
local M = {}

-- a janela do código, para onde o foco sempre volta
local function editor_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.bo[buf].filetype
    local bt = vim.bo[buf].buftype
    local ok = bt == "" and ft ~= "snacks_dashboard"
    if ok and vim.api.nvim_win_get_config(win).relative == "" then
      return win
    end
  end
  return vim.api.nvim_get_current_win()
end

local function focus_editor()
  local win = editor_win()
  if vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_set_current_win, win)
  end
end

--- Abre a árvore de arquivos na lateral.
function M.explorer()
  local ok = pcall(function() Snacks.explorer.open() end)
  if not ok then pcall(Snacks.explorer) end
end

--- O terminal do workspace: um split abaixo do CÓDIGO, não da tela inteira
--- (se fosse da tela, passaria por baixo da árvore de arquivos também).
local term_win, term_buf = nil, nil

local function term_alive()
  return term_win and vim.api.nvim_win_is_valid(term_win)
end

function M.terminal()
  if term_alive() then return term_win end

  local win = editor_win()
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
  end

  local height = math.max(8, math.floor(vim.o.lines * 0.26))
  vim.cmd("belowright " .. height .. "split")
  term_win = vim.api.nvim_get_current_win()

  if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
    vim.api.nvim_win_set_buf(term_win, term_buf) -- reaproveita a sessão
  else
    vim.cmd("terminal")
    term_buf = vim.api.nvim_get_current_buf()
    vim.bo[term_buf].buflisted = false
  end

  vim.wo[term_win].winfixheight = true
  vim.wo[term_win].number = false
  vim.wo[term_win].relativenumber = false
  vim.wo[term_win].signcolumn = "no"
  vim.cmd("stopinsert")
  return term_win
end

--- Mostra/esconde o terminal, preservando o que estava rodando.
function M.toggle_terminal()
  if term_alive() then
    local going_back = vim.api.nvim_get_current_win() ~= term_win
    if going_back then
      vim.api.nvim_set_current_win(term_win) -- só estava fora dele: foca
      vim.cmd("startinsert")
    else
      vim.api.nvim_win_close(term_win, false)
      term_win = nil
      focus_editor()
    end
  else
    M.terminal()
    vim.cmd("startinsert")
  end
end

--- Abre um agente de IA no painel lateral.
function M.ai(name)
  local ok, cli = pcall(require, "sidekick.cli")
  if not ok then
    vim.notify("sidekick não está disponível", vim.log.levels.WARN)
    return false
  end
  name = name or "claude"
  if vim.fn.executable(name) ~= 1 then
    vim.notify(
      ("`%s` não está instalado ou não está no PATH"):format(name),
      vim.log.levels.WARN
    )
    return false
  end
  cli.toggle({ name = name, focus = false })
  return true
end

--- Abre o arquivo mais provável do projeto, para a tela não nascer vazia.
local ENTRY_POINTS = {
  "src/main.rs", "src/lib.rs", "src/index.ts", "src/index.js", "src/main.go",
  "main.go", "main.py", "app.py", "index.js", "README.md", "readme.md",
}

function M.open_entry_point()
  -- se já há um arquivo de verdade aberto, não mexe
  local buf = vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_get_name(buf) ~= "" then return end

  for _, rel in ipairs(ENTRY_POINTS) do
    if vim.fn.filereadable(rel) == 1 then
      vim.cmd.edit(vim.fn.fnameescape(rel))
      return rel
    end
  end
end

--- Monta o layout inteiro.
--- @param opts? { ai?: boolean|string, terminal?: boolean, explorer?: boolean }
function M.open(opts)
  opts = vim.tbl_extend("keep", opts or {}, {
    explorer = true,
    terminal = true,
    ai = false,
  })

  -- Cada peça abre no seu tempo: o explorer e o terminal criam janelas e
  -- roubam o foco, então voltamos para o código entre uma e outra.
  local steps = { function() M.open_entry_point() end }

  if opts.explorer then
    table.insert(steps, function() M.explorer() end)
  end
  if opts.terminal then
    table.insert(steps, function()
      focus_editor()
      M.terminal()
    end)
  end
  if opts.ai then
    table.insert(steps, function()
      focus_editor()
      M.ai(type(opts.ai) == "string" and opts.ai or "claude")
    end)
  end
  table.insert(steps, focus_editor)

  local i = 0
  local function next_step()
    i = i + 1
    local step = steps[i]
    if not step then return end
    pcall(step)
    vim.defer_fn(next_step, 120)
  end
  next_step()
end

--- Fecha os painéis, deixando só o código.
function M.close()
  local keep = editor_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= keep and vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
  pcall(function() require("sidekick.cli").close() end)
end

--- Liga/desliga o layout.
function M.toggle(opts)
  local extra = 0
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft, bt = vim.bo[buf].filetype, vim.bo[buf].buftype
    if bt == "terminal" or ft:match("snacks") then
      extra = extra + 1
    end
  end
  if extra > 0 then M.close() else M.open(opts) end
end

-- ── Abrir uma pasta ───────────────────────────────────────────
-- Procurar um projeto não pode ser um exercício de paciência. Usamos o
-- picker de projetos do snacks: ele combina os diretórios que você abriu
-- recentemente com uma varredura rasa dos lugares onde projetos costumam
-- morar, procurando marcadores (.git, Cargo.toml, package.json...).
-- Rápido e assíncrono — a versão anterior varria o HOME inteiro de forma
-- bloqueante e simplesmente travava.

local function dev_dirs()
  local home = vim.uv.os_homedir()
  local candidates = {
    home, home .. "/dev", home .. "/projects", home .. "/projetos",
    home .. "/code", home .. "/git", home .. "/repos", home .. "/workspace",
    home .. "/Documents", home .. "/src",
  }
  local out = {}
  for _, dir in ipairs(candidates) do
    if vim.fn.isdirectory(dir) == 1 then
      table.insert(out, dir)
    end
  end
  return out
end

--- Escolhe um projeto e abre o workspace nele.
function M.pick_project(opts)
  opts = opts or {}
  Snacks.picker.projects({
    dev = dev_dirs(),
    patterns = { ".git", "Cargo.toml", "package.json", "go.mod",
                 "pyproject.toml", "Makefile", ".hg", ".svn" },
    confirm = function(picker, item)
      picker:close()
      if not item then return end
      local dir = item.file or item.dir or item.text
      if not dir or dir == "" then return end
      vim.schedule(function()
        vim.cmd.cd(dir)
        -- limpa os buffers do projeto anterior antes de montar o novo
        vim.cmd("silent! %bdelete!")
        vim.schedule(function()
          M.open(opts)
          vim.notify("projeto: " .. vim.fn.fnamemodify(dir, ":~"),
            vim.log.levels.INFO)
        end)
      end)
    end,
  })
end

return M
