#!/usr/bin/env python3
"""Reader for Gothic 1 Remake saves (.sav).

G1R saves are NOT plain UE GVAS: the file starts with the magic GSAV (GVAS with the bytes swapped), 12 bytes of
numbers, then the string "CustomPlayLoad", and only then the usual Unreal property tree. uesave (and every GVAS tool
tried so far) stops at the end of the file because of that preamble.

This script finds where the property tree really starts and walks it, printing every property with its offset, type
and size. It never writes to the save.

    python tools/g1r_save_reader.py <save.sav> [--depth 2] [--json out.json]

The tag layout follows Unreal's FPropertyTag as written by FSaveGameArchive: FString name, FString type, int32 size,
int32 array index, then a type-specific header (struct name / enum name / bool value type), then `size` bytes of value.
A name of "None" ends a property list.
"""
import json
import struct
import sys

KNOWN_TYPES = {
    "IntProperty", "Int8Property", "Int16Property", "Int64Property", "UInt32Property",
    "FloatProperty", "DoubleProperty", "BoolProperty", "ByteProperty", "EnumProperty",
    "StrProperty", "NameProperty", "TextProperty", "ObjectProperty", "ClassProperty",
    "SoftObjectProperty", "StructProperty", "ArrayProperty", "MapProperty", "SetProperty",
    "DelegateProperty", "MulticastDelegateProperty", "InterfaceProperty", "FieldPathProperty",
}


class Reader:
    def __init__(self, data, pos=0):
        self.d = data
        self.p = pos

    def eof(self):
        return self.p >= len(self.d)

    def u8(self):
        v = self.d[self.p]
        self.p += 1
        return v

    def i32(self):
        v = struct.unpack_from("<i", self.d, self.p)[0]
        self.p += 4
        return v

    def u32(self):
        v = struct.unpack_from("<I", self.d, self.p)[0]
        self.p += 4
        return v

    def i64(self):
        v = struct.unpack_from("<q", self.d, self.p)[0]
        self.p += 8
        return v

    def skip(self, n):
        self.p += n

    def fstring(self):
        """UE FString: int32 length including the terminating NUL; negative means UTF-16."""
        n = self.i32()
        if n == 0:
            return ""
        if n > 0:
            if n > 1_000_000 or self.p + n > len(self.d):
                raise ValueError("bad string length %d at 0x%X" % (n, self.p - 4))
            raw = self.d[self.p:self.p + n]
            self.p += n
            return raw.split(b"\x00")[0].decode("utf-8", "replace")
        n = -n
        if n > 1_000_000 or self.p + n * 2 > len(self.d):
            raise ValueError("bad utf16 length %d at 0x%X" % (n, self.p - 4))
        raw = self.d[self.p:self.p + n * 2]
        self.p += n * 2
        return raw.decode("utf-16-le", "replace").split("\x00")[0]


def read_tag(r):
    start = r.p
    name = r.fstring()
    if name == "None":
        return {"name": "None", "end": True, "offset": start}
    typ = r.fstring()
    if typ not in KNOWN_TYPES:
        raise ValueError("unknown type %r at 0x%X" % (typ, start))
    # This format writes the array index BEFORE the size (a plain GVAS tag has them the other way round): with the
    # standard order every string property came out as size=0 index=<the string length> and the walk lost alignment.
    index = r.i32()
    # An array has no size field: right after the index comes the INNER TYPE string, then one spare int, then the element
    # count, then the elements, then one trailing byte (m_CompressedBitmap: idx=1, "ByteProperty\0" where a size would be).
    if typ == "ArrayProperty":
        inner = r.fstring()
        r.i32()
        count = r.i32()
        elem = 1 if inner in ("ByteProperty", "BoolProperty") else 4
        tag = {"name": name, "type": typ, "inner": inner, "count": count, "index": index, "offset": start,
               "value_offset": r.p, "size": count * elem}
        r.skip(count * elem)
        r.u8()
        return tag
    # A struct tag replaces the size field with its struct name: name, type, index, struct name ("DateTime"), int32 1,
    # struct path ("/Script/CoreUObject"), int32 0, size, value, trailing byte. Verified byte by byte on m_Date.
    if typ == "StructProperty":
        struct_name = r.fstring()
        r.i32()
        struct_path = r.fstring()
        r.i32()
        ssize = r.i32()
        tag = {"name": name, "type": typ, "struct": struct_name, "path": struct_path, "index": index,
               "size": ssize, "offset": start, "value_offset": r.p}
        r.skip(ssize)
        r.u8()
        return tag
    size = r.i32()
    # One more byte between the size and the value for plain types: for a bool it IS the value, for the rest it is a flag.
    flag = r.u8()
    tag = {"name": name, "type": typ, "size": size, "index": index, "flag": flag, "offset": start, "value_offset": None}
    if typ == "BoolProperty":
        tag["bool"] = flag
    elif typ == "ByteProperty" or typ == "EnumProperty":
        tag["enum"] = r.fstring()
    elif typ in ("ArrayProperty", "SetProperty"):
        tag["inner"] = r.fstring()
    elif typ == "MapProperty":
        tag["inner"] = r.fstring()
        tag["value_type"] = r.fstring()
    tag["value_offset"] = r.p
    if typ != "BoolProperty":
        r.skip(size)
    return tag


def walk(r, depth, max_depth, out):
    while not r.eof():
        tag = read_tag(r)
        if tag.get("end"):
            return True
        out.append(tag)
        if depth < max_depth and tag["type"] in ("StructProperty", "ArrayProperty", "MapProperty", "SetProperty"):
            sub = Reader(r.d, tag["value_offset"])
            try:
                sub_out = []
                walk(sub, depth + 1, max_depth, sub_out)
                if sub_out:
                    tag["children"] = sub_out
            except Exception:
                pass
    return False


def looks_like_name(s):
    if not s or len(s) > 64:
        return False
    return all(32 <= ord(c) < 127 for c in s)


def valid_chain(data, off):
    """Count believable tags from `off`. A real tree gives many tags with known types, sane sizes and printable names,
    and ends with a "None" terminator; a false start dies after one or two tags or produces absurd sizes."""
    r = Reader(data, off)
    score = 0
    ended = False
    try:
        while not r.eof():
            tag = read_tag(r)
            if tag.get("end"):
                ended = True
                break
            if not looks_like_name(tag["name"]):
                return score, ended
            if not (0 <= tag["size"] <= 1 << 20):
                return score - 5, ended
            if "struct" in tag and not looks_like_name(tag["struct"]):
                return score - 5, ended
            score += 1
            if score > 5000:
                break
    except Exception:
        return score, ended
    return score, ended


def find_tree_start(data):
    """Pick the offset with the best score: tag count, plus a bonus when the chain actually reaches the "None"
    terminator. The earlier version kept the first chain that did not throw, which locked onto a 3-tag fragment at 0xE6
    because the real payload struct threw on a type it did not know."""
    best_off, best_score, best = 0, -1, []
    for off in range(0, 512):
        score, ended = valid_chain(data, off)
        if ended:
            score += 50
        if score > best_score:
            r = Reader(data, off)
            tags = []
            try:
                walk(r, 0, 1, tags)
            except Exception:
                pass
            best_off, best_score, best = off, score, tags
    return best_off, best


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    path = sys.argv[1]
    max_depth = 2
    json_out = None
    args = sys.argv[2:]
    i = 0
    while i < len(args):
        if args[i] == "--depth":
            max_depth = int(args[i + 1]); i += 2
        elif args[i] == "--json":
            json_out = args[i + 1]; i += 2
        else:
            i += 1

    data = open(path, "rb").read()
    print("file: %s, %d bytes" % (path, len(data)))
    print("magic: %r" % data[:4].decode("ascii", "replace"))
    for off in (4, 8, 12):
        print("  header +%d: %d (0x%X)" % (off, struct.unpack_from("<i", data, off)[0], struct.unpack_from("<I", data, off)[0]))

    start, tags = find_tree_start(data)
    print("property tree starts at 0x%X (%d), %d top-level tags" % (start, start, len(tags)))
    for t in tags[:40]:
        extra = ""
        if "struct" in t:
            extra = " struct=%s" % t["struct"]
        print("  0x%06X  %-28s %-18s size=%-6d idx=%d%s" % (t["offset"], t["name"], t["type"], t["size"], t["index"], extra))
    if len(tags) > 40:
        print("  ... %d more" % (len(tags) - 40))
    if json_out:
        with open(json_out, "w", encoding="utf-8") as f:
            json.dump({"start": start, "tags": tags}, f, indent=1)
        print("written: %s" % json_out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
