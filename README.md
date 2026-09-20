# nvim-rust

Uma config de Neovim para Rust, construída peça por peça — sem distro, sem framework, sem abstração sobre abstração. Cada linha é legível e cada plugin tem um motivo declarado.

Feita para quem programa Rust o dia inteiro e não quer sofrer: autocomplete que entende tipos, testes rodando sem sair do editor, debugger real, e IA integrada sem os três plugins de sempre brigando pela tecla `Tab`.

```
startup: 38 ms  ·  38 plugins  ·  Neovim 0.11+
```

## Instalação

```bash
git clone https://github.com/SEU-USUARIO/nvim-rust.git
cd nvim-rust
./install.sh
```

O script cuida de tudo: dependências do sistema, toolchain Rust via rustup, Nerd Font, plugins, parsers do treesitter e ferramentas do Mason. Configs existentes são movidas para `*.bak.<timestamp>`, nunca apagadas.

```bash
./install.sh --dry-run     # mostra o que faria, sem tocar em nada
./install.sh --deps-only   # só as dependências do sistema
./install.sh --no-deps     # só a config
```

Testado em Arch/Manjaro. Tem caminhos para Debian/Ubuntu, Fedora, openSUSE e macOS.

> **Depois de instalar:** aponte a fonte do seu terminal para uma **Nerd Font** (o script instala a Hack se não achar nenhuma). Sem isso, os ícones viram quadradinhos.

## O que tem dentro

**Rust** — [rustaceanvim](https://github.com/mrcjkb/rustaceanvim) com `rust-analyzer` configurado para clippy ao salvar, inlay hints completos, expansão de macro, visualização de MIR/HIR, runnables e debug integrados. [crates.nvim](https://github.com/saecki/crates.nvim) no `Cargo.toml`.

**Completion** — [blink.cmp](https://github.com/saghen/blink.cmp), com fuzzy matcher em Rust. LuaSnip e friendly-snippets.

**IA** — duas camadas que não se sobrepõem: [supermaven-nvim](https://github.com/supermaven-inc/supermaven-nvim) para completion inline (`Tab`) e [sidekick.nvim](https://github.com/folke/sidekick.nvim) para agentes CLI (`<leader>a`). O Sidekick roda o Claude Code, Gemini, Codex ou opencode de verdade num painel lateral, injetando contexto do buffer e recarregando os arquivos que o agente edita.

**Navegação** — [snacks.nvim](https://github.com/folke/snacks.nvim) fornecendo picker, explorer, notificações, dashboard, terminal e lazygit. [flash.nvim](https://github.com/folke/flash.nvim) para pular pela tela em duas teclas.

**Estrutura** — treesitter (branch `main`), textobjects semânticos (`cif` troca o corpo da função, `daa` remove um argumento com a vírgula), [mini.nvim](https://github.com/echasnovski/mini.nvim) para pares, surround e mover blocos.

**Resto** — LSP via mason + lspconfig, formatação com conform, debug com nvim-dap + codelldb, git com gitsigns + lazygit, which-key, trouble, oil, grug-far, persistence.

## A decisão sobre IA

Copilot, Supermaven, Codeium e os plugins de chat disputam o mesmo texto fantasma e a mesma tecla `Tab`. Instalar três garante sugestões piscando e atalhos ambíguos.

Esta config usa **um** plugin inline e **um** gerenciador de agentes — e esse gerenciador fala com qualquer CLI que você já tenha instalado. As teclas são separadas de propósito:

| Tecla | Aceita |
|---|---|
| `Ctrl-y` | o item do **LSP** — o que o compilador sabe |
| `Tab` | a sugestão da **IA** — o que o modelo acha |

## Atalhos

`<leader>` é a barra de espaço. **Segure espaço e espere** — o which-key mostra tudo que existe a partir dali. Esse é o jeito de aprender a config sem decorar nada.

| | |
|---|---|
| `<leader><space>` | buscar arquivo |
| `<leader>sg` | grep no projeto |
| `<leader>ca` | code action (o "conserta pra mim") |
| `<leader>rr` / `<leader>rR` | rodar teste / repetir o último |
| `<leader>re` | expandir macro |
| `<leader>ac` | abrir o Claude Code |
| `<leader>ap` | prompts prontos (manda os diagnostics junto) |
| `<leader>gg` | lazygit |
| `<leader>db` | breakpoint |
| `s` | flash — pular pra qualquer lugar visível |
| `<leader>sk` | buscar entre todos os atalhos |

O manual completo está em [`docs/manual.html`](docs/manual.html) — abra no navegador. Cobre desde a gramática do Vim até as receitas do dia a dia, com cheatsheet buscável.

## Estrutura

```
nvim/
├── init.lua                 ponto de entrada
└── lua/
    ├── config/
    │   ├── options.lua      opções do editor
    │   ├── lazy.lua         bootstrap do gerenciador
    │   ├── keymaps.lua      atalhos globais
    │   └── autocmds.lua     comportamentos automáticos
    └── plugins/
        ├── ui.lua           tema, statusline, dashboard
        ├── editor.lua       movimento, git, busca, sessões
        ├── treesitter.lua   parsing
        ├── lsp.lua          LSP e formatação
        ├── completion.lua   autocomplete
        ├── rust.lua         rustaceanvim, crates
        ├── ai.lua           supermaven, sidekick
        └── dap.lua          debugger
```

Qualquer `.lua` em `lua/plugins/` que devolva uma tabela é carregado automaticamente. Para adicionar um plugin, crie um arquivo — não precisa registrar em lugar nenhum.

## Requisitos

Neovim 0.11+, git, curl, um compilador C, ripgrep, Node ou Cargo (para o CLI do tree-sitter) e uma Nerd Font. Rust via rustup, com os componentes `rust-analyzer`, `rust-src`, `clippy` e `rustfmt`.

O `install.sh` resolve todos.

## Diagnóstico

```
:checkhealth        exame geral
:Lazy               plugins  (U atualiza, r faz rollback)
:LspInfo            servidores anexados a este buffer
:Mason              ferramentas externas
:checkhealth sidekick    quais CLIs de IA foram encontrados
```

Problemas comuns:

| Sintoma | Causa |
|---|---|
| Ícones viram quadrados | a fonte do terminal não é uma Nerd Font |
| Autocomplete Rust não aparece | sem `Cargo.toml` na raiz o rust-analyzer não anexa; ou ainda está indexando |
| `gd` não entra na std | falta `rustup component add rust-src` |
| Plugin quebrou após update | `:Lazy` → `r` faz rollback |

## Licença

MIT — veja [LICENSE](LICENSE).

A licença cobre esta config. Cada plugin tem a sua própria, e todos os que estão aqui são open source (MIT, Apache-2.0 ou GPL). Supermaven e os CLIs de IA são serviços de terceiros com termos próprios.
