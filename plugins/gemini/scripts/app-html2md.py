"""Wandelt einen aus der Gemini-App exportierten Bericht (HTML aus der Zwischenablage) in Markdown um.

Aufruf: app-html2md.py <eingabe.html> <ausgabe.md>

Nur Standardbibliothek. Unter Windows liefert die Zwischenablage CF_HTML (Kopf „Version:…“),
dessen UTF-8-Bytes .NET als cp1252 gelesen hat; das wird hier zurückgerechnet.
"""
import re
import sys
from html.parser import HTMLParser

VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source", "track", "wbr"}
BLOCK = {"address", "article", "aside", "blockquote", "body", "div", "dl", "figure", "footer", "form", "h1", "h2",
         "h3", "h4", "h5", "h6", "header", "hr", "li", "main", "nav", "ol", "p", "pre", "section", "table", "ul"}


class Node:
    def __init__(self, name, attrs=None):
        self.name = name
        self.attrs = dict(attrs or [])
        self.children = []

    def find_all(self, names, recursive=True):
        names = {names} if isinstance(names, str) else set(names)
        found = []
        for child in self.children:
            if isinstance(child, Node):
                if child.name in names:
                    found.append(child)
                if recursive:
                    found.extend(child.find_all(names))
        return found


class TreeBuilder(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.root = Node("document")
        self.stack = [self.root]

    def handle_starttag(self, tag, attrs):
        node = Node(tag, attrs)
        self.stack[-1].children.append(node)
        if tag not in VOID:
            self.stack.append(node)

    def handle_startendtag(self, tag, attrs):
        self.stack[-1].children.append(Node(tag, attrs))

    def handle_endtag(self, tag):
        for i in range(len(self.stack) - 1, 0, -1):
            if self.stack[i].name == tag:
                del self.stack[i:]
                return

    def handle_data(self, data):
        self.stack[-1].children.append(data)


def inline(node):
    if isinstance(node, str):
        return re.sub(r"\s+", " ", node)
    if node.name in ("script", "style"):
        return ""
    inner = "".join(inline(c) for c in node.children)
    if node.name in ("strong", "b"):
        return f"**{inner.strip()}**" if inner.strip() else ""
    if node.name in ("em", "i"):
        return f"*{inner.strip()}*" if inner.strip() else ""
    if node.name == "code":
        return f"`{inner.strip()}`"
    if node.name == "a" and node.attrs.get("href", "").startswith("http"):
        text = inner.strip() or node.attrs["href"]
        return f"[{text}]({node.attrs['href']})"
    if node.name == "br":
        return "  \n"
    return inner


def table(node):
    rows = []
    for tr in node.find_all("tr"):
        cells = [inline(c).strip().replace("|", "\\|") for c in tr.find_all(["th", "td"])]
        rows.append(cells)
    if not rows:
        return ""
    width = max(len(r) for r in rows)
    rows = [r + [""] * (width - len(r)) for r in rows]
    out = ["| " + " | ".join(rows[0]) + " |", "|" + "---|" * width]
    out += ["| " + " | ".join(r) + " |" for r in rows[1:]]
    return "\n".join(out)


def block(node, depth=0):
    if isinstance(node, str):
        text = re.sub(r"\s+", " ", node).strip()
        return [text] if text else []
    name = node.name
    if name in ("script", "style", "head"):
        return []
    if re.fullmatch(r"h[1-6]", name):
        return ["#" * int(name[1]) + " " + inline(node).strip()]
    if name == "p":
        text = inline(node).strip()
        return [text] if text else []
    if name in ("ul", "ol"):
        out = []
        for k, li in enumerate(node.find_all("li", recursive=False), 1):
            mark = f"{k}." if name == "ol" else "-"
            parts = [inline(c) for c in li.children if not (isinstance(c, Node) and c.name in ("ul", "ol"))]
            out.append("  " * depth + f"{mark} " + "".join(parts).strip())
            for sub in li.find_all(["ul", "ol"], recursive=False):
                out.extend(block(sub, depth + 1))
        return ["\n".join(out)]
    if name == "table":
        return [table(node)]
    if name == "hr":
        return ["---"]
    if name == "blockquote":
        return ["> " + inline(node).strip()]
    # Aufeinanderfolgende Inline-Teile (Text, Spans, Fett, Links …) bilden einen Absatz;
    # kurze Chat-Antworten stehen ohne <p> direkt in einem <div>.
    out, run = [], []

    def flush():
        text = "".join(inline(c) for c in run).strip()
        if text:
            out.append(text)
        run.clear()

    for child in node.children:
        if isinstance(child, str) or (child.name not in BLOCK and not child.find_all(BLOCK)):
            run.append(child)
        else:
            flush()
            out.extend(block(child, depth))
    flush()
    return out


def fix_mojibake(text):
    raw = bytearray()
    for ch in text:
        if ord(ch) < 256:
            raw.append(ord(ch))
        else:
            raw.extend(ch.encode("cp1252"))
    return raw.decode("utf-8", errors="replace")


def clean(text):
    lines = [l for l in text.split("\n") if l not in ("StartFragment", "EndFragment")]
    text = "\n".join(lines)
    text = re.sub(r" {3,}$", "", text, flags=re.M)
    text = re.sub(r"([^ \n]) {3,}", r"\1 ", text)
    return re.sub(r" +([,.;:!?])", r"\1", text)


def main(src, dst):
    html = open(src, encoding="utf-8").read()
    if html.startswith("Version:"):
        html = fix_mojibake(html)
    start = html.find("<html")
    builder = TreeBuilder()
    builder.feed(html[start:] if start >= 0 else html)
    builder.close()
    bodies = builder.root.find_all("body")
    body = bodies[0] if bodies else builder.root
    parts = [p for p in block(body) if p.strip()]
    text = clean("\n\n".join(parts).strip() + "\n")
    open(dst, "w", encoding="utf-8", newline="\n").write(text)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
