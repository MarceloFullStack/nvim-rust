#!/usr/bin/env python3
"""
Fotografa uma sessão do Neovim em HTML — útil para conferir o tema e gerar
imagens de documentação sem precisar de um terminal gráfico.

Roda o editor dentro de um pty, alimenta um emulador de terminal com a saída
e transcreve a grade de células (com as cores que o editor realmente emitiu)
para uma página HTML, que você abre no navegador e captura.

    python3 tools/screenshot.py saida.html nvim src/main.rs
    python3 tools/screenshot.py saida.html nvim . --keys '@10' $'\\x02'

Em --keys, cada argumento é uma tecla enviada em sequência; "@N" não é tecla,
é uma pausa de N segundos (para esperar algo lento, como um CLI de IA subindo).

Requer: pip install pyte
"""
import base64
import fcntl
import html as html_mod
import os
import pty
import re
import select
import struct
import sys
import termios
import time

import pyte

COLS = int(os.environ.get("COLS", 150))
ROWS = int(os.environ.get("ROWS", 40))
SETTLE = float(os.environ.get("SETTLE", 25))

BG_DEFAULT = "#06090e"
FG_DEFAULT = "#f8fafc"

FONT_DIR = os.environ.get("FONT_DIR", "/usr/share/fonts/TTF")
FONT_FACES = [("HackNerdFontMono-Regular.ttf", 400),
              ("HackNerdFontMono-Bold.ttf", 700)]

# O Neovim manda texto e fundo como `38;2;R;G;B`, que o pyte divide sem
# problema. Mas a COR DO SUBLINHADO (SGR 58, usada no undercurl dos
# diagnostics) vem com dois-pontos — `58:2::R:G:B` — e aí o pyte não
# reconhece o token: ele vaza como texto no meio do buffer.
_SGR_SUBPARAM = re.compile(r"([345]8):2:[^:;m]*:(\d+):(\d+):(\d+)")
_SGR_INDEXED = re.compile(r"([345]8):5:(\d+)")
_SGR_UNDERSTYLE = re.compile(r"(?<=\[)4:\d(?=[;m])")


def normalize_sgr(text):
    text = _SGR_SUBPARAM.sub(lambda m: "%s;2;%s;%s;%s" % m.groups(), text)
    text = _SGR_INDEXED.sub(lambda m: "%s;5;%s" % m.groups(), text)
    return _SGR_UNDERSTYLE.sub("4", text)


class TrueColorScreen(pyte.Screen):
    """pyte modela cores indexadas; o Neovim emite 24 bits."""

    def select_graphic_rendition(self, *attrs, **kwargs):
        rest = []
        attrs = list(attrs) or [0]
        i = 0
        while i < len(attrs):
            a = attrs[i]
            if a in (38, 48, 58) and i + 4 < len(attrs) and attrs[i + 1] == 2:
                r, g, b = attrs[i + 2], attrs[i + 3], attrs[i + 4]
                if a != 58:  # 58 é cor de sublinhado; o pyte não modela isso
                    value = "%02x%02x%02x" % (r & 255, g & 255, b & 255)
                    field = "fg" if a == 38 else "bg"
                    self.cursor.attrs = self.cursor.attrs._replace(**{field: value})
                i += 5
                continue
            if a == 59:  # reset da cor de sublinhado
                i += 1
                continue
            rest.append(a)
            i += 1
        if rest:
            super().select_graphic_rendition(*rest, **kwargs)


def run(argv, keys=None, settle=SETTLE):
    screen = TrueColorScreen(COLS, ROWS)
    stream = pyte.Stream(screen)

    pid, fd = pty.fork()
    if pid == 0:
        os.environ["TERM"] = "xterm-256color"
        os.environ["COLORTERM"] = "truecolor"
        os.execvp(argv[0], argv)

    # O tamanho da janela vem do ioctl do tty, não das variáveis de ambiente:
    # sem isto o programa filho enxerga os 80x24 padrão e o layout sai cortado.
    fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", ROWS, COLS, 0, 0))

    def drain(timeout=0.2):
        r, _, _ = select.select([fd], [], [], timeout)
        if not r:
            return True
        try:
            data = os.read(fd, 65536)
        except OSError:
            return False
        if not data:
            return False
        stream.feed(normalize_sgr(data.decode("utf-8", "replace")))
        return True

    deadline = time.time() + settle
    sent = False
    while time.time() < deadline:
        if not drain():
            break
        if keys and not sent and time.time() > deadline - settle + 6.0:
            for k in keys:
                if k.startswith("@"):
                    until = time.time() + float(k[1:])
                    while time.time() < until:
                        drain(0.2)
                    continue
                os.write(fd, k.encode())
                time.sleep(0.5)
                for _ in range(14):
                    if not drain(0.15):
                        break
            sent = True

    try:
        os.write(fd, b"\x1b:qa!\r")
        time.sleep(0.4)
        os.close(fd)
    except OSError:
        pass
    return screen


def color(value, default):
    if not value or value == "default":
        return default
    if isinstance(value, str) and len(value) == 6:
        try:
            int(value, 16)
            return "#" + value
        except ValueError:
            pass
    named = {
        "black": "#121b28", "red": "#fb7185", "green": "#34d399",
        "brown": "#fbbf24", "yellow": "#fde047", "blue": "#22d3ee",
        "magenta": "#a78bfa", "cyan": "#2dd4bf", "white": "#f8fafc",
    }
    return named.get(value, default)


def font_face_css():
    """Embute a Nerd Font: o navegador não carrega fonte do sistema por
    local(), e sem ela os ícones saem como quadrados vazios."""
    blocks = []
    for name, weight in FONT_FACES:
        path = os.path.join(FONT_DIR, name)
        if not os.path.exists(path):
            continue
        with open(path, "rb") as fh:
            b64 = base64.b64encode(fh.read()).decode("ascii")
        blocks.append(
            ' @font-face{font-family:"HackNF";font-weight:%d;font-display:block;'
            'src:url(data:font/ttf;base64,%s) format("truetype")}' % (weight, b64))
    return "\n".join(blocks) or ' @font-face{font-family:"HackNF";src:local("monospace")}'


def to_html(screen, title):
    rows = []
    for y in range(screen.lines):
        line = screen.buffer[y]
        parts, run_txt, run_style = [], "", None

        def flush():
            nonlocal run_txt, run_style
            if run_txt:
                parts.append('<span style="%s">%s</span>'
                             % (run_style, html_mod.escape(run_txt)))
            run_txt = ""

        for x in range(screen.columns):
            ch = line[x]
            fg = color(ch.fg, FG_DEFAULT)
            bg = color(ch.bg, BG_DEFAULT)
            if ch.reverse:
                fg, bg = bg, fg
            style = "color:%s;background:%s" % (fg, bg)
            if ch.bold:
                style += ";font-weight:700"
            if ch.italics:
                style += ";font-style:italic"
            if style != run_style:
                flush()
                run_style = style
            run_txt += ch.data or " "
        flush()
        rows.append("".join(parts))

    return """<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8"><title>%(title)s</title>
<style>
%(fontface)s
 *{box-sizing:border-box}
 body{
   margin:0; min-height:100vh; display:grid; place-items:center; padding:56px 48px;
   background:
     radial-gradient(900px 520px at 72%% -10%%, rgba(16,185,129,.20), transparent 60%%),
     radial-gradient(760px 520px at -6%% 110%%, rgba(139,92,246,.18), transparent 58%%),
     #04070a;
 }
 .frame{
   border-radius:14px; overflow:hidden; width:100%%; background:%(bg)s;
   border:1px solid #1e2b3d;
   box-shadow:0 0 0 1px rgba(16,185,129,.18), 0 30px 80px rgba(0,0,0,.75),
              0 0 90px rgba(16,185,129,.12);
 }
 .bar{display:flex; align-items:center; gap:9px; padding:11px 15px;
      background:#0a1017; border-bottom:1px solid #16212f}
 .dot{width:11px;height:11px;border-radius:50%%}
 .bar .t{margin-left:10px; color:#64748b; font-size:12px;
         font-family:"HackNF",monospace; letter-spacing:.04em}
 pre{margin:0; padding:16px 18px; background:%(bg)s;
     font-family:"HackNF","Fira Code",monospace;
     font-size:14px; line-height:1.34; white-space:pre; overflow-x:auto}
 span{white-space:pre}
</style></head><body>
 <div class="frame">
  <div class="bar">
   <span class="dot" style="background:#fb7185"></span>
   <span class="dot" style="background:#fbbf24"></span>
   <span class="dot" style="background:#34d399"></span>
   <span class="t">%(title)s</span>
  </div>
  <pre>%(rows)s</pre>
 </div>
</body></html>
""" % {"title": html_mod.escape(title), "bg": BG_DEFAULT,
       "rows": "\n".join(rows), "fontface": font_face_css()}


if __name__ == "__main__":
    out = sys.argv[1]
    cmd = sys.argv[2:]
    keys = None
    if "--keys" in cmd:
        i = cmd.index("--keys")
        keys, cmd = cmd[i + 1:], cmd[:i]
    scr = run(cmd, keys=keys)
    with open(out, "w", encoding="utf-8") as f:
        f.write(to_html(scr, " ".join(cmd)))
    filled = sum(1 for y in range(scr.lines)
                 if "".join(c.data for c in scr.buffer[y].values()).strip())
    print("gerado %s  (%d linhas com conteúdo)" % (out, filled))
