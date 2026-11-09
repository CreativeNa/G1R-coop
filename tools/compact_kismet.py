#!/usr/bin/env python3
"""Turn the bytecode AST written by uasset2json --kismet into a compact linear text.

Input : <Asset>.kismet.txt   (a list of "// ==== Function ====" blocks, each a JSON AST)
Output: <Asset>.kismet.compact.txt   (one instruction per line, structure inline)

The AST is faithful but very verbose (a few hundred KB per blueprint). This keeps every bit of
information but folded onto lines, which is what a human or an LLM can actually scan.

Usage:  python tools\\compact_kismet.py <file-or-directory> [...]
"""
import json
import os
import re
import sys

MARKER = re.compile(r"^// ==== (.+?) ====\s*$")

# keys that add noise without information
NOISE = {"PinCategory", "PinSubCategory", "PinSubCategoryObject", "StatementIndex"}


def render(node):
    if isinstance(node, list):
        return "[" + ", ".join(render(x) for x in node) + "]"
    if isinstance(node, dict):
        inst = node.get("Inst", "?")
        parts = []
        for k, v in node.items():
            if k == "Inst" or k in NOISE:
                continue
            if isinstance(v, (dict, list)):
                if not v:
                    continue
                parts.append(render(v))
            elif v is None:
                continue
            else:
                parts.append(str(v))
        return inst + ("(" + ", ".join(parts) + ")" if parts else "")
    return str(node)


def convert_file(path):
    out_path = path.replace(".kismet.txt", ".kismet.compact.txt")
    lines = []
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        text = f.read()

    # split into blocks: marker line followed by one JSON value
    blocks = []
    cur_name, buf = None, []
    for line in text.splitlines():
        m = MARKER.match(line)
        if m:
            if cur_name is not None:
                blocks.append((cur_name, "\n".join(buf)))
            cur_name, buf = m.group(1), []
        elif cur_name is not None:
            buf.append(line)
    if cur_name is not None:
        blocks.append((cur_name, "\n".join(buf)))

    for name, body in blocks:
        lines.append("")
        lines.append("== " + name + " ==")
        try:
            ast = json.loads(body)
        except Exception as ex:
            lines.append("   ! could not parse: " + str(ex))
            continue
        if not isinstance(ast, list):
            lines.append("   " + render(ast))
            continue
        for ins in ast:
            idx = ins.get("StatementIndex") if isinstance(ins, dict) else None
            prefix = ("%4s: " % idx) if idx is not None else "      "
            lines.append(prefix + render(ins))

    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    return out_path


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: compact_kismet.py <file-or-directory> [...]")
    done = 0
    for arg in sys.argv[1:]:
        if os.path.isdir(arg):
            for dirpath, _d, files in os.walk(arg):
                for fn in files:
                    if fn.endswith(".kismet.txt") and not fn.endswith(".compact.txt"):
                        convert_file(os.path.join(dirpath, fn))
                        done += 1
        elif arg.endswith(".kismet.txt"):
            convert_file(arg)
            done += 1
    print("compacted %d files" % done)


if __name__ == "__main__":
    main()
