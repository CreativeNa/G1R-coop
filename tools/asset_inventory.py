#!/usr/bin/env python3
"""Inventory of the content extracted from Gothic 1 Remake's IoStore containers.

Reads   extracted/legacy/            (written by: retoc to-legacy <Paks dir> extracted\\legacy)
Writes  sdk/assets.tsv               one row per extracted file: path, bytes, extension
        sdk/assets_summary.md        what is there, by folder and by extension

Nothing here parses UE assets - it is the map, not the content. Parsing .uasset/.uexp needs
CUE4Parse (FModel) or a custom reader; the paths and sizes are enough to decide what to open.

Usage:  python tools\\asset_inventory.py [extracted-dir]
"""
import os
import sys
import collections

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DEFAULT_DIR = os.path.join(ROOT, "extracted", "legacy")
OUT_DIR = os.path.join(ROOT, "sdk")

INTERESTING = (
    (".uasset", "UE package header (the object graph of one asset)"),
    (".uexp", "package exports (the actual data of the objects)"),
    (".ubulk", "bulk data: mesh/vertex buffers, textures, audio"),
    (".json", "JSON (data tables, configs, localization)"),
    (".csv", "CSV data"),
    (".ini", "config"),
    (".locres", "localization resource"),
    (".bnk", "Wwise sound bank"),
    (".wem", "Wwise audio stream"),
    (".umap", "level"),
)


def human(n):
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024 or unit == "GB":
            return "%.1f %s" % (n, unit)
        n /= 1024.0


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_DIR
    if not os.path.isdir(root):
        sys.exit("not a directory: %s" % root)

    rows = []
    by_ext = collections.Counter()
    by_ext_bytes = collections.Counter()
    by_top = collections.Counter()
    by_top_bytes = collections.Counter()
    total = 0

    for dirpath, _dirnames, filenames in os.walk(root):
        for fn in filenames:
            full = os.path.join(dirpath, fn)
            try:
                size = os.path.getsize(full)
            except OSError:
                continue
            rel = os.path.relpath(full, root).replace("\\", "/")
            ext = os.path.splitext(fn)[1].lower() or "(none)"
            rows.append((rel, size, ext))
            total += size
            by_ext[ext] += 1
            by_ext_bytes[ext] += size
            top = rel.split("/")[0]
            by_top[top] += 1
            by_top_bytes[top] += size

    rows.sort()
    os.makedirs(OUT_DIR, exist_ok=True)
    with open(os.path.join(OUT_DIR, "assets.tsv"), "w", encoding="utf-8", newline="\n") as f:
        f.write("path\tbytes\text\n")
        for rel, size, ext in rows:
            f.write("%s\t%d\t%s\n" % (rel, size, ext))

    md = []
    md.append("# Extracted content")
    md.append("")
    md.append("Source: `retoc to-legacy` over `Gothic 1 Remake/G1R/Content/Paks` (IoStore: .utoc + .ucas).")
    md.append("`scriptobjects.bin` comes from `global.utoc` and is required for a correct conversion.")
    md.append("")
    md.append("| | |")
    md.append("|---|---|")
    md.append("| files | %d |" % len(rows))
    md.append("| total size | %s |" % human(total))
    md.append("")
    md.append("## By extension")
    md.append("")
    md.append("| ext | files | size | what it is |")
    md.append("|---|---|---|---|")
    hint = dict(INTERESTING)
    for ext, cnt in by_ext.most_common(25):
        md.append("| `%s` | %d | %s | %s |" % (ext, cnt, human(by_ext_bytes[ext]), hint.get(ext, "")))
    md.append("")
    md.append("## By top-level folder")
    md.append("")
    md.append("| folder | files | size |")
    md.append("|---|---|---|")
    for top, cnt in by_top.most_common(25):
        md.append("| `%s` | %d | %s |" % (top, cnt, human(by_top_bytes[top])))
    md.append("")
    with open(os.path.join(OUT_DIR, "assets_summary.md"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(md))

    print("files  : %d" % len(rows))
    print("size   : %s" % human(total))
    print("written: %s" % os.path.join(OUT_DIR, "assets.tsv"))
    print("written: %s" % os.path.join(OUT_DIR, "assets_summary.md"))


if __name__ == "__main__":
    main()
