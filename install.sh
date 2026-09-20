#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
#  Instalador da config Neovim — Rust + IA
#
#  Uso:
#    ./install.sh              instala tudo
#    ./install.sh --deps-only  só as dependências do sistema
#    ./install.sh --no-deps    só a config (assume deps prontas)
#    ./install.sh --dry-run    mostra o que faria, sem fazer
#
#  Suporta: Arch/Manjaro, Debian/Ubuntu, Fedora, openSUSE, macOS
# ──────────────────────────────────────────────────────────────
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_MIN_MAJOR=0
NVIM_MIN_MINOR=11

DO_DEPS=1
DO_CONFIG=1
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --deps-only) DO_CONFIG=0 ;;
    --no-deps)   DO_DEPS=0 ;;
    --dry-run)   DRY_RUN=1 ;;
    -h|--help)   sed -n '2,16p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "opção desconhecida: $arg" >&2; exit 1 ;;
  esac
done

# ── Saída ─────────────────────────────────────────────────────
if [ -t 1 ]; then
  B=$'\033[1m'; DIM=$'\033[2m'; R=$'\033[0m'
  OK=$'\033[32m'; WARN=$'\033[33m'; ERR=$'\033[31m'; INFO=$'\033[34m'
else
  B=""; DIM=""; R=""; OK=""; WARN=""; ERR=""; INFO=""
fi

step() { printf "\n${B}${INFO}==>${R}${B} %s${R}\n" "$*"; }
ok()   { printf "  ${OK}✓${R} %s\n" "$*"; }
warn() { printf "  ${WARN}!${R} %s\n" "$*"; }
die()  { printf "\n  ${ERR}✗ %s${R}\n\n" "$*" >&2; exit 1; }
run()  {
  if [ "$DRY_RUN" = 1 ]; then printf "  ${DIM}[dry-run] %s${R}\n" "$*";
  else "$@"; fi
}

have() { command -v "$1" >/dev/null 2>&1; }

# `grep -q` e `head` fecham o pipe assim que têm o que precisam, o que manda
# SIGPIPE pro produtor. Com `pipefail` isso vira falha do pipeline inteiro e
# derrubaria o script — então esses dois casos rodam num subshell sem pipefail.
has_nerd_font() { ( set +o pipefail; fc-list 2>/dev/null | grep -qi "nerd font" ); }
nvim_version()  { ( set +o pipefail; nvim --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1 ); }

# ── Detecta o gerenciador de pacotes ──────────────────────────
detect_pm() {
  if have pacman;  then echo pacman;  return; fi
  if have apt-get; then echo apt;     return; fi
  if have dnf;     then echo dnf;     return; fi
  if have zypper;  then echo zypper;  return; fi
  if have brew;    then echo brew;    return; fi
  echo unknown
}
PM="$(detect_pm)"

SUDO=""
if [ "$(id -u)" -ne 0 ] && [ "$PM" != "brew" ]; then
  have sudo || die "precisa de sudo (ou rode como root)"
  SUDO="sudo"
fi

pm_install() {
  [ $# -eq 0 ] && return 0
  case "$PM" in
    pacman) run $SUDO pacman -S --needed --noconfirm "$@" ;;
    apt)    run $SUDO apt-get install -y "$@" ;;
    dnf)    run $SUDO dnf install -y "$@" ;;
    zypper) run $SUDO zypper install -y "$@" ;;
    brew)   run brew install "$@" ;;
    *)      die "gerenciador de pacotes não reconhecido — instale manualmente: $*" ;;
  esac
}

# Nome dos pacotes muda entre distros
pkg_name() {
  local generic="$1"
  case "$generic:$PM" in
    ripgrep:*)            echo ripgrep ;;
    fd:pacman)            echo fd ;;
    fd:apt)               echo fd-find ;;
    fd:dnf|fd:zypper)     echo fd-find ;;
    fd:brew)              echo fd ;;
    nodejs:pacman)        echo "nodejs npm" ;;
    nodejs:apt)           echo "nodejs npm" ;;
    nodejs:dnf)           echo "nodejs npm" ;;
    nodejs:zypper)        echo "nodejs npm" ;;
    nodejs:brew)          echo node ;;
    clipboard:pacman)     echo "wl-clipboard xclip" ;;
    clipboard:apt)        echo "wl-clipboard xclip" ;;
    clipboard:dnf)        echo "wl-clipboard xclip" ;;
    clipboard:zypper)     echo "wl-clipboard xclip" ;;
    clipboard:brew)       echo "" ;;
    buildtools:pacman)    echo "base-devel" ;;
    buildtools:apt)       echo "build-essential" ;;
    buildtools:dnf)       echo "gcc make" ;;
    buildtools:zypper)    echo "gcc make" ;;
    buildtools:brew)      echo "" ;;
    *)                    echo "$generic" ;;
  esac
}

# ══════════════════════════════════════════════════════════════
printf "\n${B}  Neovim · Rust · IA — instalador${R}\n"
printf "  ${DIM}gerenciador detectado: %s${R}\n" "$PM"
[ "$DRY_RUN" = 1 ] && printf "  ${WARN}modo dry-run: nada será alterado${R}\n"

# ── 1. Dependências do sistema ────────────────────────────────
if [ "$DO_DEPS" = 1 ]; then
  step "Dependências do sistema"

  PKGS=""
  for p in git curl unzip ripgrep fd fzf lazygit nodejs clipboard buildtools; do
    PKGS="$PKGS $(pkg_name "$p")"
  done
  # shellcheck disable=SC2086
  pm_install $PKGS || warn "alguns pacotes falharam — siga e instale os que faltarem manualmente"
  ok "pacotes base"

  # ── Neovim ──
  step "Neovim"
  need_nvim=1
  if have nvim; then
    v="$(nvim_version)"
    maj="${v%%.*}"; min="${v##*.}"
    if [ "$maj" -gt "$NVIM_MIN_MAJOR" ] || { [ "$maj" -eq "$NVIM_MIN_MAJOR" ] && [ "$min" -ge "$NVIM_MIN_MINOR" ]; }; then
      ok "nvim $v já instalado"
      need_nvim=0
    else
      warn "nvim $v é antigo demais (precisa de $NVIM_MIN_MAJOR.$NVIM_MIN_MINOR+)"
    fi
  fi
  if [ "$need_nvim" = 1 ]; then
    case "$PM" in
      pacman|brew) pm_install neovim ;;
      *)
        # repos de apt/dnf costumam trazer versões velhas: usa o appimage oficial
        warn "instalando o Neovim oficial em ~/.local/bin (o repositório da distro traz versão antiga)"
        run mkdir -p "$HOME/.local/bin"
        run curl -fsSL -o /tmp/nvim.appimage \
          https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
        run chmod +x /tmp/nvim.appimage
        run mv /tmp/nvim.appimage "$HOME/.local/bin/nvim"
        ;;
    esac
    ok "neovim instalado"
  fi

  # ── Rust via rustup ──
  step "Toolchain Rust"
  if have rustup; then
    ok "rustup já instalado"
  else
    if [ "$PM" = "pacman" ] && pacman -Si rustup >/dev/null 2>&1; then
      warn "o pacote 'rust' do pacman conflita com rustup; o pacman vai pedir pra removê-lo"
      pm_install rustup
    else
      run sh -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path"
    fi
  fi
  export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

  if have rustup; then
    run rustup default stable
    run rustup component add rust-analyzer rust-src clippy rustfmt
    ok "stable + rust-analyzer + rust-src + clippy + rustfmt"

    # No Arch o rustup vive em /usr/bin e não cria shim pro rust-analyzer.
    # O rustup resolve a toolchain pelo nome do link (argv[0]), então um
    # symlink pro próprio rustup vira o proxy correto.
    if ! have rust-analyzer; then
      run mkdir -p "$HOME/.local/bin"
      run ln -sf "$(command -v rustup)" "$HOME/.local/bin/rust-analyzer"
      ok "shim do rust-analyzer criado em ~/.local/bin"
    fi
  fi

  # ── tree-sitter CLI (a branch main do nvim-treesitter compila os parsers) ──
  step "tree-sitter CLI"
  if have tree-sitter; then
    ok "já instalado"
  elif have npm; then
    run npm install -g tree-sitter-cli
    ok "instalado via npm"
  elif have cargo; then
    run cargo install tree-sitter-cli
    ok "instalado via cargo"
  else
    warn "sem npm nem cargo — os parsers do treesitter não vão compilar"
  fi

  # ── Nerd Font ──
  step "Nerd Font"
  if has_nerd_font; then
    ok "já existe uma Nerd Font instalada"
  else
    FONT_DIR="$HOME/.local/share/fonts"
    run mkdir -p "$FONT_DIR"
    run curl -fsSL -o /tmp/Hack.zip \
      https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip
    run unzip -oq /tmp/Hack.zip -d "$FONT_DIR/HackNerdFont"
    run rm -f /tmp/Hack.zip
    have fc-cache && run fc-cache -f >/dev/null 2>&1
    ok "Hack Nerd Font instalada"
    warn "configure a fonte do seu TERMINAL para 'Hack Nerd Font Mono' — senão os ícones viram quadrados"
  fi
fi

# ── 2. A config ───────────────────────────────────────────────
if [ "$DO_CONFIG" = 1 ]; then
  step "Instalando a config"

  [ -d "$REPO_DIR/nvim" ] || die "não achei a pasta 'nvim/' ao lado do install.sh"

  TS="$(date +%Y%m%d-%H%M%S)"
  for d in "$HOME/.config/nvim" "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"; do
    if [ -e "$d" ]; then
      run mv "$d" "$d.bak.$TS"
      ok "backup: $(basename "$d") → $(basename "$d").bak.$TS"
    fi
  done

  run mkdir -p "$HOME/.config"
  run cp -r "$REPO_DIR/nvim" "$HOME/.config/nvim"
  ok "config copiada para ~/.config/nvim"

  # ── PATH ──
  SHELL_RC=""
  case "${SHELL##*/}" in
    zsh)  SHELL_RC="$HOME/.zshrc" ;;
    bash) SHELL_RC="$HOME/.bashrc" ;;
  esac
  if [ -n "$SHELL_RC" ] && [ -f "$SHELL_RC" ]; then
    if ! grep -q '.cargo/bin' "$SHELL_RC" 2>/dev/null; then
      if [ "$DRY_RUN" = 0 ]; then
        printf '\n# rust toolchain (rustup)\nexport PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"\n' >> "$SHELL_RC"
      fi
      ok "PATH atualizado em $(basename "$SHELL_RC")"
    fi
  fi

  # ── Plugins, parsers e ferramentas ──
  export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
  if [ "$DRY_RUN" = 0 ]; then
    step "Baixando plugins (pode levar alguns minutos)"
    nvim --headless "+Lazy! sync" +qa 2>&1 | tail -3 || warn "o Lazy sync reclamou; rode ':Lazy sync' dentro do nvim"
    ok "plugins instalados"

    step "Compilando parsers do treesitter"
    nvim --headless "+lua vim.defer_fn(function() vim.cmd('qa!') end, 180000)" >/dev/null 2>&1 || true
    n_parsers=$(ls "$HOME/.local/share/nvim/site/parser/" 2>/dev/null | wc -l)
    ok "$n_parsers parsers compilados"

    step "Instalando ferramentas do Mason (codelldb, taplo, stylua...)"
    nvim --headless \
      -c "lua require('lazy').load({ plugins = { 'mason.nvim' } })" \
      -c "lua local r=require('mason-registry'); r.refresh(); local w={'codelldb','taplo','lua-language-server','stylua','shfmt'}; local p=0; for _,n in ipairs(w) do local o,pk=pcall(r.get_package,n); if o and not pk:is_installed() then p=p+1; pk:once('install:success',function() p=p-1 end); pk:once('install:failed',function() p=p-1 end); pk:install() end end; vim.wait(300000, function() return p==0 end, 500)" \
      -c "qa!" >/dev/null 2>&1 || warn "algumas ferramentas do Mason falharam; rode ':Mason' dentro do nvim"
    ok "ferramentas do Mason instaladas"
  fi
fi

# ── 3. Verificação ────────────────────────────────────────────
step "Verificação"
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
missing=0
check() {
  if have "$1"; then ok "$1  $(command -v "$1")"
  else printf "  ${ERR}✗${R} %s ${DIM}(%s)${R}\n" "$1" "$2"; missing=$((missing+1)); fi
}
check nvim          "o editor"
check rustc         "compilador Rust"
check cargo         "build system do Rust"
check rust-analyzer "LSP do Rust"
check rg            "ripgrep — busca"
check git           "git"
check tree-sitter   "compila os parsers de sintaxe"
check lazygit       "TUI de git (<Espaço>gg)"

if has_nerd_font; then ok "Nerd Font instalada"
else warn "nenhuma Nerd Font encontrada — os ícones vão aparecer como quadrados"; fi

printf "\n"
if [ "$missing" -eq 0 ]; then
  printf "  ${OK}${B}Tudo pronto.${R}\n\n"
  printf "  Abra o editor:   ${B}nvim${R}\n"
  printf "  Diagnóstico:     ${B}:checkhealth${R}\n"
  printf "  Ver os atalhos:  segure ${B}<Espaço>${R} e espere\n\n"
  printf "  ${DIM}Lembre de apontar a fonte do terminal para uma Nerd Font.${R}\n\n"
else
  printf "  ${WARN}${B}Faltam $missing item(ns).${R} Instale-os e rode de novo.\n\n"
  exit 1
fi
