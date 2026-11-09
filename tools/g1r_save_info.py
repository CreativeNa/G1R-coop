#!/usr/bin/env python3
"""Report the structure of a Gothic 1 Remake save: preamble, both property blocks, and the compressed tail.

The save is not plain GVAS. Reading it bottom-up, in the order the facts were verified on G1R-009.sav:

  * magic "GSAV" (GVAS with the bytes swapped), 12 bytes of numbers, then the string "CustomPlayLoad";
  * property block 1 (18 tags, mostly save-slot flags) ending with "None";
  * two class paths "/Script/G1R.SaveGamePublicData", one int, then
  * property block 2 (17 tags: slot name, chapter id, map name, dates, difficulty) ending with "None";
  * a second "None", then a compressed payload whose compressor is named "Oodle".

The public block is what matters for testing (chapter, slot, settings) and it is readable and writable without any
decompression. The payload (story variables, NPC state) is Oodle-compressed; Oodle is statically linked into
G1R-Win64-Shipping.exe, so decompressing it needs a call made from inside the game process, not from this script.

    python tools/g1r_save_info.py <save.sav> [--tags]
"""
import importlib.util
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("reader", os.path.join(HERE, "g1r_save_reader.py"))
reader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reader)


def read_block(data, pos):
    r = reader.Reader(data, pos)
    tags = []
    while True:
        t = reader.read_tag(r)
        if t.get("end"):
            return tags, t["offset"], r.p
        tags.append(t)


def skip_class_paths(data, pos):
    """After a block come one or two FStrings with the class path, then an int, then the next block."""
    r = reader.Reader(data, pos)
    paths = []
    while True:
        save = r.p
        try:
            s = r.fstring()
        except Exception:
            r.p = save
            break
        if not s.startswith("/Script/"):
            r.p = save
            break
        paths.append(s)
        if len(paths) >= 2:
            break
    head = r.i32() if r.p + 4 <= len(data) else None
    return r.p, paths, head


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    path = sys.argv[1]
    show_tags = "--tags" in sys.argv
    data = open(path, "rb").read()

    print("file: %s (%d bytes)" % (path, len(data)))
    print("magic: %r" % data[:4].decode("ascii", "replace"))
    for off in (4, 8, 12):
        print("  preamble +%d: %d" % (off, struct.unpack_from("<i", data, off)[0]))
    marker = data.lower().find(b"customplay")
    print("  preamble string 'CustomPlayLoad' at 0x%X" % marker)

    # The first block is found by scoring candidate offsets: the preamble mixes numbers and strings, so there is no
    # fixed offset to start from.
    pos, _ = reader.find_tree_start(data)
    blocks = 0
    while pos < len(data) and blocks < 2:
        try:
            tags, none_at, end = read_block(data, pos)
        except Exception as e:
            print("block %d at 0x%X: stopped (%s)" % (blocks, pos, e))
            break
        print("block %d at 0x%X: %d tags, 'None' at 0x%X" % (blocks, pos, len(tags), none_at))
        if show_tags:
            for t in tags:
                extra = t.get("struct") or t.get("inner") or ""
                print("     %-32s %-16s size=%-6d %s" % (t["name"], t["type"], t.get("size", -1), extra))
        else:
            print("     " + ", ".join(t["name"] for t in tags[:8]) + (" …" if len(tags) > 8 else ""))
        pos, paths, head = skip_class_paths(data, end)
        blocks += 1

    tail = data.find(b"Oodle\x00")
    if tail > 0:
        size_field = struct.unpack_from("<i", data, tail - 12)[0] if tail >= 12 else 0
        print("compressed payload: 'Oodle' at 0x%X, header int at 0x%X = %d (0x%X)" % (tail, tail - 12, size_field, size_field))
        print("  the payload (story, NPC state) cannot be read without Oodle: it is statically linked into the game exe,")
        print("  so a decompression call has to be made from inside the running game, not from this script.")
    else:
        print("no Oodle marker found")
    print("sum: %d block(s) read, %d bytes left unread (compressed)" % (blocks, len(data) - pos))
    return 0


if __name__ == "__main__":
    sys.exit(main())
