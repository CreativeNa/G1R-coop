#!/usr/bin/env python3
"""Turn the reflection dump of Gothic 1 Remake into a usable SDK.

Reads  native/build/dump/classes_*.txt  (written in game by the probe command "dumpall")
Writes sdk/G1R_SDK.h     C++ structs with explicit offsets for /Script/G1R, /Script/Engine and their ancestors
       sdk/classes.tsv   every class/struct of the game (name, kind, super, package, counts)
       sdk/props.tsv     every property: class, type, name, offset, size
       sdk/functions.tsv every function: class, name
       sdk/README.md     what this is and how to use it

The dump has no parameter lists (a UFunction's params are only known at run time: use
"tools\\dev.ps1 probe \"fn <Class> <Function>\""), so functions appear by name only.

Usage:  python tools\\sdk_from_dump.py [dump-file]
"""
import os
import re
import sys
import collections

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DEFAULT_DUMP = os.path.join(ROOT, "native", "build", "dump", "classes_1996.txt")
OUT_DIR = os.path.join(ROOT, "sdk")

RE_CLASS = re.compile(r"^(class|struct) (\S+) : (\S+) \[(.+)\]\s*$")
RE_PROP = re.compile(r"^  prop (\S+) (.+?) @(\d+)/(\d+)(?: -> (.+?))?\s*$")
RE_FN = re.compile(r"^  fn (.+?)\s*$")

HEADER_PACKAGES = ("/Script/G1R", "/Script/Engine")

# property type -> C type when the size matches, otherwise a byte array of the reported size
PRIM = {
    ("BoolProperty", 1): "uint8_t",
    ("ByteProperty", 1): "uint8_t",
    ("EnumProperty", 1): "uint8_t",
    ("Int8Property", 1): "int8_t",
    ("Int16Property", 2): "int16_t",
    ("UInt16Property", 2): "uint16_t",
    ("IntProperty", 4): "int32_t",
    ("UInt32Property", 4): "uint32_t",
    ("Int64Property", 8): "int64_t",
    ("UInt64Property", 8): "uint64_t",
    ("FloatProperty", 4): "float",
    ("DoubleProperty", 8): "double",
}
PTR_PROP = {
    "ObjectProperty", "ClassProperty", "InterfaceProperty", "WeakObjectProperty",
    "LazyObjectProperty", "SoftObjectProperty", "SoftClassProperty",
}
CPP_KEYWORDS = {
    "alignas", "alignof", "and", "asm", "auto", "bool", "break", "case", "catch", "char",
    "class", "const", "constexpr", "continue", "default", "delete", "do", "double", "else",
    "enum", "explicit", "export", "extern", "false", "float", "for", "friend", "goto", "if",
    "inline", "int", "long", "mutable", "namespace", "new", "noexcept", "not", "nullptr",
    "operator", "or", "private", "protected", "public", "register", "return", "short",
    "signed", "sizeof", "static", "struct", "switch", "template", "this", "throw", "true",
    "try", "typedef", "typename", "union", "unsigned", "using", "virtual", "void",
    "volatile", "wchar_t", "while", "xor",
}


def parse(path):
    """Returns (classes, order, dupes). classes is keyed by a unique key; 'name' is the real name."""
    classes = collections.OrderedDict()
    by_name = {}
    dupes = 0
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
                if key in classes:            # the same class name in two packages: keep both, key the second
                    dupes += 1
                    key = "%s#%d" % (name, dupes)
                else:
                    by_name[name] = key
                cur = {"kind": kind, "name": name, "key": key, "super": sup, "pkg": pkg,
                       "props": [], "fns": [], "dup": key != name}
                classes[key] = cur
                continue
            m = RE_PROP.match(line)
            if m and cur is not None:
                ptype, pname, off, size, target = m.groups()
                cur["props"].append((ptype, pname, int(off), int(size), target or ""))
                continue
            m = RE_FN.match(line)
            if m and cur is not None:
                cur["fns"].append(m.group(1))
                continue
            # an unknown line inside a class is ignored; the properties that follow still belong to it
    return classes, by_name, dupes


def topo_order(classes, by_name):
    """every class after its parent; deterministic and cycle safe."""
    out, done, stack = [], set(), set()

    def visit(key):
        if key in done or key not in classes:
            return
        if key in stack:
            return
        stack.add(key)
        sup = classes[key]["super"]
        if sup in by_name:
            visit(by_name[sup])
        stack.discard(key)
        done.add(key)
        out.append(key)

    for key in classes:
        visit(key)
    return out


def ident(name):
    """property/class names are friendly names ('Display Name'): make them C identifiers."""
    out = "".join(ch if (ch.isalnum() or ch == "_") else "_" for ch in name)
    out = out.strip("_") or "field"
    if out[0].isdigit():
        out = "_" + out
    if out in CPP_KEYWORDS:
        out += "_"
    return out


def ctype(ptype, size):
    ct = PRIM.get((ptype, size))
    if ct:
        return ct
    if ptype in PTR_PROP and size == 8:
        return "void*"
    return None


def emit_header(classes, by_name, order, path):
    keep = set()

    def add_chain(key):
        n = key
        seen = set()
        while n in classes and n not in seen:
            seen.add(n)
            keep.add(n)
            sup = classes[n]["super"]
            n = by_name.get(sup) if sup else None

    for key, c in classes.items():
        if c["pkg"] in HEADER_PACKAGES and not c["dup"]:
            add_chain(key)

    em = [k for k in order if k in keep]
    end_of = {}

    def class_end(key):
        if key in end_of:
            return end_of[key]
        c = classes.get(key)
        if not c:
            return 0
        end = class_end(by_name.get(c["super"])) if c["super"] in by_name else 0
        for _t, _nm, off, size, _tg in c["props"]:
            if size > 0 and off + size > end:
                end = off + size
        end_of[key] = end
        return end

    lines = []
    w = lines.append
    w("// Gothic 1 Remake reflection SDK - generated by tools/sdk_from_dump.py, do not edit.")
    w("// Source: the game's own UClass/UProperty reflection data, read from a live process.")
    w("// Every member sits at the exact offset the engine reported; the header is pack(1) so the")
    w("// compiler cannot insert padding of its own. Offsets are relative to the UObject base")
    w("// (vtable pointer at +0), the same base the coop DLL and ProcessEvent use.")
    w("//")
    w("// What this header does NOT give you:")
    w("//   * function parameters - a UFunction's layout is only known at run time:")
    w("//         tools\\dev.ps1 probe \"fn <Class> <Function>\"")
    w("//   * the real size of a class (the dump has no sizeof): the end of the last member is a lower bound")
    w("//   * the bit index of boolean flags that share one byte - see sdk/props.tsv for all of them")
    w("//   * the class a pointer points to (the dump has the property type, not its target class)")
    w("#pragma once")
    w("#include <cstdint>")
    w("#pragma pack(push, 1)")
    w("")
    for key in em:
        c = classes[key]
        cname = ident(c["name"])
        sup = by_name.get(c["super"]) if c["super"] else None
        sup_name = ident(classes[sup]["name"]) if sup in classes else None
        w("// %s %s : %s [%s]  %d props, %d functions" % (c["kind"], c["name"], c["super"] or "-", c["pkg"], len(c["props"]), len(c["fns"])))
        w("struct %s%s {" % (cname, (" : " + sup_name) if sup_name else ""))
        cur = class_end(sup) if sup in classes else 0
        used = set()
        by_off = collections.defaultdict(list)
        for p in c["props"]:
            by_off[p[2]].append(p)
        for off in sorted(by_off):
            group = by_off[off]
            size = max(g[3] for g in group)
            if size <= 0:
                w("    // @%d zero-sized: %s" % (off, ", ".join(g[1] for g in group)))
                continue
            if off > cur:
                w("    uint8_t _pad_%d[%d];" % (cur, off - cur))
                cur = off
            elif off < cur:
                w("    // @%d overlaps the previous member (bitfield or union): %s" % (off, ", ".join(g[1] for g in group)))
                continue
            if len(group) == 1:
                ptype, pname, _o, psize, ptarget = group[0]
                nm = ident(pname)
                base_nm, k = nm, 1
                while nm in used:
                    nm = "%s_%d" % (base_nm, k)
                    k += 1
                used.add(nm)
                ct = ctype(ptype, psize)
                w("    // @%d %s%s" % (off, ptype, (" -> " + ptarget) if ptarget else ""))
                if ct:
                    w("    %s %s;" % (ct, nm))
                else:
                    w("    uint8_t %s[%d];" % (nm, psize))
            else:
                w("    // @%d %d members share this offset (bool flags / union): %s" % (off, len(group), ", ".join(g[1] for g in group)))
                nm = "_at_%d" % off
                while nm in used:
                    nm += "_"
                used.add(nm)
                w("    uint8_t %s[%d];" % (nm, size))
            cur = off + size
        w("};")
        w("")
    w("#pragma pack(pop)")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    return len(em)


def write_tsv(classes, path):
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("name\tkind\tsuper\tpackage\tprops\tfunctions\n")
        for c in classes.values():
            f.write("%s\t%s\t%s\t%s\t%d\t%d\n" % (c["name"], c["kind"], c["super"], c["pkg"], len(c["props"]), len(c["fns"])))


def write_props(classes, path):
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("class\ttype\tname\toffset\tsize\ttarget\n")
        for c in classes.values():
            for ptype, pname, off, size, target in c["props"]:
                f.write("%s\t%s\t%s\t%d\t%d\t%s\n" % (c["name"], ptype, pname, off, size, target))


def write_fns(classes, path):
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("class\tfunction\n")
        for c in classes.values():
            for fn in c["fns"]:
                f.write("%s\t%s\n" % (c["name"], fn))


README = """# SDK from the game's own reflection data

Generated by `tools/sdk_from_dump.py` from `native/build/dump/classes_*.txt`, which the probe
command `dumpall` writes while the game runs. Nothing here was obtained by guessing: every
name, offset and size is what the engine itself reports.

## Files

| File | What |
|---|---|
| `G1R_SDK.h` | C++ structs with exact member offsets for `/Script/G1R`, `/Script/Engine` and their ancestors |
| `classes.tsv` | every class/struct in the game: `name kind super package props functions` |
| `props.tsv` | every property: `class type name offset size` |
| `functions.tsv` | every function: `class function` |

## How to use it

* **Finding a field in a live process / IDA / Ghidra**: look it up in `props.tsv`, the offset is
  from the `UObject` base (vtable at +0).
* **Reading memory in the coop DLL**: `find_prop_offset(class, name)` already does this at run
  time; the header is for offline analysis and for code that wants the offset compiled in.
* **Function parameters**: the dump has no parameter lists. Ask the running game:
  `tools\\dev.ps1 probe "fn GothicGASLibrary ApplyDamageTo"` prints
  `Name@offset/size` for every parameter - that is exactly what `call_fn` needs.

## Known limits

* No `sizeof`: only the offset of the last member (a lower bound).
* Boolean flags sharing one byte are grouped: the dump has the byte offset, not the bit index.
* Pointer properties do not say which class they point to.
* 34 class names occur twice (Blueprint-generated duplicates). In the TSV both appear; in the
  header only the first, because C++ would not allow two types with one name.

## Regenerate

```
python tools\\sdk_from_dump.py [path\\to\\classes_<pid>.txt]
```
"""


def main():
    dump = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_DUMP
    if not os.path.isfile(dump):
        sys.exit("dump not found: %s" % dump)
    os.makedirs(OUT_DIR, exist_ok=True)
    classes, by_name, dupes = parse(dump)
    order = topo_order(classes, by_name)
    n_hdr = emit_header(classes, by_name, order, os.path.join(OUT_DIR, "G1R_SDK.h"))
    write_tsv(classes, os.path.join(OUT_DIR, "classes.tsv"))
    write_props(classes, os.path.join(OUT_DIR, "props.tsv"))
    write_fns(classes, os.path.join(OUT_DIR, "functions.tsv"))
    with open(os.path.join(OUT_DIR, "README.md"), "w", encoding="utf-8", newline="\n") as f:
        f.write(README)
    nprops = sum(len(c["props"]) for c in classes.values())
    nfns = sum(len(c["fns"]) for c in classes.values())
    print("classes/structs parsed : %d (duplicate names kept apart: %d)" % (len(classes), dupes))
    print("properties             : %d" % nprops)
    print("functions              : %d" % nfns)
    print("structs in G1R_SDK.h   : %d" % n_hdr)
    print("written to             : %s" % OUT_DIR)


if __name__ == "__main__":
    main()
