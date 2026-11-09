#!/usr/bin/env python3
"""Harvest UFunction parameter layouts from the live game.

The reflection dump has function NAMES but not their parameters - a UFunction's layout only
exists in a running process. The probe module can answer "fn <Class> <Function>" with
"Class:Fn(Name@off/size ...)", which is exactly what CoreAPI.call_fn needs. This script asks
for thousands of them in batches: one probe_cmd.txt can carry many commands.

Requires: the game running with the coop core + probe module injected.

Usage:  python tools\\harvest_signatures.py [--pid N] [--batch 250] [--limit N]

Writes sdk/signatures.tsv  (class, function, nparams, out, params)
"""
import os
import re
import sys
import time
import glob

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SDK = os.path.join(ROOT, "sdk")
BUILD = os.path.join(ROOT, "native", "build")

PACKAGES = ("/Script/G1R", "/Script/THQGDS", "/Script/AlkimiaStoryFileImport", "/Script/Angelscript")
SKIP_PREFIX = ("GVL_", "Default__", "SKEL_", "REINST_")

RE_SIG = re.compile(r"^(\S+):(\S+)\((.*)\)\s*$")
RE_PARAM = re.compile(r"(\w+)@(\d+)/(\d+)(\(out\))?")


def find_pid(explicit):
    if explicit:
        return explicit
    candidates = []
    for path in glob.glob(os.path.join(BUILD, "probe_out_*.txt")):
        m = re.search(r"probe_out_(\d+)\.txt$", path)
        if m:
            candidates.append((os.path.getmtime(path), int(m.group(1))))
    if not candidates:
        sys.exit("no probe_out_*.txt in native/build - is the game running with the probe module?")
    candidates.sort(reverse=True)
    return candidates[0][1]


def load_targets(limit):
    classes = {}
    with open(os.path.join(SDK, "classes.tsv"), "r", encoding="utf-8") as f:
        next(f)
        for line in f:
            name, _kind, _sup, pkg, _p, _fn = line.rstrip("\n").split("\t")
            classes[name] = pkg
    targets = []
    with open(os.path.join(SDK, "functions.tsv"), "r", encoding="utf-8") as f:
        next(f)
        for line in f:
            cls, fn = line.rstrip("\n").split("\t")
            if classes.get(cls) not in PACKAGES:
                continue
            if cls.startswith(SKIP_PREFIX):
                continue
            targets.append((cls, fn))
    targets.sort()
    if limit:
        targets = targets[:limit]
    return targets


def run_batch(pid, batch, tag):
    cmd_path = os.path.join(BUILD, "probe_cmd.txt")
    out_path = os.path.join(BUILD, "probe_out_%d.txt" % pid)
    body = "#%s\n" % tag + "\n".join("fn %s %s" % (c, f) for c, f in batch) + "\n"
    with open(cmd_path, "w", encoding="ascii", errors="replace", newline="\n") as f:
        f.write(body)

    deadline = time.time() + 20
    while time.time() < deadline:
        time.sleep(0.2)
        try:
            with open(out_path, "r", encoding="utf-8", errors="replace") as f:
                text = f.read()
        except OSError:
            continue
        if text.startswith("#" + tag):
            return text
    return ""


def parse(text, batch):
    got = {}
    for line in text.splitlines():
        m = RE_SIG.match(line.strip())
        if not m:
            continue
        cls, fn, params = m.groups()
        if params.startswith("function "):     # "not found" style answers
            continue
        plist = RE_PARAM.findall(params)
        got[(cls, fn)] = (len(plist), "1" if "(out)" in params else "0", params)
    rows = []
    for cls, fn in batch:
        if (cls, fn) in got:
            n, has_out, params = got[(cls, fn)]
            rows.append((cls, fn, str(n), has_out, params))
        else:
            rows.append((cls, fn, "", "", ""))
    return rows


def main():
    pid = None
    batch_size = 250
    limit = 0
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--pid":
            pid = int(args[i + 1]); i += 2
        elif args[i] == "--batch":
            batch_size = int(args[i + 1]); i += 2
        elif args[i] == "--limit":
            limit = int(args[i + 1]); i += 2
        else:
            i += 1
    pid = find_pid(pid)
    print("game pid %d" % pid)

    targets = load_targets(limit)
    print("functions to ask: %d" % len(targets))

    os.makedirs(SDK, exist_ok=True)
    out_path = os.path.join(SDK, "signatures.tsv")
    done = 0
    found = 0
    with open(out_path, "w", encoding="utf-8", newline="\n") as out:
        out.write("class\tfunction\tnparams\tout\tparams\n")
        for start in range(0, len(targets), batch_size):
            batch = targets[start:start + batch_size]
            tag = "sig%d" % start
            text = run_batch(pid, batch, tag)
            if not text:
                print("batch %d: no answer, skipped" % start)
                continue
            rows = parse(text, batch)
            for r in rows:
                out.write("\t".join(r) + "\n")
                if r[2]:
                    found += 1
            out.flush()
            done += len(batch)
            print("%d/%d asked, %d with a signature" % (done, len(targets), found))

    print("written: %s (%d of %d resolved)" % (out_path, found, len(targets)))


if __name__ == "__main__":
    main()
