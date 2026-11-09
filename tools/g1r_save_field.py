#!/usr/bin/env python3
"""Read or change a single integer field in a Gothic 1 Remake save, without parsing the whole file.

The full property-tree parser (tools/g1r_save_reader.py) still trips over nested structs, but a field can be found by its
tag: the 4-byte name length, the name, the 4-byte type length, the type, then index, size, one flag byte and the value.
That is enough to read a field and to overwrite it in place - an integer write changes no length, so nothing else in the
file has to be recalculated.

    python tools/g1r_save_field.py <save> --get m_ChapterID
    python tools/g1r_save_field.py <save> --set m_ChapterID 2 --out new.sav

Never edit the original: --set requires --out and refuses to write to the source file.
"""
import struct
import sys


def find_int_field(data, name):
    """Return (tag_start, value_offset, value) for an IntProperty with this name, or None."""
    needle = name.encode("ascii") + b"\x00"
    pos = -1
    found = []
    while True:
        pos = data.find(needle, pos + 1)
        if pos < 0:
            break
        start = pos - 4
        if start < 0:
            continue
        name_len = struct.unpack_from("<i", data, start)[0]
        if name_len != len(needle):
            continue
        after = pos + len(needle)
        type_len = struct.unpack_from("<i", data, after)[0]
        if type_len <= 0 or type_len > 64:
            continue
        typ = data[after + 4:after + 4 + type_len].rstrip(b"\x00")
        if typ != b"IntProperty":
            continue
        p = after + 4 + type_len
        index, size = struct.unpack_from("<ii", data, p)
        p += 8
        flag = data[p]
        p += 1
        if size != 4:
            continue
        value = struct.unpack_from("<i", data, p)[0]
        found.append((start, p, value, index, flag))
    return found


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    path = sys.argv[1]
    data = bytearray(open(path, "rb").read())
    mode = sys.argv[2]
    args = sys.argv[3:]

    if mode == "--get":
        name = args[0]
        hits = find_int_field(data, name)
        if not hits:
            print("no IntProperty named %s" % name)
            return 1
        for start, off, value, index, flag in hits:
            print("%s: tag 0x%X, value at 0x%X, index %d, flag %d, value %d" % (name, start, off, index, flag, value))
        return 0

    if mode == "--set":
        name = args[0]
        new = int(args[1])
        out = None
        if "--out" in args:
            out = args[args.index("--out") + 1]
        if not out:
            print("--set needs --out <file>; the source save is never modified")
            return 2
        hits = find_int_field(data, name)
        if not hits:
            print("no IntProperty named %s" % name)
            return 1
        if len(hits) > 1:
            print("%d occurrences of %s - refusing to guess which one to change" % (len(hits), name))
            for start, off, value, index, flag in hits:
                print("   tag 0x%X value %d" % (start, value))
            return 1
        start, off, old, index, flag = hits[0]
        print("%s: %d -> %d at 0x%X" % (name, old, new, off))
        struct.pack_into("<i", data, off, new)
        open(out, "wb").write(bytes(data))
        print("written: %s (%d bytes)" % (out, len(data)))
        return 0

    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main())
