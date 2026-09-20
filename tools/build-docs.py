#!/usr/bin/env python3
"""
Gera docs/index.html (a página do GitHub Pages) a partir de docs/manual.html.

O manual.html é escrito sem <!doctype>/<html>/<head>/<body> porque nasceu para
um host que fornece esse esqueleto. Este script embrulha o conteúdo num
documento HTML completo e acrescenta o que só faz sentido na versão pública:
charset e viewport, metadados sociais e o bloco de instalação no topo.

A página é dark-only de propósito: a identidade vem do Git Hydra, que é um
preto esverdeado com neon. Não há alternância de tema para quebrar isso.

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
html{color-scheme:dark}
body{margin:0}
img{max-width:100%}
[hidden]{display:none!important}

/* ── Bloco de instalação, no topo ──────────────────────────────────── */
.getit{
  margin-top:26px; padding:18px 20px; position:relative; overflow:hidden;
  border:1px solid var(--glow-line); border-radius:12px;
  background:var(--surface); box-shadow:var(--shadow), var(--glow);
  display:flex; flex-direction:column; gap:12px; max-width:62ch;
}
.getit::before{
  content:""; position:absolute; top:0; left:0; right:0; height:1px;
  background:linear-gradient(90deg,transparent,var(--accent),transparent);
}
.getit-head{
  font-family:var(--f-mono); font-size:.6875rem; font-weight:600;
  letter-spacing:.14em; text-transform:uppercase; color:var(--accent);
  display:flex; align-items:center; justify-content:space-between; gap:12px;
  text-shadow:0 0 16px rgba(52,211,153,.4);
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
.btn.primary{
  background:var(--accent); border-color:var(--accent); color:#04120c; font-weight:600;
  box-shadow:0 0 22px rgba(52,211,153,.28);
}
.btn.primary:hover{background:var(--accent-deep); color:#04120c; border-color:var(--accent-deep)}
.getit-note{margin:0; font-size:var(--step--1); color:var(--muted); text-wrap:pretty}

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

})();
"""


def png_size(path):
    """Lê largura e altura do cabeçalho IHDR de um PNG, sem dependências."""
    with open(path, "rb") as fh:
        head = fh.read(24)
    if len(head) < 24 or head[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    return int.from_bytes(head[16:20], "big"), int.from_bytes(head[20:24], "big")


def check_images(body):
    """Confere que cada <img> aponta para um arquivo existente e que as
    dimensões declaradas batem com as reais.

    Trocar a imagem e esquecer do width/height deixa a página com a proporção
    errada — o navegador reserva o espaço pelo que está escrito no HTML.
    """
    problems = []
    for m in re.finditer(r'<img\s+src="([^"]+)"\s+width="(\d+)"\s+height="(\d+)"', body):
        src, w, h = m.group(1), int(m.group(2)), int(m.group(3))
        path = ROOT / "docs" / src
        if not path.exists():
            problems.append("imagem não encontrada: docs/%s" % src)
            continue
        real = png_size(path)
        if real and real != (w, h):
            problems.append(
                "docs/%s mede %dx%d, mas o HTML declara %dx%d"
                % (src, real[0], real[1], w, h))
    return problems


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

    problems = check_images(body)
    if problems:
        for p in problems:
            print("erro: " + p, file=sys.stderr)
        return 1

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
<link rel="icon" type="image/png" href="assets/git-hydra-64.png">
<meta property="og:image" content="{PAGES_URL}assets/git-hydra.png">
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
