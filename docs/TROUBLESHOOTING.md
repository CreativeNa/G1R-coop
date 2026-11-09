## The game stutters and one copy runs at 2-5 fps

**Cause: the two game windows overlap.** Windows (and the engine) stop presenting a window that is completely
covered by another one, so the covered copy drops to 2-5 fps. It is easy to mistake this for a mod problem -
the frame times look terrible, but the module costs stay at a few milliseconds.

Measured on this machine: the covered copy ran at 2-3 fps while the visible one ran at 30+, and after tiling
the windows side by side both ran at 26-39 fps.

**Fix:** keep the windows side by side (or on two monitors) so neither is fully covered. `tools\tile_windows.ps1`
puts them on the left and right halves of the primary screen.

This also explains the animation mismatch that comes and goes: a copy running at 3 fps advances its own
animations and AI much later than the other one.

# Troubleshooting index — symptom → where to look

One page for "something broke, where do I start". Each row names the instrument and the file to read.
Deeper write-ups: [`BUGS.md`](BUGS.md) (open and fixed bugs), [`BUG_UI_AFTER_LOAD.md`](BUG_UI_AFTER_LOAD.md)
(the load/UI bug in full), [`TESTING.md`](TESTING.md) (how the checks work), `AI_HANDOFF.txt` in the
repo root (the running journal, in Russian).

---

## Start here, in this order

```powershell
.\tools\check.ps1                 # one command: PASS/FAIL and the layer that broke
Select-String native\build\coopdll.log -Pattern 'AV at coopdll|EXCEPTION'
Get-ChildItem docs\reports | Sort-Object LastWriteTime | Select-Object -Last 3
```

If `check.ps1` is green but the game misbehaves, the symptom table below decides where to look.

---

## Where everything lives

| What | Path |
|---|---|
| the live log of both copies (one file, lines start with `[pid]`) | `native\build\coopdll.log` |
| built modules (hot-reloaded) | `native\build\modules\<name>.dll` |
| per-process copies the core actually loads | `native\build\modules\<name>_<pid>_<n>.dll` |
| switches, read within a second, no rebuild needed | `native\build\*.txt` |
| reports from the checks | `docs\reports\` |
| the journal: every change, why, and how to roll it back | `AI_HANDOFF.txt` (root) |

Module sources: `native\<name>_module.c`. Build one: `native\build_module.bat <name>`.

---

## Symptoms

| Symptom | Where to look |
|---|---|
| **After a load: no Esc, no inventory, quick-slot icons gone, `<MISSING STRING TABLE ENTRY>`, spell-like crosshair, transparent save window** | `docs/BUG_UI_AFTER_LOAD.md`. Quick check: `Select-String native\build\coopdll.log -Pattern 'S load'` — presses must equal `the other player loaded save` lines. The guard logs `same event (lid N) already applied, ignored` when it fires. |
| **F9 does nothing** | First: the game window must be **active** — both the game and `key_poll` only react when that copy owns the foreground window. Check the log for `S load: F9 (quick load) pressed here`; if absent, the key never arrived. If the line is there but nothing loads, the game's own quickload failed (no quicksave) and it drops to the main menu. |
| **An extra load nobody asked for** | Same as the first row: it is a retransmitted event. `last_load_lid.txt` must exist and contain `pid:lid`. |
| **Guest's NPC has wrong HP / a health bar that lies** | `npc_module.c`: the health-set cache (was capped at 600, now 8192) and the record field width (was `uint8_t`, now `uint16_t`). Verify with `.\tools\scenarios.ps1 -Only npc_health`. |
| **A defeated NPC is not posed on the other copy** | Log line `N seat X: ... bone-driven here N, bone-driven mirrors applied M`; if `here > 0` and the other copy's `applied == 0`, the corpse mirror is broken. The gate checks this automatically. |
| **The friend's character looks wrong (bent head, wrong weapon)** | `python tools\parity.py` → `POSE bones` (compares hero bones of one copy with puppet bones of the other). Worst deviation seen in a healthy state: 0.4 units. Equipment visuals: log `E local equipment:` / `E re-attach`. |
| **Chest contents or lid out of sync** | Log lines `S chest tracked`, `S chest ... emptied it`, `S chest ... lid stop replayed`; parity section `CHESTS`. Switch `story_nochest.txt` isolates the chest polling. |
| **Inventory counts differ** | Parity section `INV`; item path logs `S item ... picked up here` / `S gone received`. |
| **`AV at coopdll_...` in the log** | The line after it names the module and the game call, e.g. `call=K2_AttachToComponent module=equip`. A module is touching objects while the world is being torn down — add/extend the quiet period after a world change (see `equip_module.c` / `story_module.c`). `AV ... call=none` means the fault is inside the core itself. |
| **`EXCEPTION` lines** | Same as above; the gate fails only on **new unknown** exceptions (`K2_AttachToComponent` is known and filtered). |
| **The game slows down** | Log `M cost ms avg/max per frame: anim / equip / pose / npc / story / menu / probe` — it names the expensive module. `P smooth` and `N ...` lines show the per-frame cost of pose and NPC work. |
| **The friend is not visible at all** | Log `N3 remote at ... shown ok=1`, parity sections `PUPPET present` and `HERO<->PUPPET`. If `shown ok=0`, the puppet actor is hidden or was never spawned. |
| **The camera is white / the world is veiled after a load** | Measured: `m_CurrentBehaviour = 2` is **normal** in a healthy state; the old `cam_fix` (writing 16) was fighting normal behaviour and is off by default. Do not re-enable it without proof. |

---

## Switches (`native\build\*.txt`, created/removed while the game runs)

| File | Effect |
|---|---|
| `story_off.txt` | the whole story module off (items, chests, quests, load sync) |
| `story_noloadsync.txt` | only the load synchronisation off — safe mode if loads break the UI |
| `story_loadkey.txt` | synchronise F9 as a key press instead of creating the saved-games page |
| `story_nochest.txt` / `story_noscan.txt` / `story_nokeys.txt` | chest polling / item scan / F9+camera+title off |
| `equip_off.txt` | remove all equipment visuals from the puppet |
| `npc_off.txt` | NPC mirroring off |
| `modules_off.txt` | all modules off (the puppet actor still exists) |
| `pose_*`, `anim_*` | pose/animation test aids (see `AI_HANDOFF.txt`) |

---

## Three rules that saved the most time

1. **Compare across copies, not field by field.** Each copy has its own hero: hero A must equal puppet B.
   Equal hero positions on both copies would be a bug, not health.
2. **A module's memory does not survive a world load.** The core calls `mod_init` again when a world
   loads (`M module initialised` in the log). Anything that must outlive a load — "already applied"
   ids, timers — has to live in a file (see `last_load_lid.txt`) or in the core, not in a `static`.
   This one mistake produced a double load, a broken UI and two wasted fixes.
3. **Text in the log is the source of truth, not what the screen seems to show.** "The host did not
   catch F9" turned out to be "the world did reload, 30 s later"; "the host is in the main menu"
   turned out to be a widget that exists in memory all the time. Read the lines, then judge.

## "This save was made with a different modlist" (with G1RCoop in the list)

The game records the injected core in the save's mod list, so the two PCs must run the **same core file**. It is not
enough that the source tree matches: the name and build of the DLL that was injected is what ends up in the list.

Seen live: the host had been started with `coopdll_109.dll` (built by an earlier session), while every package built
later shipped `coopdll_106.dll`, so the guest loading the host's save got the warning on F9 and in the load menu.

Fix: install the **same package on both PCs** (0.4.2.32 onwards ships one core for both). If the warning still appears
after that, the save itself was written without the mod - load it once on the host and save again (F5), then send the
new save to the guest with `tools\savesync.ps1`.
