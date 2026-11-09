#!/usr/bin/env python3
"""Build a .usmap mapping file from the reflection dump of Gothic 1 Remake.

UAssetAPI cannot deserialize unversioned properties without mappings, so every export comes out
as RawExport (base64). The dump written by the probe command "dumpall" has the class hierarchy,
the property offsets and - since the prop_ref extension - what every property points at. That is
exactly what a usmap needs.

Usage:  python tools\\dump_to_usmap.py [dump-file] [out.usmap]

Format (usmap version 0, from UAssetAPI's Usmap.cs / UsmapBinaryReader.cs):
    u16 magic 0x30C4, u8 version = 0
    i32 nameCount, then per name: u8 length, bytes
    i32 enumCount (0 here: enums are written as plain bytes)
    i32 schemaCount, then per schema:
        i32 nameIndex, i32 superIndex, u16 propCount, u16 serializedPropCount,
        then per property: u16 schemaIndex, u8 arraySize, i32 nameIndex, propertyData
    propertyData: u8 type, then type specific (struct name / inner type / enum)
"""
import os
import re
import struct
import sys
import collections

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DEFAULT_DUMP = os.path.join(ROOT, "native", "build", "dump", "classes_22752.txt")
DEFAULT_OUT = os.path.join(ROOT, "sdk", "G1R.usmap")

RE_CLASS = re.compile(r"^(class|struct) (\S+) : (\S+) \[(.+)\]\s*$")
RE_PROP = re.compile(r"^  prop (\S+) (.+?) @(\d+)/(\d+)(?: -> (.+?))?\s*$")

# UsmapPropertyType, in the order UAssetAPI declares them
T = {
    "ByteProperty": 0, "BoolProperty": 1, "IntProperty": 2, "FloatProperty": 3,
    "ObjectProperty": 4, "NameProperty": 5, "DelegateProperty": 6, "DoubleProperty": 7,
    "ArrayProperty": 8, "StructProperty": 9, "StrProperty": 10, "TextProperty": 11,
    "InterfaceProperty": 12, "MulticastDelegateProperty": 13, "MulticastInlineDelegateProperty": 13,
    "MulticastSparseDelegateProperty": 13, "WeakObjectProperty": 14, "LazyObjectProperty": 15,
    "AssetObjectProperty": 16, "SoftObjectProperty": 17, "SoftClassProperty": 17,
    "ClassProperty": 4, "UInt64Property": 18, "UInt32Property": 19, "UInt16Property": 20,
    "Int64Property": 21, "Int16Property": 22, "Int8Property": 23, "MapProperty": 24,
    "SetProperty": 25, "EnumProperty": 26, "FieldPathProperty": 27, "OptionalProperty": 28,
    "Utf8StrProperty": 29, "AnsiStrProperty": 30,
}
STRUCT, ARRAY, SET, MAP, ENUM, BYTE = 9, 8, 25, 24, 26, 0


def parse(path):
    classes = collections.OrderedDict()
    dup = 0
    cur = None
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            if not line.strip() or line.startswith("#"):
                continue
            m = RE_CLASS.match(line)
            if m:
                kind, name, sup, pkg = m.groups()
                if sup == "-":
                    sup = ""
                key = name
                if key in classes:
                    dup += 1
                    key = "%s#%d" % (name, dup)
                cur = {"kind": kind, "name": name, "key": key, "super": sup, "pkg": pkg, "props": []}
                classes[key] = cur
                continue
            m = RE_PROP.match(line)
            if m and cur is not None:
                ptype, pname, off, size, target = m.groups()
                cur["props"].append((ptype, pname, int(off), int(size), target or ""))
    return classes


class Names:
    def __init__(self):
        self.index = {"None": 0}
        self.list = ["None"]

    def add(self, s):
        if not s:
            return 0
        if s not in self.index:
            self.index[s] = len(self.list)
            self.list.append(s)
        return self.index[s]


def split_desc(s):
    """'ArrayProperty(StructProperty(FItem))' -> ('ArrayProperty', ['StructProperty(FItem)'])"""
    s = (s or "").strip()
    i = s.find("(")
    if i < 0 or not s.endswith(")"):
        return s, []
    kind, inner = s[:i], s[i + 1:-1]
    args, depth, cur = [], 0, ""
    for ch in inner:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if ch == "," and depth == 0:
            args.append(cur)
            cur = ""
        else:
            cur += ch
    args.append(cur)
    return kind, args


def leaf_name(desc):
    """'ArrayProperty(StructProperty(FItem))' -> 'FItem'  (the old, name-only behaviour)."""
    s = (desc or "").strip()
    while True:
        i = s.find("(")
        if i < 0 or not s.endswith(")"):
            return s
        kind, args = split_desc(s)
        s = (args[0] if args else "").strip()
        if not s:
            return kind


def safe_elem(desc):
    """UAssetAPI serialises TArray<bool> as a bit array; claiming BoolProperty for an element
    makes it desync and allocate wildly (measured: 24 GB, 50x slower). Byte is what it expects."""
    kind, _args = split_desc(desc)
    return "ByteProperty" if kind == "BoolProperty" else desc


def build(classes, names, precise=False):
    struct_names = {c["name"] for c in classes.values() if c["kind"] == "struct"}
    class_names = {c["name"] for c in classes.values() if c["kind"] == "class"}

    def simple(target, depth=0):
        if depth > 3 or not target:
            return bytes([BYTE])
        name = leaf_name(target)
        if name in struct_names:
            return bytes([STRUCT]) + struct.pack("<i", names.add(name))
        if name in class_names:
            return bytes([4])
        return bytes([BYTE])

    def propdata(desc, depth=0):
        """Turn the probe's description into usmap property data. The description now carries the
        element KIND, so arrays and maps no longer have to be guessed."""
        if not precise:
            return simple(desc, depth)
        if depth > 3 or not desc:
            return bytes([BYTE])
        kind, args = split_desc(desc)
        t = T.get(kind)
        if t is None:
            # an old-style dump only had a name: fall back to the guess
            if desc in struct_names:
                return bytes([STRUCT]) + struct.pack("<i", names.add(desc))
            if desc in class_names:
                return bytes([4])
            return bytes([BYTE])
        if t == STRUCT:
            return bytes([STRUCT]) + struct.pack("<i", names.add(args[0] if args else "None"))
        if t in (ARRAY, SET, 28):                     # optional is serialized like a container too
            return bytes([t]) + propdata(safe_elem(args[0] if args else ""), depth + 1)
        if t == ENUM:
            return bytes([ENUM]) + bytes([BYTE]) + struct.pack("<i", 0)   # enum name "None": parsing falls back to the inner byte
        if t == MAP:
            key = safe_elem(args[0]) if len(args) > 0 else ""
            val = safe_elem(args[1]) if len(args) > 1 else ""
            return bytes([MAP]) + propdata(key, depth + 1) + propdata(val, depth + 1)
        return bytes([t])

    out = []
    for c in classes.values():
        name_idx = names.add(c["name"])
        sup_idx = names.add(c["super"])
        props = [p for p in c["props"] if p[3] > 0]
        body = [struct.pack("<iiHH", name_idx, sup_idx, len(props), len(props))]
        for i, (ptype, pname, off, size, target) in enumerate(props):
            body.append(struct.pack("<HBi", i, 1, names.add(pname)))
            body.append(propdata(target))
        out.append(b"".join(body))
    return out


def main():
    dump = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_DUMP
    out_path = sys.argv[2] if len(sys.argv) > 2 and not sys.argv[2].startswith("--") else DEFAULT_OUT
    if not os.path.isfile(dump):
        sys.exit("dump not found: %s" % dump)
    classes = parse(dump)

    names = Names()
    for c in classes.values():                       # fill the name table first: indices must be final
        names.add(c["name"])
        names.add(c["super"])
        for ptype, pname, off, size, target in c["props"]:
            names.add(pname)
            if target and "(" not in target:          # plain names only; expressions are parsed by build()
                names.add(target)
    precise = "--precise" in sys.argv
    schemas = build(classes, names, precise)

    os.makedirs(os.path.dirname(out_path), exist_ok=True)

    payload = bytearray()
    payload += struct.pack("<i", len(names.list))
    for n in names.list:
        raw = n.encode("utf-8")
        if len(raw) > 255:
            raw = raw[:255]
        payload += bytes([len(raw)])
        payload += raw
    payload += struct.pack("<i", 0)                  # no enums
    payload += struct.pack("<i", len(schemas))
    for s in schemas:
        payload += s

    with open(out_path, "wb") as f:
        f.write(struct.pack("<H", 0x30C4))
        f.write(bytes([0]))                          # usmap version 0
        f.write(bytes([0]))                          # compression: none
        f.write(struct.pack("<I", len(payload)))     # compressed size
        f.write(struct.pack("<I", len(payload)))     # decompressed size
        f.write(payload)

    print("schemas : %d" % len(schemas))
    print("names   : %d" % len(names.list))
    print("written : %s (%.1f MB)" % (out_path, os.path.getsize(out_path) / 1048576.0))


if __name__ == "__main__":
    main()
