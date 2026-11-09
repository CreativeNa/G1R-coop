#!/usr/bin/env python3
"""Diff two reflection dumps: what changed between game builds.

Reads  two classes_<pid>.txt dumps
Writes docs/RE/CHANGES_<label>.md

The point is to answer "what changed in the patch" without reading 9 MB of text:
new/removed classes, classes whose property or function count changed, and the
individual properties that appeared or disappeared.

Usage:  python tools\\dump_diff.py <old dump> <new dump> [label]
"""
import os
import re
import sys
import collections

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT_DIR = os.path.join(ROOT, "docs", "RE")

RE_CLASS = re.compile(r"^(class|struct) (\S+) : (\S+) \[(.+)\]\s*$")
RE_PROP = re.compile(r"^  prop (\S+) (.+?) @(\d+)/(\d+)(?: -> (.+?))?\s*$")
RE_FN = re.compile(r"^  fn (.+?)\s*$")


def parse(path):
    out = {}
    totals = {"props": 0, "fns": 0}
    cur = None
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            if not line.strip() or line.startswith("#"):
                continue
            m = RE_CLASS.match(line)
            if m:
                cur = {"kind": m.group(1), "super": m.group(3), "pkg": m.group(4), "props": {}, "fns": set()}
                out[m.group(2)] = cur
                continue
            m = RE_PROP.match(line)
            if m and cur is not None:
                cur["props"][m.group(2)] = (m.group(1), int(m.group(3)), int(m.group(4)), m.group(5) or "")
                totals["props"] += 1
                continue
            m = RE_FN.match(line)
            if m and cur is not None:
                cur["fns"].add(m.group(1))
                totals["fns"] += 1
    return out, totals


def main():
    if len(sys.argv) < 3:
        sys.exit("usage: dump_diff.py <old dump> <new dump> [label]")
    old_path, new_path = sys.argv[1], sys.argv[2]
    label = sys.argv[3] if len(sys.argv) > 3 else "patch"
    old, told = parse(old_path)
    new, tnew = parse(new_path)

    added = sorted(set(new) - set(old))
    removed = sorted(set(old) - set(new))

    changed = []
    for name in sorted(set(old) & set(new)):
        o, n = old[name], new[name]
        if len(o["props"]) != len(n["props"]) or len(o["fns"]) != len(n["fns"]) or o["super"] != n["super"]:
            changed.append(name)

    lines = ["# What changed: %s" % label, "",
             "`%s` → `%s`" % (os.path.basename(old_path), os.path.basename(new_path)), "",
             "| | old | new |", "|---|---|---|",
             "| classes/structs | %d | %d |" % (len(old), len(new)),
             "| properties | %d | %d |" % (told["props"], tnew["props"]),
             "| functions | %d | %d |" % (told["fns"], tnew["fns"]),
             "",
             "New classes: **%d**, removed: **%d**, changed: **%d**" % (len(added), len(removed), len(changed)),
             ""]

    if added:
        lines += ["## New classes (%d)" % len(added), ""]
        for name in added[:200]:
            c = new[name]
            lines.append("* `%s` (%s, %s) — %d props, %d fns" % (name, c["kind"], c["pkg"], len(c["props"]), len(c["fns"])))
        if len(added) > 200:
            lines.append("")
            lines.append("… and %d more" % (len(added) - 200))
        lines.append("")

    if removed:
        lines += ["## Removed classes (%d)" % len(removed), ""]
        for name in removed[:100]:
            lines.append("* `%s`" % name)
        lines.append("")

    if changed:
        lines += ["## Classes whose members changed (%d)" % len(changed), ""]
        lines += ["| class | props old→new | fns old→new | new properties |", "|---|---|---|---|"]
        for name in changed[:250]:
            o, n = old[name], new[name]
            newprops = sorted(set(n["props"]) - set(o["props"]))
            lines.append("| `%s` | %d → %d | %d → %d | %s |" % (
                name, len(o["props"]), len(n["props"]), len(o["fns"]), len(n["fns"]),
                ", ".join("`%s`" % p for p in newprops[:8]) + (" …" if len(newprops) > 8 else "")))
        if len(changed) > 250:
            lines.append("")
            lines.append("… and %d more" % (len(changed) - 250))
        lines.append("")

    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, "CHANGES_%s.md" % label)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("written: %s" % path)
    print("added %d, removed %d, changed %d" % (len(added), len(removed), len(changed)))


if __name__ == "__main__":
    main()
