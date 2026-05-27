#!/usr/bin/env python3
"""Bundle the four PlayGrid quote docs into a single printable HTML.

Companion to ``build-quote-pdf.sh`` which then prints the HTML to a
PDF using Firefox headless. Kept tiny on purpose — no jinja, no
templating engine, no design tokens; just markdown -> HTML and a
hand-written stylesheet tuned for A4 print.
"""

from __future__ import annotations

import pathlib
import sys

import markdown


ROOT = pathlib.Path(__file__).resolve().parent.parent

# Order matters: comparison up front so the reader sees prices first,
# then the individual quotes drill into clauses.
DOCS = [
    ("Pricing at a glance", ROOT / "docs" / "pricing-comparison.md"),
    ("Pilot estimate", ROOT / "docs" / "pilot-estimate.md"),
    ("Build-only estimate", ROOT / "docs" / "estimate.md"),
    ("Full launch + running costs", ROOT / "docs" / "launch-and-running-costs.md"),
]

STYLE = """
@page { size: A4; margin: 18mm 15mm; }
* { box-sizing: border-box; }
body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
               "Helvetica Neue", Arial, sans-serif;
  font-size: 10.5pt;
  line-height: 1.45;
  color: #1a1a1a;
  margin: 0;
}
header.cover {
  page-break-after: always;
  padding: 25mm 0;
  border-bottom: 4px solid #2a4dde;
}
header.cover h1 {
  font-size: 32pt;
  margin: 0 0 8mm 0;
  letter-spacing: -0.5px;
}
header.cover p { font-size: 13pt; margin: 2mm 0; color: #555; }
header.cover .meta {
  margin-top: 18mm;
  font-size: 10pt;
  color: #777;
}
section.doc { page-break-before: always; }
section.doc:first-of-type { page-break-before: auto; }
section.doc > h1.section-title {
  font-size: 22pt;
  margin: 0 0 10mm 0;
  padding-bottom: 4mm;
  border-bottom: 2px solid #2a4dde;
  color: #2a4dde;
  letter-spacing: -0.3px;
}
h1, h2, h3, h4 {
  font-weight: 700;
  page-break-after: avoid;
}
h1 { font-size: 18pt; margin-top: 9mm; }
h2 { font-size: 14pt; margin-top: 8mm; }
h3 { font-size: 12pt; margin-top: 6mm; }
p { margin: 3mm 0; }
ul, ol { margin: 3mm 0 3mm 6mm; padding: 0; }
li { margin: 1.5mm 0; }
table {
  border-collapse: collapse;
  width: 100%;
  margin: 4mm 0;
  font-size: 10pt;
  page-break-inside: avoid;
}
th, td {
  padding: 2.5mm 3mm;
  border: 1px solid #ddd;
  text-align: left;
  vertical-align: top;
}
th { background: #f4f6ff; font-weight: 600; color: #2a4dde; }
tr:nth-child(even) td { background: #fafbff; }
code {
  background: #f4f4f4;
  padding: 0.5mm 1.5mm;
  border-radius: 1.5mm;
  font-size: 9.5pt;
  font-family: "SF Mono", Menlo, Consolas, monospace;
}
pre {
  background: #f4f4f4;
  padding: 3mm;
  border-radius: 2mm;
  overflow-x: auto;
  font-size: 9pt;
  page-break-inside: avoid;
}
hr { border: 0; border-top: 1px solid #e0e0e0; margin: 5mm 0; }
blockquote {
  border-left: 3px solid #2a4dde;
  padding-left: 4mm;
  color: #555;
  margin: 3mm 0;
}
.toc {
  background: #f4f6ff;
  padding: 4mm 6mm;
  border-radius: 3mm;
  margin: 8mm 0;
}
.toc h2 { margin-top: 0; }
.toc ol { margin: 2mm 0 0 6mm; }
"""


def render() -> str:
    md = markdown.Markdown(extensions=["tables", "fenced_code", "toc"])
    sections: list[str] = []
    toc_items: list[str] = []
    for index, (title, path) in enumerate(DOCS, start=1):
        if not path.exists():
            print(f"[warn] missing: {path}", file=sys.stderr)
            continue
        md.reset()
        body = md.convert(path.read_text(encoding="utf-8"))
        anchor = f"section-{index}"
        toc_items.append(f'<li><a href="#{anchor}">{title}</a></li>')
        sections.append(
            f'<section class="doc" id="{anchor}">\n'
            f'  <h1 class="section-title">{index}. {title}</h1>\n'
            f"  {body}\n"
            f"</section>"
        )

    toc_html = (
        '<div class="toc">\n'
        "  <h2>Contents</h2>\n"
        f'  <ol>{"".join(toc_items)}</ol>\n'
        "</div>"
    )

    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>PlayGrid Club — Project Quotes</title>
  <style>{STYLE}</style>
</head>
<body>
  <header class="cover">
    <h1>PlayGrid Club</h1>
    <p>Freelance project quotes — pilot, build, and full launch</p>
    <p>Prepared by Venkatakrishnan Ramesh</p>
    <div class="meta">
      <p>Repository · github.com/Venkatakrishnan-Ramesh/playgrid</p>
      <p>Date · 2026-05-20</p>
      <p>Quote validity · 30 days</p>
    </div>
    {toc_html}
  </header>
  {chr(10).join(sections)}
</body>
</html>
"""


def main() -> int:
    out_dir = ROOT / "docs" / "build"
    out_dir.mkdir(parents=True, exist_ok=True)
    html_path = out_dir / "quotes.html"
    html_path.write_text(render(), encoding="utf-8")
    print(html_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
