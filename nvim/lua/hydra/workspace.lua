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
    title = "Projetos  │  ⏎ abrir   ^B navegar pastas",
    dev = dev_dirs(),
    patterns = { ".git", "Cargo.toml", "package.json", "go.mod",
                 "pyproject.toml", "Makefile", ".hg", ".svn" },
    actions = {
      browse_fs = function(picker)
        picker:close()
        vim.schedule(function() M.browse(vim.uv.os_homedir(), opts) end)
      end,
    },
    win = {
      input = {
        keys = {
          ["<C-b>"] = { "browse_fs", mode = { "n", "i" }, desc = "Navegar pastas do sistema" },
        },
      },
    },
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

-- ── Navegar o sistema de arquivos ─────────────────────────────
-- O picker de projetos só mostra o que ele conseguiu detectar. Quando o
-- projeto está num canto qualquer do disco, você precisa é de um navegador:
-- entra e sai de pastas até achar, e abre onde quiser.

local PROJECT_MARKERS = {
  ".git", "Cargo.toml", "package.json", "go.mod",
  "pyproject.toml", "Makefile", "composer.json",
}

local function is_project(dir)
  for _, marker in ipairs(PROJECT_MARKERS) do
    if vim.uv.fs_stat(dir .. "/" .. marker) then return true end
  end
  return false
end

local function subdirs(dir)
  local names = {}
  local fd = vim.uv.fs_scandir(dir)
  if not fd then return names end
  while true do
    local name, kind = vim.uv.fs_scandir_next(fd)
    if not name then break end
    -- fs_scandir_next não resolve symlink: confirma com stat
    if kind == "directory"
      or (kind == "link" and (vim.uv.fs_stat(dir .. "/" .. name) or {}).type == "directory")
    then
      table.insert(names, name)
    end
  end
  table.sort(names, function(a, b)
    local ha, hb = a:sub(1, 1) == ".", b:sub(1, 1) == "."
    if ha ~= hb then return hb end      -- ocultas por último
    return a:lower() < b:lower()
  end)
  return names
end

--- Navega pastas a partir de `start`, e abre a que você escolher.
--- @param start? string diretório inicial (padrão: seu diretório pessoal)
--- @param opts? table repassado para M.open (ex.: { ai = "claude" })
function M.browse(start, opts)
  opts = opts or {}
  local state = {
    dir = vim.fs.normalize(start or vim.uv.os_homedir()),
  }

  local function finder()
    local items, i = {}, 0
    local parent = vim.fs.dirname(state.dir)
    if parent and parent ~= state.dir then
      i = i + 1
      table.insert(items, {
        idx = i, score = 0, text = "../", dir = parent, file = parent,
      })
    end
    for _, name in ipairs(subdirs(state.dir)) do
      i = i + 1
      local full = state.dir .. "/" .. name
      table.insert(items, {
        idx = i, score = 0,
        text = name .. (is_project(full) and "  ●" or ""),
        dir = full, file = full,
      })
    end
    return items
  end

  local function open_dir(picker, dir)
    picker:close()
    vim.schedule(function()
      vim.cmd.cd(dir)
      vim.cmd("silent! %bdelete!")
      vim.schedule(function()
        M.open(opts)
        vim.notify("projeto: " .. vim.fn.fnamemodify(dir, ":~"), vim.log.levels.INFO)
      end)
    end)
  end

  -- o título carrega o caminho e as teclas: ninguém deveria precisar
  -- decorar atalho para navegar numa lista de pastas
  local HINT = "  │  ⏎ entrar   ^O abrir   ^U subir"

  local function title_for(dir)
    return vim.fn.fnamemodify(dir, ":~")
      .. (is_project(dir) and "  ●" or "") .. HINT
  end

  local function goto_dir(picker, dir)
    state.dir = vim.fs.normalize(dir)
    -- o título renderizado vem de picker.title (opts.title virou template
    -- na primeira renderização e não muda mais sozinho)
    picker.title = title_for(state.dir)
    pcall(function() picker:update_titles() end)
    -- O filtro que você digitou para achar a pasta não vale mais lá dentro:
    -- sem limpar, a lista nova nasce vazia.
    pcall(function() picker.input:set("") end)
    picker:find()
  end

  local picker
  picker = Snacks.picker({
    title = "{title}",
    finder = finder,
    format = "text",
    layout = { preset = "default" },
    -- Enter entra na pasta; para ABRIR, Ctrl+O (ou Ctrl+A na atual)
    confirm = function(picker, item)
      if not item then return end
      goto_dir(picker, item.dir)
    end,
    actions = {
      open_selected = function(picker, item)
        if item then open_dir(picker, item.dir) end
      end,
      open_current = function(picker)
        open_dir(picker, state.dir)
      end,
      go_up = function(picker)
        local parent = vim.fs.dirname(state.dir)
        if parent and parent ~= state.dir then
          goto_dir(picker, parent)
        end
      end,
      go_home = function(picker)
        goto_dir(picker, vim.uv.os_homedir())
      end,
    },
    win = {
      input = {
        keys = {
          ["<C-o>"] = { "open_selected", mode = { "n", "i" }, desc = "Abrir a pasta selecionada" },
          ["<C-a>"] = { "open_current", mode = { "n", "i" }, desc = "Abrir a pasta atual" },
          ["<C-u>"] = { "go_up", mode = { "n", "i" }, desc = "Subir um nível" },
          ["<C-h>"] = { "go_up", mode = { "n", "i" }, desc = "Subir um nível" },
          ["<C-e>"] = { "go_home", mode = { "n", "i" }, desc = "Ir para o diretório pessoal" },
        },
      },
      list = {
        keys = {
          ["<C-o>"] = "open_selected",
          ["<C-a>"] = "open_current",
          ["-"] = "go_up",
        },
      },
    },
  })

  picker.title = title_for(state.dir)
  pcall(function() picker:update_titles() end)
  return picker
end

return M
