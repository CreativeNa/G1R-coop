# Surviving a game patch (recon mode)

Before this existed, every Gothic 1 Remake update meant a manual recon session: find `GUObjectArray`,
the `FNamePool` block table and `ProcessEvent` again, then edit the `BUILDS[]` table in
`native/coopdll.c`. Recon mode makes the core find them itself and remember the answer.

---

## What happens on an unknown build

`native/coopdll.c` picks a profile by **exe file size**. When the size is not in `BUILDS[]`, the core
no longer refuses to start; it searches:

| Thing | How | Where |
|---|---|---|
| `FNamePool` block table | block 0 begins with the entry `"None"` (header length 4, ANSI); the block index and byte cursor sit right before the table | `recon_find_pool()` |
| `FUObjectArray` | scans the writable sections for the `FChunkedFixedUObjectArray` layout `{Objects**, PreAllocated*, Max, Num, MaxChunks, NumChunks}`; a candidate is accepted only when the first 40 items know their own index (`UObject + 0xC`) | `recon_find_arr()` |
| `ProcessEvent` | the vtable **slot 77** of the first `UObject`. That slot index was read off a known build; it is stable inside one engine version | `recon_find_pe()` |

The result is logged and, crucially, **written to `native/build/learned_profile.txt`**:

```
RECON: name pool found (rva 0x9dffd90)
RECON: object array found (rva 0x9eb6bc0)
RECON: ProcessEvent found (rva 0x13a6b40, vtable slot 77)
RECON: ready. Paste this into BUILDS if you want it permanent:
RECON:     { 175124992u, 0x9EB6BC0u, 0, 0, 0x13A6B40u, 0x9DFFD90u, 0, 0 },
build profile for exe size 175124992 DISCOVERED by recon and saved to learned_profile.txt
```

The next start on the same build does no scanning at all:

```
build profile for exe size 175124992 loaded from learned_profile.txt (recon mode)
```

So the cycle after a patch is: **start the game once → read one line → play**. If you want the build
in the source (so a fresh install works without the file), paste the printed line into `BUILDS[]`.

---

## Self-test without waiting for a patch

`native/build/force_recon.txt` makes the core pretend the build is unknown, then check that it finds
the same RVAs a human found:

```powershell
Set-Content native\build\force_recon.txt "self-test"
Remove-Item native\build\learned_profile.txt
.\tools\start_coop_11.ps1 -Seats 0
# log must show the three "RECON: ... found" lines and a profile identical to BUILDS[]
Remove-Item native\build\force_recon.txt
```

Verified on 1.2 (exe 175124992): recon produced `0x9EB6BC0 / 0x13A6B40 / 0x9DFFD90` — exactly the
hand-made profile — and the mod ran normally on it (probe answered, modules loaded, hero resolved).

---

## What recon does NOT find

* `rva_tostring` / `rva_ctor` — the old `FName::ToString` and `FName` constructor. Not needed: the
  core falls back to reading names straight from the pool (`rva_pool_blocks`).
* `rva_tick_scan` / `rva_guard` — optional hooks (camera tick scan, audio guard). Left 0; the core
  logs the loss and continues. If a new build needs them, they still have to be found by hand.
* Anything the game keeps outside the exe image (assets are unaffected by a patch).

So a patch needs no developer action for the core, **unless** a future engine update changes the
`UObject` vtable layout — then `RECON_PE_SLOT` (77) is the one constant to re-read. The core prints
the slot on every start of a known build: `RECON hint: ProcessEvent is vtable slot N`.

---

## After a patch — the full checklist

1. Start the game once with the new build; read the `RECON:` block in `native/build/coopdll.log`.
2. If it says `ready`, the core works. If it says `recon failed`, the failed line names what is
   missing (pool / array / ProcessEvent).
3. Re-dump the reflection if the SDK is needed: `tools/sdk_from_dump.py`, `tools/dump_to_usmap.py`
   (see `docs/RE/README.md`).
4. Run `tools\check.ps1` — the parity gate tells immediately whether the modules still line up.
5. When everything is green, paste the `RECON:` line into `BUILDS[]` and commit it, so the next
   install works without `learned_profile.txt`.
