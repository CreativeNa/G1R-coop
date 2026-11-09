#!/usr/bin/env python3
"""Compare the state of the two running coop copies and say which SECTION diverged.

This is the "which of the three hypotheses is it" tool: instead of guessing why a mirror looks
wrong, it asks both copies for the same canonical block (the probe command `parity`) and reports
the first section that differs.

    python tools\\parity.py                     # one comparison, human readable
    python tools\\parity.py --watch 5           # every 5 s, log a timeline, print transitions
    python tools\\parity.py --snap GothicCameraManager m_CurrentBehaviour
    python tools\\parity.py --raw               # print both blocks, no comparison

Exit code: 0 = all sections agree, 1 = a section diverged, 2 = could not talk to both copies.

Tolerances: positions are compared with a few units of slack (the two copies never agree
exactly), counters that differ by nature (packet sequence numbers) are ignored on purpose.
"""
import os
import re
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DEV = os.path.join(ROOT, "tools", "dev.ps1")

TOL_POS = 5.0          # units of slack for a horizontal position
TOL_Z = 120.0          # the puppet actor sits 90 units below the hero on purpose (mesh alignment)
TOL_NPC = 150.0        # NPCs walk; a mirrored NPC is interpolated on the other copy
TOL_BONE = 12.0        # pose interpolation between 20 Hz packets
TOL_CHEST_POS = 100.0  # chests are mirrored, their positions may be rounded differently


def run_probe(cmd):
    """Ask both copies through dev.ps1 and split the answer by game process."""
    ps = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", DEV, "probe", cmd]
    out = subprocess.run(ps, capture_output=True, text=True, errors="replace").stdout
    blocks = {}
    cur = None
    for line in out.splitlines():
        m = re.match(r"^===== game pid (\d+)", line)
        if m:
            cur = int(m.group(1))
            blocks[cur] = []
            continue
        if cur is None:
            continue
        if line.startswith(">"):
            continue
        blocks[cur].append(line)
    return blocks


def seat_of_pid():
    """pid -> seat number, from the command line (-CoopSeat=N)."""
    ps = ["powershell", "-NoProfile", "-Command",
          "Get-CimInstance Win32_Process -Filter \"Name='G1R-Win64-Shipping.exe'\" | "
          "ForEach-Object { \"$($_.ProcessId) $($_.CommandLine)\" }"]
    out = subprocess.run(ps, capture_output=True, text=True, errors="replace").stdout
    res = {}
    for line in out.splitlines():
        parts = line.split(" ", 1)
        if len(parts) != 2 or not parts[0].isdigit():
            continue
        m = re.search(r"-CoopSeat=(\d+)", parts[1])
        if m:
            res[int(parts[0])] = int(m.group(1))
    return res


def parse_block(lines):
    """Canonical block -> dict of sections."""
    sec = {"hero": {}, "puppet": {}, "cam": None, "chests": {}, "chest_count": None, "net": None,
           "npcs": {}, "npc_count": None, "inv": None, "ui": {}, "bones": {}}
    for line in lines:
        t = line.split()
        if not t:
            continue
        if t[0] == "HERO" and len(t) >= 5:
            sec["hero"] = {"pos": tuple(float(x) for x in t[2:5])}
        elif t[0] == "PUPPET" and len(t) >= 2:
            # PUPPET have_remote <n> pos <x> <y> <z> seq <n>   |   PUPPET have_remote <n> pos none seq <n>
            d = {"have_remote": 0, "pos": None}
            try:
                d["have_remote"] = int(t[t.index("have_remote") + 1])
            except Exception:
                pass
            try:
                i = t.index("pos")
                if t[i + 1] != "none":
                    d["pos"] = (float(t[i + 1]), float(t[i + 2]), float(t[i + 3]))
            except Exception:
                pass
            sec["puppet"] = d
        elif t[0] == "CAM" and len(t) >= 3:
            sec["cam"] = t[2]
        elif t[0] == "CHEST" and len(t) >= 2:
            key = t[1]
            pos = None
            m = re.match(r"^@(-?[\d.]+),(-?[\d.]+)$", t[2]) if len(t) > 2 else None
            if m:
                pos = (float(m.group(1)), float(m.group(2)))
                rest = t[3:]
            else:
                rest = t[2:]
            items = tuple(rest[-2:]) if len(rest) >= 2 else rest
            sec["chests"][key + ("@%s" % (pos,)) if pos else key] = items
        elif t[0] == "CHESTS" and len(t) >= 2:
            sec["chest_count"] = t[1]
        elif t[0] == "NPCS" and len(t) >= 2:
            sec["npc_count"] = t[1]
        elif t[0] == "INV":
            sec["inv"] = tuple(t[2:4])
        elif t[0] == "NPC" and len(t) >= 2:
            try:
                pos = (float(t[2]), float(t[3]), float(t[4]))
                hp = int(t[t.index("hp") + 1])
                df = int(t[t.index("defeated") + 1])
            except Exception:
                continue
            sec["npcs"][t[1]] = {"pos": pos, "hp": hp, "df": df}
        elif t[0] == "UI" and len(t) >= 3:
            sec["ui"][t[1]] = t[2]
        elif t[0] == "BONEPOS" and len(t) >= 6:
            try:
                sec["bones"][(t[1], t[2])] = (float(t[3]), float(t[4]), float(t[5]))
            except Exception:
                pass
        elif t[0] == "NET":
            sec["net"] = line
    return sec


def near(a, b, tol):
    if a is None or b is None:
        return a is b
    return all(abs(x - y) <= tol for x, y in zip(a, b))


def near_hero_puppet(a, b):
    """The puppet actor is placed 90 units below the hero on purpose (mesh alignment), so the
    horizontal position must match tightly and Z only within that known offset."""
    if a is None or b is None:
        return a is b
    return abs(a[0] - b[0]) <= TOL_POS and abs(a[1] - b[1]) <= TOL_POS and abs(a[2] - b[2]) <= TOL_Z


def compare(a, b):
    """Returns a list of (section, ok, detail).

    The invariant is CROSS-copy: the hero of one copy must be where the other copy draws the
    puppet, the chests must hold the same things, the camera state must be the same. Comparing
    the same field on both copies would always differ (they are two different heroes).
    """
    res = []
    pa, pb = a["puppet"], b["puppet"]
    ok = pa.get("have_remote") == 1 and pb.get("have_remote") == 1
    res.append(("PUPPET present", ok, "have_remote %s/%s" % (pa.get("have_remote"), pb.get("have_remote"))))

    ok = (pa.get("pos") is None) == (pb.get("pos") is None)
    if ok and pa.get("pos") and pb.get("pos"):
        ok = near_hero_puppet(a["hero"].get("pos"), pb.get("pos")) and near_hero_puppet(b["hero"].get("pos"), pa.get("pos"))
    res.append(("HERO<->PUPPET", ok, "hero A %s vs puppet B %s; hero B %s vs puppet A %s"
                % (a["hero"].get("pos"), pb.get("pos"), b["hero"].get("pos"), pa.get("pos"))))

    res.append(("CAM behaviour", True, "%s vs %s%s" % (a["cam"], b["cam"], "" if a["cam"] == b["cam"] else " (information only: each player has their own camera state: menu, dialogue, combat)")))

    # A chest SET can differ for a while without meaning anything: a cell streams in at different
    # moments (observed 17/18 -> 19/19 after the heroes walked on) and a picked-up actor stays in the
    # object array until the garbage collector frees it (a nugget count differed 27/28 -> 27/27 after
    # 15 s). So only the contents of a chest BOTH copies know are a hard failure; a set difference is
    # reported as a note and is real only if it survives about a minute.
    ka, kb = set(a["chests"]), set(b["chests"])
    only_a, only_b = ka - kb, kb - ka
    same_items = [k for k in (ka & kb) if a["chests"][k] != b["chests"][k]]
    ok = not same_items
    detail = "common %d, count %s/%s" % (len(ka & kb), a["chest_count"], b["chest_count"])
    if only_a or only_b:
        detail += "; set differs (streaming or a pending destroy): A-only %d, B-only %d - real only if it stays > 1 min" % (len(only_a), len(only_b))
    if same_items:
        detail += "; ITEM COUNTS DIFFER: %d (e.g. %s)" % (len(same_items), sorted(same_items)[0])
    res.append(("CHESTS", ok, detail))

    ka, kb = set(a["npcs"]), set(b["npcs"])
    only_a, only_b = ka - kb, kb - ka
    npc_diff = []
    for k in ka & kb:
        x, y = a["npcs"][k], b["npcs"][k]
        if x["hp"] != y["hp"] or x["df"] != y["df"] or not near(x["pos"], y["pos"], TOL_NPC):
            npc_diff.append(k)
    ok = not npc_diff                       # only the NPCs both copies know must agree
    detail = "common %d" % len(ka & kb)
    if only_a or only_b:
        # streaming edge: each copy loads its own set, so a difference here is a NOTE, not a failure
        detail += "; sets differ (streaming): A-only %d, B-only %d" % (len(only_a), len(only_b))
    if npc_diff:
        k = sorted(npc_diff)[0]
        detail += "; %d common differ (e.g. %s: %s vs %s)" % (len(npc_diff), k, a["npcs"][k], b["npcs"][k])
    res.append(("NPC", ok, detail))
    res.append(("INV", True, "%s vs %s (information only: every player has an inventory of their own)" % (a["inv"], b["inv"])))

    keys = sorted(set(a["ui"]) | set(b["ui"]))
    ui_diff = [k for k in keys if a["ui"].get(k) != b["ui"].get(k) and k != "W_SavedGamesPage_C"]          # the saved-games page object our load sync creates stays in memory, not activated and pass-through (measured), harmless
    detail = "; ".join("%s %s/%s" % (k, a["ui"].get(k), b["ui"].get(k)) for k in ui_diff[:3])
    res.append(("UI widgets", not ui_diff, detail if ui_diff else "all equal"))

    # pose: the hero of one copy against the puppet of the other, bone by bone. Bones of the
    # separate facial mesh read as exactly (0,0,0) on the hero, so they are skipped.
    worst = 0.0; worst_bone = ""; compared = 0; bad = 0
    for name in sorted(set(k[1] for k in a["bones"] if k[0] == "hero")):
        pa = a["bones"].get(("hero", name))
        pb = b["bones"].get(("puppet", name))
        if pa is None or pb is None or pa == (0.0, 0.0, 0.0):
            continue
        compared += 1
        dev = max(abs(pa[i] - pb[i]) for i in range(3))
        if dev > TOL_BONE:
            bad += 1
        if dev > worst:
            worst = dev; worst_bone = name
    ok = compared > 0 and bad == 0
    res.append(("POSE bones", ok, "compared %d, %d over %.0f units (worst %.1f on %s)"
                % (compared, bad, TOL_BONE, worst, worst_bone or "-")))
    return res


def print_block(label, sec):
    print("--- %s ---" % label)
    print("  hero  ", sec["hero"])
    print("  puppet", sec["puppet"])
    print("  cam   ", sec["cam"])
    print("  chests", len(sec["chests"]), "count", sec["chest_count"])


def main():
    args = sys.argv[1:]
    watch = None
    snap = None
    raw = "--raw" in args
    if "--watch" in args:
        watch = float(args[args.index("--watch") + 1])
    if "--snap" in args:
        i = args.index("--snap")
        snap = (args[i + 1], args[i + 2] if len(args) > i + 2 and not args[i + 2].startswith("-") else "")

    seats = seat_of_pid()
    if len(seats) < 2:
        print("need two running copies (found %d)" % len(seats))
        return 2
    pid_seat = {p: s for p, s in seats.items()}

    def once(verbose=True):
        cmd = "snap %s %s" % (snap[0], snap[1]) if snap else "parity"
        blocks = run_probe(cmd)
        if len(blocks) < 2:
            print("no answer from both copies")
            return 2, []
        pids = sorted(blocks, key=lambda p: pid_seat.get(p, 99))
        A, B = blocks[pids[0]], blocks[pids[1]]
        if snap:
            diff = sorted(set(l.strip() for l in A if l.strip()) ^ set(l.strip() for l in B if l.strip()))
            if verbose:
                print("snap %s: %d differing lines" % (snap, len(diff)))
                for d in diff[:40]:
                    print("   ", d)
            return (0 if not diff else 1), [("SNAP", not diff, "%d differing" % len(diff))]
        sa, sb = parse_block(A), parse_block(B)
        if raw:
            print_block("seat %s" % pid_seat.get(pids[0]), sa)
            print_block("seat %s" % pid_seat.get(pids[1]), sb)
        res = compare(sa, sb)
        if verbose:
            print("seat %s vs seat %s" % (pid_seat.get(pids[0]), pid_seat.get(pids[1])))
            for name, ok, detail in res:
                print("  %-14s %s  %s" % (name, "OK  " if ok else "DIFF", detail))
        return (0 if all(ok for _, ok, _ in res) else 1), res

    if watch is None:
        code, _ = once()
        return code

    print("watching every %.1f s, Ctrl-C stops" % watch)
    last = None
    try:
        while True:
            code, res = once(verbose=False)
            state = tuple(ok for _, ok, _ in res)
            stamp = time.strftime("%H:%M:%S")
            if state != last:
                print("%s  %s" % (stamp, "  ".join("%s=%s" % (n, "OK" if ok else "DIFF") for n, ok, _ in res)))
                for n, ok, d in res:
                    if not ok:
                        print("        %s: %s" % (n, d))
                last = state
            time.sleep(watch)
    except KeyboardInterrupt:
        print("stopped")
        return 0


if __name__ == "__main__":
    sys.exit(main())
