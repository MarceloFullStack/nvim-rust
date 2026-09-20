#!/usr/bin/env python3
"""
Gera docs/index.html (a página do GitHub Pages) a partir de docs/manual.html.

O manual.html é escrito sem <!doctype>/<html>/<head>/<body> porque nasceu para
um host que fornece esse esqueleto. Este script embrulha o conteúdo num
documento HTML completo e acrescenta o que só faz sentido na versão pública:
charset e viewport, metadados sociais, o bloco de instalação no topo e um
botão de tema (a página hospedada não herda o tema de nenhum host).

Uso:  python3 tools/build-docs.py
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "docs" / "manual.html"
OUT = ROOT / "docs" / "index.html"

REPO_URL = "https://github.com/MarceloFullStack/nvim-rust"
PAGES_URL = "https://marcelofullstack.github.io/nvim-rust/"
DESCRIPTION = (
    "Config de Neovim para Rust: rust-analyzer, debugger, IA integrada e um "
    "manual completo — da gramática do Vim às receitas do dia a dia."
)

# ── Reset equivalente ao que o host do artifact injeta, mais o que a
#    página hospedada precisa por conta própria. ───────────────────────
RESET = """
/* ── Reset (a versão hospedada não herda esqueleto de nenhum host) ── */
html{color-scheme:light dark}
body{margin:0}
img{max-width:100%}
[hidden]{display:none!important}

/* ── Bloco de instalação, no topo ──────────────────────────────────── */
.getit{
  margin-top:26px; padding:18px 20px;
  border:1px solid var(--line); border-radius:12px;
  background:var(--surface); box-shadow:var(--shadow);
  display:flex; flex-direction:column; gap:12px; max-width:62ch;
}
.getit-head{
  font-family:var(--f-mono); font-size:.6875rem; font-weight:600;
  letter-spacing:.14em; text-transform:uppercase; color:var(--accent);
  display:flex; align-items:center; justify-content:space-between; gap:12px;
}
.getit-cmd{margin:0}
.getit-cmd pre{margin:0; background:var(--bg)}
.copy{
  font-family:var(--f-mono); font-size:.6875rem; letter-spacing:.06em;
  padding:4px 10px; border-radius:6px; cursor:pointer; flex:none;
  border:1px solid var(--line); background:var(--surface); color:var(--fg-soft);
  text-transform:none; font-weight:500;
}
.copy:hover{color:var(--accent); border-color:var(--accent)}
.copy.done{color:var(--green); border-color:var(--green)}
.getit-links{display:flex; flex-wrap:wrap; gap:8px}
.btn{
  font-size:var(--step--1); font-weight:500; text-decoration:none;
  padding:7px 14px; border-radius:7px;
  border:1px solid var(--line); color:var(--fg); background:var(--bg);
  display:inline-flex; align-items:center; gap:7px;
}
.btn:hover{border-color:var(--accent); color:var(--accent)}
.btn.primary{background:var(--accent); border-color:var(--accent); color:#fff}
.btn.primary:hover{opacity:.9; color:#fff}
:root:not([data-theme="light"]) .btn.primary{color:#16161e}
@media (prefers-color-scheme:light){
  :root:not([data-theme="dark"]) .btn.primary{color:#fff}
}
:root[data-theme="dark"] .btn.primary{color:#16161e}
.getit-note{margin:0; font-size:var(--step--1); color:var(--muted); text-wrap:pretty}

/* ── Botão de tema ─────────────────────────────────────────────────── */
.theme-btn{
  margin:10px 20px 0; padding:6px 10px; cursor:pointer;
  font-family:var(--f-mono); font-size:.6875rem; text-align:left;
  border:1px solid var(--line); border-radius:7px;
  background:var(--bg); color:var(--fg-soft);
  display:flex; align-items:center; gap:7px;
}
.theme-btn:hover{color:var(--accent); border-color:var(--accent)}
@media (max-width:900px){.theme-btn{margin:10px 14px 0}}
"""

# ── O bloco que aparece no topo da página ─────────────────────────────
GETIT = f"""
    <div class="getit">
      <div class="getit-head">
        <span>Quer essa config na sua máquina?</span>
        <button class="copy" id="copy" type="button">copiar</button>
      </div>
      <div class="getit-cmd">
        <pre><code id="cmd">git clone {REPO_URL}.git
cd nvim-rust &amp;&amp; ./install.sh</code></pre>
      </div>
      <div class="getit-links">
        <a class="btn primary" href="{REPO_URL}">Ver no GitHub</a>
        <a class="btn" href="{REPO_URL}/archive/refs/heads/main.zip">Baixar .zip</a>
        <a class="btn" href="#setup">O que vem dentro</a>
      </div>
      <p class="getit-note">O instalador resolve dependências do sistema, toolchain Rust via rustup,
      Nerd Font, plugins, parsers do treesitter e ferramentas do Mason. Configs existentes viram
      <code>.bak</code> — nada é apagado. Rode com <code>--dry-run</code> pra ver o que faria antes.
      Arch, Debian/Ubuntu, Fedora, openSUSE e macOS.</p>
    </div>
"""

# ── Scripts extras da versão hospedada ────────────────────────────────
EXTRA_JS = """
(function(){
  // ── Botão de copiar o comando ──
  var btn = document.getElementById('copy');
  var cmd = document.getElementById('cmd');
  if(btn && cmd){
    btn.addEventListener('click', function(){
      var text = cmd.innerText;
      var done = function(){
        btn.textContent = 'copiado';
        btn.classList.add('done');
        setTimeout(function(){ btn.textContent = 'copiar'; btn.classList.remove('done'); }, 1600);
      };
      if(navigator.clipboard && navigator.clipboard.writeText){
        navigator.clipboard.writeText(text).then(done, fallback);
      } else { fallback(); }
      function fallback(){
        var ta = document.createElement('textarea');
        ta.value = text; ta.style.position = 'fixed'; ta.style.opacity = '0';
        document.body.appendChild(ta); ta.select();
        try { document.execCommand('copy'); done(); } catch(e){}
        document.body.removeChild(ta);
      }
    });
  }

  // ── Tema: segue o sistema até o leitor escolher ──
  var root = document.documentElement;
  var tbtn = document.getElementById('theme');
  if(!tbtn) return;
  var stored = null;
  try { stored = localStorage.getItem('theme'); } catch(e){}
  if(stored === 'dark' || stored === 'light') root.setAttribute('data-theme', stored);

  var label = function(){
    var explicit = root.getAttribute('data-theme');
    var dark = explicit ? explicit === 'dark'
             : window.matchMedia('(prefers-color-scheme: dark)').matches;
    tbtn.textContent = dark ? '☀  tema claro' : '☾  tema escuro';
  };
  label();
  tbtn.addEventListener('click', function(){
    var explicit = root.getAttribute('data-theme');
    var dark = explicit ? explicit === 'dark'
             : window.matchMedia('(prefers-color-scheme: dark)').matches;
    var next = dark ? 'light' : 'dark';
    root.setAttribute('data-theme', next);
    try { localStorage.setItem('theme', next); } catch(e){}
    label();
  });
})();
"""


def main() -> int:
    if not SRC.exists():
        print(f"erro: não achei {SRC}", file=sys.stderr)
        return 1

    src = SRC.read_text(encoding="utf-8")

    # O head é tudo até o fim do primeiro bloco <style>; o resto é o corpo.
    marker = "</style>"
    idx = src.find(marker)
    if idx == -1:
        print("erro: não achei o </style> que separa head e corpo", file=sys.stderr)
        return 1
    head, body = src[:idx], src[idx + len(marker):]

    title_match = re.search(r"<title>(.*?)</title>", head, re.S)
    title = title_match.group(1).strip() if title_match else "Manual do Neovim Rust"

    # O reset entra no fim do <style>, para que as regras da página
    # (definidas antes) continuem vencendo por ordem quando empatam.
    head = head + RESET + marker

    # O bloco de instalação entra logo depois da linha de estatísticas do topo.
    anchor = "</div>\n  </div>\n</header>"
    if anchor not in body:
        print("erro: não achei o fim do hero para inserir o bloco de instalação",
              file=sys.stderr)
        return 1
    body = body.replace(anchor, "</div>\n" + GETIT + "  </div>\n</header>", 1)

    # Botão de tema no topo do menu lateral.
    rail_anchor = '<div class="who">manual de bordo</div>\n  </div>'
    if rail_anchor not in body:
        print("erro: não achei o cabeçalho do menu lateral", file=sys.stderr)
        return 1
    body = body.replace(
        rail_anchor,
        '<div class="who">manual de bordo</div>\n  </div>\n'
        '  <button class="theme-btn" id="theme" type="button">tema</button>',
        1,
    )

    # Os scripts extras entram no fim do último <script> existente.
    tail = "</script>"
    last = body.rfind(tail)
    if last == -1:
        print("erro: não achei o bloco <script> final", file=sys.stderr)
        return 1
    body = body[:last] + EXTRA_JS + body[last:]

    doc = f"""<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="{DESCRIPTION}">
<meta name="color-scheme" content="light dark">
<link rel="canonical" href="{PAGES_URL}">
<meta property="og:type" content="website">
<meta property="og:title" content="{title}">
<meta property="og:description" content="{DESCRIPTION}">
<meta property="og:url" content="{PAGES_URL}">
<meta name="twitter:card" content="summary">
<link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'><text y='14' font-size='14'>⌨️</text></svg>">
{head}
</head>
<body>
{body.strip()}
</body>
</html>
"""
    OUT.write_text(doc, encoding="utf-8")
    kb = len(doc.encode("utf-8")) / 1024
    print(f"gerado {OUT.relative_to(ROOT)}  ({kb:.0f} KB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
