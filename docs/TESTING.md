> **Two PCs?** These suites read the local log only, so they need both copies on one machine. For a live online session
> (host on one PC, guest on another) use `tools/cooptest.ps1` - see [`ONLINE_TESTING.md`](ONLINE_TESTING.md).

# Testing the coop mod

The point of this file is to stop the loop "change code → play → guess". Every change can be
checked by one command against two running copies, and every failure names the layer where the two
copies disagree.

---

## The one command

```powershell
.\tools\check.ps1            # parity gate + npc_health scenario
.\tools\check.ps1 -Quick     # parity gate only (fast, read-only)
.\tools\check.ps1 -Soak 60   # plus a 60 s soak
```

Exit code 0 = PASS. A report per block lands in `docs\reports\`.

It needs **two running copies** (`tools\start_coop_11.ps1`). The gate changes nothing; the
scenarios do change state and restore it.

---

## What is checked, and what it means

| Check | Meaning when it fails |
|---|---|
| two copies running | one process died |
| state parity | see the sections below — the detail names the first divergence |
| fps >= 5 | something is badly stuck (background windows are throttled, 8–15 is normal for an unfocused copy) |
| no new unknown exceptions | our code threw something not seen before; `K2_AttachToComponent` is a known, caught AV and is filtered |
| corpse pose mirrored | a copy bone-drives a defeated NPC and the other is not applying it |

### Sections of the state parity

| Section | Invariant | Tolerances |
|---|---|---|
| PUPPET present | both copies see the friend (`have_remote 1`) | — |
| HERO↔PUPPET | **cross-copy**: hero of A is where B draws its puppet, and vice versa | 5 units horizontal, 120 vertical (the puppet actor sits 90 below the hero on purpose) |
| CAM behaviour | `m_CurrentBehaviour` (information only: menu, dialogue, combat give each player their own state; 2 is the normal value) | not a failure |
| CHESTS | common chests hold the same items; a **set** difference is a note (streaming / pending destroy) | position 100 units |
| NPC | same NPCs, same health and defeated flag | 150 units (NPCs walk); **set differences are a note, not a failure** — that is the streaming edge |
| INV | hero inventory counts (information only: every player has their own inventory) | not a failure |
| UI widgets | GameOver/Pause/Conversation/MainMenu visibility equal | exact |
| POSE bones | hero bones of A match puppet bones of B | 12 units; facial bones are skipped (separate mesh, read as 0 on the hero) |

**The single most important rule:** compare ACROSS copies, not the same field on both. Each copy
has its own hero; equal hero positions would mean a bug, not health.

**Run the gate while both heroes stand still.** While one of them walks, HERO↔PUPPET (the puppet is
interpolated, so it lags by ~100 units) and CAM behaviour can differ legitimately, and CHESTS/items
can differ for a few seconds while a cell streams in or a destroyed actor waits for the garbage
collector. Measured: chests 17/18 → 19/19 after the heroes walked on; ore nuggets 27/28 → 27/27 after 15 s and 26/27 → 26/26 after 30 s. The copy that PICKED an
item keeps the actor in the object array until the garbage collector frees it - up to ~30 s - while
the other copy has already destroyed it, so never compare world-actor counts right after a pickup. A difference that persists for a minute is real, anything shorter is not.

---

## When a check fails

1. Read the section name — that is the layer: positions → movement/mirror, NPC → ownership or
   replication, CHESTS/INV → the story module, UI → the widget/event path, POSE → the pose module.
2. For a specific object, compare it directly:
   ```powershell
   python tools\parity.py --snap Interactive_Chest_C "SomeProperty"
   python tools\parity.py --watch 5        # timeline: prints every OK→DIFF transition
   ```
3. `probe` is the microscope: `findall <class> <name>`, `members <object>`, `get <object> <prop>`,
   `npcinfo <name>`, `chestlist`, `contdump <chest>`, `posehash`, `parity`, `snap`.

---

## Adding a check

**A new state field** → add a section to the `parity` command in `native\probe_module.c`, parse and
compare it in `tools\parity.py`. Print a stable key (never a pointer, never the numeric suffix of a
runtime name) and a tolerance that reflects how the value moves.

**A new behaviour** → add a scenario to `tools\scenarios.ps1`: drive the game through `probe`,
then assert. Rules that saved time:

* write to the **owner** of an object, not the mirror — the owner is the one that simulates it
  (default: seat 0; the truth is in the log line `N seat X: ... simulating N`);
* restore what you touched, so the next run starts clean;
* never assume "the nearest hero" is the owner — the module uses 600 units of hysteresis.

---

## Known noise (do not "fix" these)

* NPC sets differ at the edge of streaming — each copy loads its own surroundings.
* fps of an unfocused window is throttled; measure with focus if you need a real number.
* `EXCEPTION 0xc0000005 in ProcessEvent(K2_AttachToComponent)` on both copies: a known, caught
  access violation, filtered as `known` in the gate.
* Bones of the facial mesh read as (0,0,0) on the hero — the face is a separate skinned mesh.

---

## What is still not covered

* dialogue and subtitles (the biggest open bug) — no deterministic way to start a conversation yet;
* chest lid, bent head/pickaxe — visual, would need screenshot comparison;
* ore mining — needs the mineable object identified in a live game;
* two-PC play — needs a second machine.

## What red means (2026-11-05)
- FAIL = a real divergence or a new fault. Information-only rows (INV, CAM) and the probe module faults ("bad address asked by a probe command") do not fail the gate.
- SKIP = the scenario cannot run in the current place (e.g. `npc_health` needs Drake loaded near the heroes); it never counts as a failure.

## Bad network on one PC (core 85+)
`native\build\net_sim.txt` with `loss=<percent> delay=<ms> jitter=<ms>` (any part optional, read every 2 s by each copy, applied to what that copy SENDS; resolution one game frame; delete the file for a perfect network). `.\tools\scenarios.ps1 -Only netsim` runs reference / delay / 10 % loss / 30 % loss + delay: the host hero jumps 400 units and the time until the other copy draws the puppet there is measured (floor about 2.5 s because of the probe round trips), then parity and exceptions after the network is perfect again.
First result (2026-11-05, one run): reference 3 / 2.7 / 2.5 s; delay 2.7 / 2.5 / 2.7; loss 10 % 2.7 / 2.5 / **10.4**; loss 30 % + delay 2.7 / 2.4 / 2.7; parity back, 0 new exceptions. The 10.4 s sample is unexplained (repeat before trusting it).
