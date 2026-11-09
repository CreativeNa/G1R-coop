# Bug: the UI dies after a save load (no Esc, no inventory, broken strings)

Status: **fixed and verified on 3 load cycles (2026-11-05)**, both directions (host and guest).
This file exists so the bug can be recognised and found again quickly if it returns.

---

## Symptom

After a save load — F9 **or** loading from the pause menu, on either copy — the game keeps
running but the interface is dead:

* `Esc` does not open the pause, `I` does not open the inventory;
* the quick-slot icons (1–9) disappear;
* there is no "game saved" confirmation;
* the HUD shows `<MISSING STRING TABLE ENTRY>`;
* the crosshair looks like spell-aiming mode ("как будто магией пользуешься");
* sometimes a **transparent save-selection window** appears;
* both copies are affected; a restart of the game is the only cure.

The game itself is fine: two clean copies without the core load and keep a working UI, including
two simultaneous loads.

---

## What it was (two separate defects, both fixed)

### 1. The load was applied TWICE on the receiving copy — the real cause

`story_module.c`, `load_apply()`. The sending copy repeats a `type 9` (slot load) event until it is
acknowledged. The first application **starts a load**, and a load resets the module's state —
including the queue of already-seen ids. The repeated event then looked new and was applied a second
time. Two loads back to back is what kills the UI and the input state.

Evidence in `native/build/coopdll.log` (one F9 press on the guest):

```
[21324] S load: the other player loaded save Q, started here (ok)
[21324] S load: page deactivated (ok) and removed (ok) right after the load started
[21324] S load: StartLoadingSave '#0' (started by the other player, not sent back)
[21324] S load: page on the screen (ok), activated (ok)          <-- SECOND application
[21324] S load: the other player loaded save Q, started here (ok)
```

The user saw it as "the host loaded three times while I pressed F9 twice".

**Fix (final):** the applied lid is written to `native/build/last_load_lid.txt` as `pid:lid`, and
`load_apply()` ignores an event whose lid matches **for the same pid**.

Why a file and not memory: `mod_init()` runs again when a world loads (the log shows
`M module initialised` right at that moment), so every in-memory structure — the queue of already
seen lids, the `static` timers, everything — is wiped exactly when the repeat arrives. An earlier
attempt kept the lid in a file but deleted it from `mod_init()`, which wiped it at the same moment;
a time-window guard cannot work either, because the repeat arrives 20–30 s later and a window that
long also blocks a legitimate second press ("F9 не прошёл").

Verified in one session: 4 presses → 4 loads on the far copy, 2 delayed repeats caught:

```
S event in: type 9 'Q' lid 19496599 (new)                    <- applied
S event in: type 9 'Q' lid 19496599 (dropped: seen already)  x5
S event in: type 9 'Q' lid 19496599 (new)                    <- the repeat, 30 s later
S load: same event (lid 19496599) already applied, ignored    <- caught
```

### 2. Caught access violations while attaching equipment during the load

`equip_module.c`, `mod_update()`. During a world change the module kept calling
`K2_AttachToComponent` on objects that the engine was already tearing down. The core catches the
access violation and the game survives, but the interrupted engine call is another way to leave the
input/UI state half-initialised.

Log (6 occurrences in one session):

```
AV at coopdll_76.dll+0x2bcfa: reading address 0xa5f226
AV   our code at that moment: call=K2_AttachToComponent module=equip
```

**Fix:** the module stays quiet for 5 s after the hero **or the puppet** changes. Keying it only on
the hero was not enough: the log shows the AV at lines 2202 and 3330 immediately after a load
(address `0x200000002c` — a bogus pointer), because the puppet is recreated during the same window.

### 3. The transparent save-selection window

`story_module.c`, `load_apply()`. To load a slot on a copy that never opened the load menu, the
module creates `W_SavedGamesPage_C` itself, adds it to the viewport and activates it. A page created
outside the normal flow draws as a transparent window and keeps the keyboard.

**Fix:** right after `StartLoadingSave` the page is deactivated **and** removed from its parent; the
cleanup path still removes it if anything is left over (hard timeout 10 s, was 60 s).

---

## Ruled out (do not re-investigate)

| Theory | Why it is wrong |
|---|---|
| the game breaks on load by itself | two clean copies without the core load fine, Esc and inventory work |
| two copies loading at the same time conflict | two clean copies loaded simultaneously (2 s apart) and stayed healthy |
| `m_CurrentBehaviour` stuck at 2 (the "white veil") | measured **2 on both copies in a fully healthy state** — 2 is the normal value; the old `cam_fix` wrote 16 and was fighting normal behaviour (off by default) |
| the saved-games page is the cause | a mode that synchronises F9 as a **key press** (no page at all) still broke the UI — the page was only the visible part |
| the guest posts F9 into the wrong window | `find_game_window()` filters by `pid == GetCurrentProcessId()` |
| the puppet pose is wrong | measured: worst bone deviation 0.4 units, fine |

---

## If it comes back — how to find it in ten minutes

1. **Reproduce** with two copies and one F9. Note which copy and whether it was F9 or the menu.
2. **Count the loads** — this is the fastest discriminator:
   ```powershell
   Select-String -LiteralPath native\build\coopdll.log -Pattern 'S load' | ForEach-Object { $_.Line }
   ```
   One press must produce exactly one `the other player loaded save ... started here` per copy.
   More than one → defect 1 came back. The guard logs `S load: same event (lid N) already applied,
   ignored`; if the repeat is not logged at all, it reaches `load_apply` through another path.
3. **Look for the equipment AVs**:
   ```powershell
   Select-String -LiteralPath native\build\coopdll.log -Pattern 'AV at coopdll|K2_AttachToComponent'
   ```
   Any hit means a module touched an object during world teardown.
4. **Inspect the widget state** (works while the game is broken):
   ```powershell
   python tools\parity.py            # the UI section: GameOver / Pause / Conversation / MainMenu / SavedGames
   ```
   A `W_SavedGamesPage_C` other than `-1` means a page is still in the world; `PauseMenuWidget` at 4
   means the pause exists but is not interactive.
5. **Bisect with switches** in `native\build\`, each is read within a second (no rebuild):
   * `story_noloadsync.txt` — disables only the load synchronisation;
   * `story_loadkey.txt` — synchronises F9 as a key press instead of the page;
   * `equip_off.txt` — stops attaching equipment to the puppet;
   * `story_off.txt`, `npc_off.txt`, `modules_off.txt` — whole modules.

   Known bisect results: with `story_noloadsync` or with a single copy the bug never appeared, which
   is what pointed at the load-synchronisation path.

---

## Where the code is

| File | What |
|---|---|
| `native/story_module.c` — `load_apply()` | creates the page, selects the slot, starts the load, deactivates and removes the page, ignores a repeat of the same event id (memory in `native/build/last_load_lid.txt`, `pid:lid`) |
| `native/story_module.c` — F9 handler | detects F9 through `GetAsyncKeyState`, picks the slot, queues the event (type 9 slot / type 10 key) |
| `native/story_module.c` — `load_page_cleanup()` | safety net: removes a leftover page after the world changed or after 10 s |
| `native/equip_module.c` — `mod_update()` | 5 s grace after a hero change before attaching anything |
| `native/probe_module.c` — `parity` (UI section) | prints the visibility of the six state widgets plus `W_SavedGamesPage_C` |

## Tests that cover it

* `tools\check.ps1` — the parity gate; the UI section reports a leftover page.
* Manual: press F9 on each copy in turn, then Esc and I on both. Expected: one load per press per
  copy, pause and inventory open.
