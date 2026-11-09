> **Readiness of the current build (0.4.2.51): about 65%.** It runs a real session, but much of the newest code was
> measured and changed in the same night; treat it as promising, not stable, and test it hard. Details: `docs/STATUS.md`.

# Changelog

> **Исторический документ.** Описывает переносную раскладку (
ative\build + start_net.ps1) до установщика.
> Актуальный поток — docs/HOW_TO_PLAY.md (установщик, ярлык «Gothic 1 Remake Co-op»).



Detailed log of what was built, why, what broke on the way and how it was fixed. Newest first. Dates are 2026-10-30 / 2026-10-31 unless noted. "Seat 0" is the host copy of the game, "seat 1" the guest copy; both run the same DLL.

Everything below was developed and verified with **two copies of the game on one PC** (a separate test copy of the game folder, never the real installation). Real two-PC play over the internet has **not** been tested yet.

> **Important note on testing.** Most of the changes described here were **not tested in real play situations**. Everything was developed and checked only with two copies of the game on **one PC**, mostly through automated scripts and synthetic actions (teleports, destroying an actor instead of a real pickup, direct state writes), not by people playing together. Real two-PC / internet play, long sessions and many ordinary game situations (dialogues, trading, normal looting, longer fights, save / load cycles) have not been exercised. Treat every feature as an experimental first version that **needs further work and real-world testing**.

> **Важно о тестировании.** Большая часть изменений **не проверялась в реальных игровых ситуациях**. Всё разрабатывалось и проверялось только на двух копиях игры на **одном компьютере**, в основном автоматическими скриптами и искусственными действиями (телепорты, удаление объекта вместо настоящего подбора, прямая запись состояний), а не живой игрой вдвоём. Игра по сети между двумя ПК, долгие сессии и обычные игровые ситуации не проверялись. Каждая функция — экспериментальная первая версия, которая **требует доработки и проверки в реальных условиях**.

## 0.4.2.26 — game build 1.2 (2026-11-07)

* **the mirrored body now faces the way it walks.** The drawn component is aligned with its actor (relative rotation
  0); the hero mesh's own `-90` offset was a red herring — copying it turned the body 90, then 180 degrees off. Dialled
  in live with a control line every 5 s (`P yaw: puppet actor -89, drawn comp -89, hero mesh rel -90`) and a
  `pose_yaw.txt` override that applies without a rebuild.

## Verified in the live two-PC session (2026-11-07)

* **story chapter banners** work: the banner shown for a chapter change reaches the other copy and appears there (it
  was built earlier with an observed `GameStory::RequestChapterHUDNotification`; the live session confirmed it);
* **shared death and shared load**: one player's death kills the other and both load the same save, once per death;
* **quests, trade, chests, loose items, NPC mirroring and combat** all verified on the pair (details in
  `docs/SESSION_2026-11-07.md`).

## 0.4.2.25 — game build 1.2 (2026-11-07)

* **the story module re-reads the role every two seconds** and takes it from `connect.txt` first: a guest that started
  before the host (and was therefore given the host role at start-up) stops acting as the host the moment it joins -
  the log says `S role changed: host -> guest`;
* **firewall ports sorted out**: UDP 40001 (game) and 40002 (discovery), TCP 40003 (saves) and 40004 (diagnostics);
  40002 used to land in the TCP rule and 40004 was missing;
* includes 0.4.2.23 and 0.4.2.24: `role = guest` makes the launcher retry the discovery instead of quietly becoming a host, and the
  diagnostic bridge starts by itself with the launcher.

## 0.4.2.22 — game build 1.2 (2026-11-07)

**Both copies must be updated: the modules changed (story, npc, pose) and the launcher does too.**

### Fixed (found in the first live two-PC session)

* **The guest believed it was the host.** The modules detect the role from `role.txt`, then from `-CoopSeat=` on the
  command line - and the launcher never passed it, so both copies took the host branch. Two consequences, both seen
  live: the clock was driven by both sides (the host applied **14** clock jumps in one session) and the NPC module
  ran in host mode on the guest. The role is now also read from `connect.txt` (`join` = guest), which is what
  actually decides the connection, the launcher passes `-CoopSeat=0|1`, and **the host refuses to apply an incoming
  clock at all**, whatever the other side thinks it is.
* **The mirrored player's body stood 90 degrees sideways.** The hero's mesh is a Mutable asset with its own relative
  rotation - measured as `0, -90, 0` - and the pose module attached its drawn component with `SnapToTarget` without
  transferring that offset. The puppet now takes the local hero mesh's relative rotation (same pipeline on both
  copies), and the log prints the value it used.

### Changed

* **No startup movies.** The publisher logos, the legal screen and the ~1 GB intro are loose `.bk2` files under
  `<game>\G1R\Content\Movies`, and neither `-no-intro-cinematic` nor `-nosplash` nor editing the movie lists in
  `Game.ini`/`Engine.ini` switches them off. The installer renames them to `*.bk2.off` (recording the list in
  `_disabled_by_coop.txt`), offers it as a ticked checkbox, and the uninstaller restores every name. This is the only
  change the mod makes inside the game folder, and it is reversible.
* **No auto-continue.** `autoload.txt` is gone by default: it pressed Continue by itself and skipped the main menu,
  which is exactly where the Co-op buttons live. It can be brought back with `autoload = 1` in `settings.ini`.



**A build-dependent bug that made the whole mod silent on one machine.**

### The bug

The core detects the engine's property layout (where `UStruct::ChildProperties` lives, how far `FField::Next` and
`FField::NamePrivate` are inside a property) at start-up, because those offsets differ between engine versions. It used
to accept the first candidate whose property names merely *looked* plausible, and it did so **once**, early, while the
engine was still filling the class in.

On a GOG copy that meant: the core hooked, the modules loaded, log lines appeared, positions and poses flowed - but
every property lookup returned nothing (`members` printed `0 props`), so the menu module could not find its anchor
button and neither Co-op button was created. The log said `detect: no first property`, which was misleading: the answer
was "not yet, and not there".

### The fix

* a layout is accepted only when it can actually see **properties every Actor has** (`Tags`, `bHidden`, `Instigator`,
  `Owner`, `RootComponent`, `ReplicatedMovement`, `CustomTimeDilation`, `bCanBeDamaged`); two hits are required, so a
  wrong chain cannot pass;
* several `ChildProperties` offsets and five `(Next, Name)` pairs are tried, and the detection **re-runs every 2 s**
  until one matches;
* the menu module no longer gives up after 12 attempts - it keeps trying every 1.5 s.

On the affected PC the log then showed:

```
detect: child +0x50 next +0x18 name +0x20 -> 8 known Actor properties
detect: layout accepted: ChildProperties +0x50, next +0x18, name +0x20, Offset_Internal +0x44
MENU: anchor button 'LoadGame' found
MENU: co-op buttons created (...), language russian (engine 'ru')
```

### Verified on a real pair over Radmin

```
launcher: role: guest, fetching the save games from x.x.x.x, connect.txt: join ... 40001
net: id=S1 local :40001 -> x.x.x.x:40001
net: the host says: welcome, the gate is open
N2: hero instance found at frame 481
N3 remote at 103403 -58699 2503 shown ok=1 (packets seq=960)
P received pose #1001 (425 bones, interval 74 ms)
```

So a GOG copy and a Steam copy of the **same** game build (both `175124992` bytes) can play together, and the guest's
save games are replaced with the host's automatically.

### Also in this version

* `firewall_coop.ps1` ships with the installer (a host without the rule never receives a packet);
* **the publisher logos, the legal screen and the 1 GB intro are switched off.** They are loose `.bk2` files in
  `<game>\G1R\Content\Movies`; no command line argument and no user configuration stops them (`-no-intro-cinematic`,
  `-nosplash`, a cleared `MoviePlayerSettings` section in `Game.ini` and `Engine.ini` were all tried and none worked).
  The installer therefore renames them to `*.bk2.off` and writes `_disabled_by_coop.txt` next to them; the uninstaller
  puts every name back. It is a checkbox in the wizard ("Не показывать заставки") and it can be unticked. This is the
  only thing the mod ever changes inside the game folder, and it is reversible.
* **the auto-continue switch is gone.** `autoload.txt` made the game load the newest save by itself, which jumped past
  the main menu - the very place the Co-op buttons live. The launcher also deletes a stale `autoload.txt` left by an
  older version, so the menu stays on screen; the connection is already written, so the player only presses Continue.

---

## 0.4.1 — game build 1.2 (2026-11-06)

**The first version a person can install without touching a console: download, run `Setup.cmd`, play.**

### Added

* **An installer.** `Setup.cmd` starts a wizard that finds the game by itself - **any store and a disc install**:
  Steam libraries from the registry and `libraryfolders.vdf`, **GOG** from the store's own registry keys and its usual
  folders, and **anything that registered itself in "Apps and features"** (which is how GOG Galaxy and most retail
  installers do it), then the plain folders on every drive. If none of that matches, the wizard asks for the folder.
  It then checks the game build, copies the mod into
  `%LOCALAPPDATA%\G1RCoop\app`, writes `settings.ini`, creates a desktop shortcut ("Gothic 1 Remake Co-op"), a
  Start-menu group and an entry in "Apps and features". **Nothing is written into the game folder**, so a failed
  install cannot damage the game; the previous version is kept until the new one is verified and only then removed.
* **A launcher.** The shortcut starts the game and injects the core after it is up; failures are shown in a message
  box and written to `%LOCALAPPDATA%\G1RCoop\logs\launcher.log`.
* **An uninstaller** that removes the folder, the shortcuts and the registry entry, keeps the settings if asked, and
  never touches the game or the save games.
* **A second main-menu button: "Join co-op".** It needs no address at all: the mod broadcasts a probe, the host's
  core answers with its port, and the guest connects to the first host that replies. Manual address entry still
  works (an address on the clipboard + the "Co-op" button).
* **The "Co-op" button works while the game is running.** The core used to read its connection file once, at load,
  so pressing the button changed nothing; it now watches the file and reconnects live.
* **The button picks the right address**: the Radmin VPN address (26.x.x.x) first, then an ordinary private one, by
  enumerating the network adapters instead of resolving the host name.
* **A Radmin VPN check** in the installer: it shows your own 26.x address, or tells you the mod is useless over the
  network without it.
* **No banners before the menu.** The launcher now starts the game with \-no-intro-cinematic -nosplash\, so the publisher logos, the intro movie and the splash screen are skipped and the main menu (with the Co-op buttons) comes up as soon as the engine has loaded. Extra arguments can be added in \settings.ini\ (\extra_args = -windowed -ResX=1600 -ResY=900\).
* **The launcher decides everything by itself.** On start it asks the network whether somebody is already hosting
  (the same probe as the button): if a host answers it becomes the guest, **fetches his save games automatically**
  (the guest's own are backed up first), writes the connection and injects; if nobody answers it becomes the host,
  starts serving its save games and hosts. `settings.ini` can force the role (`role = host|guest|auto`) or switch
  the save transfer off (`save_transfer = 0`). The in-game buttons stay as the manual fallback.
* **A black box that starts with the game.** The launcher runs `tools\blackbox.ps1` hidden, and it stops by itself
  when the game exits. It samples both copies every 10 s into `%LOCALAPPDATA%\G1RCoop\logs\blackbox_<time>.jsonl`
  (alive, frame rate, seconds since the copy last wrote to the log) and writes a report - the last samples, the last
  200 log lines per copy and a full copy of the log - on the first anomaly: a crash, a copy that stops logging
  (freeze), a frame rate below 15 for two samples in a row, a new `EXCEPTION`, or the two copies' state diverging.
  A start-up grace of 90 s keeps loading screens out of the reports. Nobody has to remember to run it.
* `tools\make_installer_package.ps1` builds the whole distribution (`dist\Gothic1Coop-Setup-<version>.zip`): the
  four installer scripts, the payload (core, 7 modules, `inject.exe`, `autoload.txt`), a manifest with the hash of
  every file, and a "READ ME FIRST" that assumes the reader has never installed a mod.

### Verified

* the silent install path end to end: 12 files in `app`, the desktop shortcut and the uninstall entry created;
* the launcher: the game starts, `LoadLibrary returned 0x... (nonzero = loaded)`, and the core writes its log into
  the installed folder;
* discovery on a running host: `COOP-WHO?` on UDP 40002 is answered with `COOP-HOST 1 40001 S0`.

### Notes

* PowerShell reads a `.ps1` without a BOM as ANSI, which broke the Cyrillic strings in the wizard - all installer
  scripts are saved as UTF-8 **with BOM** now;
* `Join-Path` throws on a drive that does not exist, which made game detection fail on a machine without an `E:`;
  the paths are built as strings and the drives are checked first.

---

## 0.4.0 — game build 1.2 (2026-11-06)

**The core and every module changed: both copies need a restart.** Afterwards the modules stay hot-reloadable.

### Added

* **Trade.** A trader's purse and whole stock now follow the other copy. The stock is written only when both
  copies agree on the item order (a checksum of the item names travels with it), so counts can never land on the
  wrong item. Ore, items and prices stay per hero - each player pays from his own purse.
* **Shared sleep.** Whoever sleeps in a bed, the other copy darkens smoothly with the game's own camera fade and
  both wake up with the same time of day. The dark lasts a bit longer than the game's own sleep screen, so the
  clock changes while the screen is black.
* **The Light spell is visible on the caster across copies.** While one player holds a light, the other copy shows
  it on his character (the game's own light actor is re-bound to his puppet; two simultaneous lights still
  conflict, see the limitations).
* **Dead NPCs fall over on the other copy.** Both death paths release the body and enable physics, so a corpse
  never stands upright on one side.
* **A quest HUD and journal entries arrive while playing**, and the quest tracker shows the same objective on
  both copies.
* **Window layout helpers** (`tools\window_monitors.ps1`, `window_split.ps1`, `window_size.ps1`) - two copies of
  the game on one GPU run at a few frames per second when one window is full-screen, and these put them side by
  side or on two monitors.
* **Diagnostic tools**: `tools\health.ps1` (state of the run), `tools\tail.ps1` (filtered log), `tools\cmp.ps1`
  (the same object on both copies, only the differences). New probe commands: `arr`, `hex`, `where`, `pkg`.

### Fixed

* **A transformation is noticed at all.** The game possesses a different actor (a creature) and the mod kept
  mirroring the old hero. The core now follows the player controller's `Pawn`, and the receiving side keeps its
  own bone list, so the other player's animation no longer freezes after a transformation. The creature's mesh is
  sent by path, loaded and set on the puppet. (Still imperfect: the creature is misplaced and its head is off -
  see the limitations.)
* **The clock has one owner again.** Both copies were sending it and pulled the clock up to 20 hours apart; the
  host sends, compared in seconds, every 5 s.
* **Frame rate**: the story module went from about 9 ms to 3-5 ms per frame - the trade and stats work had been
  walking the whole object list several times a second.
* **The stutter was not the mod**: a full-screen game window on one GPU leaves the other copy at 2-5 frames per
  second. `docs/TROUBLESHOOTING.md` explains how to recognise it, `tools\window_monitors.ps1` fixes it.
* **A retransmission storm**: queued events re-stamped their sequence on every packet, so an acknowledgement never
  caught up and one event was re-sent hundreds of times a second (which dropped the frame rate).

### Verified in play, no code change needed

* **Quests** synchronise in both directions - the quest, its objectives and the journal entry arrive on the same
  second.
* **Skills are separate for both kinds**: attributes (strength, spent points) and the real `GE_Skill_*` skills
  (lockpicking, pickpocket, ...). Each hero learns on his own, and the trainer never blocks the second player.

### Known limitations

* a creature from a transformation is drawn misplaced and its head is off;
* the mirrored player's face is deformed;
* the other player's spell effects are not reproduced (projectiles, flashes, sounds) and spells cannot damage the
  other player - his puppet has no collision;
* dialogue text and voice are still host-only;
* closing a chest works, opening it is still 3-4 s late on the other copy;
* the "new journal entry" popup does not appear for the copy that receives the entry;
* playing over a network between two PCs is still untested end to end.

---

## 0.3.3.1 — game build 1.2 (2026-11-06)

Patch release on top of 0.3.3. **Only the `story` module changed**, so dropping the new `story.dll` into
`modules\` is enough - the game reloads it in about a second. The core is the same as in 0.3.3.

**Added — shared sleep.** When one player sleeps in a bed, the other copy goes dark too and both wake up
together with the same time of day. It works in **both directions** (host sleeping or guest sleeping):

* the sleeping copy notices its clock leap (the game runs under a minute per second, so a jump of five
  minutes or more is unmistakably a sleep), sends the new time at once and tells the other copy how long
  to stay dark - the length comes from the game's own sleep ability
  (`m_TimeBetweenFadeOutAndFadeIn`) plus three seconds;
* the other copy darkens with the engine's own `PlayerCameraManager::StartCameraFade` (0.7 s in and out),
  changes its clock **while the screen is black**, and lifts the fade by itself;
* a clock this copy wrote itself is not mistaken for a sleep (5 s guard), so the fade does not bounce
  back and forth.

Verified in two runs in both directions.

**Fixed on the way**

* two events queued in the same tick shared one event id, so the receiver dropped the second as a
  duplicate - that is why the new time only arrived on the next 20 s heartbeat instead of with the fade.
  Every queued event now takes its own id;
* the "clock jumped" check used a flat 5-minute threshold against a 20 s heartbeat, and the game's clock
  runs ~3 in-game minutes per 10 real seconds - the normal passage crossed it every heartbeat and one
  sleep produced four black screens. The clock is now sampled every second and compared against what the
  normal passage can produce.

**Chest lid**

* closing now works on the other copy: it gets the closing section, the stop and the host's frame, and
  forcing the mesh and actor to tick at that moment puts the lid down;
* opening still has a 3-4 s visual delay on the other copy although every event arrives in the same
  millisecond and the animation state ends up identical to the host. Measurements and the next ideas are
  in `docs/BUGS.md`; it is cosmetic.

---

## 0.3.3 — game build 1.2 (2026-11-06)

**The core changed, so both copies need a restart once.** The modules are hot-reloadable as usual.

**Fixed and verified**

* **F9 no longer kills the UI.** The double-load chain is closed: the stuck-death fallback stays quiet
  for 60 s after any load, and the autoload only presses `Continue` before a world has existed in the
  process. Verified in play: one F9 -> one load, ESC and the inventory work afterwards, no exceptions.
* **The frame rate is back in the window title** (`Gothic 1 Remake - [HOST / GUEST] 30 fps`, refreshed
  every second).

**Added**

* **Native hooking in the core.** Until now the mod could only observe UFUNCTIONs through ProcessEvent.
  The core now patches the exe's **delay-import table**, which is where a game that links a DLL lazily
  keeps its function pointers. This is what made the FMOD work below possible, and it is reusable for
  any other lazily imported engine function.
* **FMOD voice groundwork** (experimental, capture only): the core hooks
  `FMOD::Studio::EventInstance::start` and `System::update`, learns the Studio system pointer, and
  identifies every started event through the plain C exports
  (`EventInstance_GetDescription` -> `EventDescription_GetID` -> `System_LookupPath`). Playback for the
  other copy is exposed to modules as `fmod_play_guid()`. Captured so far: the music event; a live
  conversation produced no `start` line yet, so the dialogue voice is not confirmed to go through this
  path. The next steps are written down in `docs/BUGS.md`.

**Documentation**

* `gore\` now carries the GORE toolkit and the game's decompiled AngelScript (7263 modules) inside the
  project, with a README on how to regenerate it after a game patch. The journal synchronisation came
  straight out of that source tree, and the dialogue findings did too.
* `docs/BUGS.md` records what a real conversation shows, which functions can and cannot be observed, and
  that `probe nativefn` must not be trusted (it answers the same for everything).

**Known limitations (unchanged)**

* Dialogue text and voice are still host-only (see above for the current state of that work).
* Closing a chest leaves the lid half open on the other copy (cosmetic).
* A torch lying on the ground burns on the guest but not on the host (cosmetic).
* Playing over a network between two PCs is still untested end to end.

---

## 0.3.2 — game build 1.2 (2026-11-06)

**Both copies must run this build together:** the cutscene event record grew from 53 to 69 bytes, so a
0.3.2 module cannot talk to an older one. The `story` and `probe` modules changed; the core did not.

**Added — the journal / glossary is synchronised.** After a conversation the entry now appears on both
copies, which it never did before. How it works: every copy polls
`Document::FindSegmentsUnlockedByReader` every 3 s (the reader is the hero's `m_CharacterState`, and one
call returns the whole unlocked set), keeps a snapshot and sends the names of segments that appeared
since. The receiver resolves the name to a class, reads the owning document from that class's
`Default__` object (`InDocument`) and calls `Document::RememberSegmentUnlocked` with its own reader.
Verified live: an unlock on the host reached the guest in **160 ms**. The names and offsets came from
decompiling the game's AngelScript with [GORE](https://github.com/dh0er/gore).

**Fixed — the UI dying after F9.** Two load paths could start a second load on top of a running one, and
two loads in a row is what kills the ESC/inventory/UI: the stuck-death fallback (it ignored a load that
was already running) and the autoload (it pressed `Continue` in the main-menu widget that the game
rebuilds during a load). The fallback now stays quiet for 60 s after any load, and the autoload only
acts before a world has existed in the process.

**Also in this build (from the parallel work on the repo):** a two-PC test kit
(`tools\start_net.ps1`, `tools\savesync.ps1`, `docs\TWO_PC_TEST.md`), network emulation in the core
(`native\build\net_sim.txt`), a beta package builder and tester guide, and persisted event ids so a
retransmitted death/load/drop event is not applied twice after a module reload.

**Known limitations (unchanged)**

* Dialogue text is still host-only, and voice too - the dialogue widgets are Blueprint bytecode that
  cannot be observed from a DLL. The next attempt is the game's own voiceline API
  (`SayVoicelineWithContext(tag, ...)`), which would give voice and subtitle natively.
* Closing a chest leaves the lid half open on the other copy (cosmetic).
* A torch lying on the ground burns on the guest but not on the host (cosmetic).
* Playing over a network between two PCs is still untested end to end.

---

## 0.3.1 — game build 1.2 (2026-11-06)

A small release on top of 0.3.0. Only the `story` module changed, so **no restart is needed** — drop
the new `story.dll` into `modules\` and it reloads within a second.

**Fixed**

* **The chest lid now opens on the other copy.** For a long time this was recorded as "the animation is
  set and the position runs, but the pose is not drawn". The real cause was found by reading the state
  instead of looking at the screen: the guest's chest anim instance had `CurrentAsset = null` while the
  host was playing `PT_LockedChest_AnimMontage`. The game writes that asset straight into the
  single-node instance and never calls `Multicast_PlayInteractMontage`, so nothing was ever sent. Now
  the host sends the animation state itself, the receiver loads the montage when it is not in memory,
  and both sides resolve the chest immediately - the host from the actor pointer the observer hands
  over, the guest from the four id bytes in the message - so opening works on the first try even right
  after a module reload.
* **Observer slot 0 was ignored.** `observe_fn` returns slot **0** for
  `Multicast_JumpSectionInteractMontage`, but every mapping loop required `slot > 0`; those calls were
  logged as `S obs ?` and never reached a handler, and the registration retried every second. Both fixed.

**Changed**

* The per-call observation trace (`S obs ...` for every engine call, with its parameters) is now off by
  default - it is a lot of lines in a fight. Enable it by creating `native\build\obs_log.txt`.
* New `docs/TEST_AIDS.md`: giving items (`give_host.txt` / `give_guest.txt`, the torch is
  `ItMw_1H_Torch`), `dropnear:`, teleporting, setting the game clock, and the fact that console `summon`
  does not spawn anything in this build.

**Known limitations (unchanged from 0.3.0, plus one)**

* The guest does not see dialogue text, and voice is host-only by design — the dialogue layer is
  AngelScript bytecode, and neither its widgets nor its voiceline calls can be observed from a DLL.
* **Journal / glossary entries are not synchronised**: after a conversation the entry appears only for
  the host. The unlock lives in `Document::RememberSegmentUnlocked` (bytecode, cannot be hooked); the
  planned fix is to poll `Document::FindSegmentsUnlockedByReader` and replay the unlock on the other copy.
* Closing a chest leaves the lid half open on the other copy (cosmetic; the opening path works).
* A torch lying on the ground burns on the guest but not on the host (cosmetic, cannot be read through
  reflection either way).
* Playing over a network between two PCs has never been tested.

---

## 0.3.0 — game build 1.2 (2026-11-05)

First release that runs on game build 1.2 (exe 175124992). Upgrade notes: the core DLL changed, so
**both copies need a restart once**; the modules themselves stay hot-reloadable.

**Fixed**

* **The UI died after a save load** (no Esc, no inventory, missing quick-slot icons,
  `<MISSING STRING TABLE ENTRY>`, a spell-like crosshair, sometimes a transparent save window). Cause:
  the load synchronisation applied the load **twice** on the receiving copy - the sender retransmits
  until acknowledged and a load resets the module, so the repeat arrived ~30 s later and was applied
  again. Fixed by remembering the applied event id on disk. Also: the saved-games page created to
  start the load is removed immediately (it kept the keyboard), and the equipment module stays quiet
  5 s after a world change (the caught `K2_AttachToComponent` violations are gone). Write-up:
  `docs/BUG_UI_AFTER_LOAD.md`.
* **NPC health never reached the other copy**: the attribute-set cache was capped at 600 entries and
  the value was sent as one byte (clamped at 254). Now 8192 entries and `uint16`.
* **Freezes**: `find_object` was called four times a second for the dialogue work and walks the whole
  object array, which pushed the story module to 13-17 ms per frame. Object lookups are cached and the
  item scan respects its time budget (3.3 -> ~1.0 ms/frame for that module).

**Added**

* **Recon mode**: on an unknown exe size the core finds `GUObjectArray`, the `FNamePool` block table
  and `ProcessEvent` by itself, saves them to `native/build/learned_profile.txt` and prints a
  ready-to-paste `BUILDS[]` line. A game update no longer needs a developer. `docs/RECON_MODE.md`.
* **QA tooling**: `tools\check.ps1` (one command: parity gate + load audit + NPC health scenario),
  `parity_suite.ps1`, `scenarios.ps1`, `load_audit.ps1` (regression gate over the log), `status.ps1`
  (processes, switches, per-seat module builds, costs), `probe near` (what is around the hero),
  `realkey.ps1`/`realclickat.ps1`. Log lines carry timestamps and rotate at 32 MB.
  `docs/TESTING.md`, `docs/TROUBLESHOOTING.md`.
* **Verified in live play**: ore pickup synchronises in both directions; a chest-set difference and a
  "leftover" nugget were transients (streaming and the garbage collector), now handled by the tools.

**Known limitations**

* **The guest does not see dialogue text.** The line is read on the host and transferred (66 ms
  measured), but the display could not be made reliable: the game itself reuses the subtitle widget
  class for its ambient lines, and the other widget classes cannot be created. The display code was
  removed; the findings and everything already tried are in `docs/SESSION_2026-11-05.md`. Story
  dialogues therefore stay readable to the host only. **Voice is host-only by design** - the audio
  plays in that process and cannot be sent to another.
* The chest lid is not drawn on the other copy.
* Playing over a network between two PCs has **never been tested**; everything was verified with two
  copies on one PC.
* A rare, caught access violation inside the story module while it builds a packet (a few per hour).

---

## Contents

1. [Story, quests, world items, chests](#1-story-quests-world-items-chests)
2. [Shared NPCs and per-NPC ownership](#2-shared-npcs-and-per-npc-ownership)
3. [Knocked-out and dead NPCs (bone-driven bodies)](#3-knocked-out-and-dead-npcs-bone-driven-bodies)
4. [Network layer](#4-network-layer)
5. [Automated tests and tools](#5-automated-tests-and-tools)
6. [Startup speed and auto-continue](#6-startup-speed-and-auto-continue)
7. [Puppet: bow, arrows, equipment](#7-puppet-bow-arrows-equipment)
8. [Crashes found and what was done](#8-crashes-found-and-what-was-done)
9. [Mistakes made and reverted](#9-mistakes-made-and-reverted)
10. [Not done / not verified](#10-not-done--not-verified)
11. [Credits](#11-credits)

---

## 1. Story, quests, world items, chests

New hot-reloadable module `native/story_module.c`, new third data channel in the core (`S|` datagrams), `COREAPI_VERSION` 9 -> 10 (`set_local_blob3`, `remote_blob3`, `remote_blob3_len`, `remote_blob3_seq`). The core now loads six modules (`anim`, `equip`, `pose`, `npc`, `story`, `probe`; `MAX_MODS` raised to 8). Because the module list grew, this needed a new core DLL (`coopdll_51`) and a game restart once; after that the module itself is hot-reloadable.

### 1.1 Story flags

- The game keeps its whole story in one object, `StoryG1R` (a subclass of `GameStory`). Its own properties are one **contiguous block of memory** (offsets 912..2788, about 520 four-byte words: integers such as `Drax_GotBeer`, and 8-byte in-game-time values), plus the current chapter in the parent class (`GameStory::Chapter`).
- Every second the module reads the block and compares it with "what both copies last agreed on". Words that differ become **pending changes**.
- Pending changes are sent as `(word index, value)` pairs. They stay in the list and are re-sent every second **until the other copy acknowledges** the blob (every blob carries its own sequence number and the last sequence number it received). A lost datagram therefore costs one second, not a lost change.
- The receiver writes the values into its own story object and records them as agreed, so they are not echoed back.
- **First contact:** the host starts with "everything differs", i.e. it sends the full block and the full quest table; the guest takes it over (the host leads the world, like everything else).
- **Conflict** (both copies changed the same word within a second): the host wins.
- Verified in both directions (test below): a flag set on the host appears on the guest and vice versa.

### 1.2 Quest states

- `QuestSubsystem.AllQuestInstances` holds 679 quest objects. Each has a one-byte `State`. Found values: 0 none, 1 available, 2 running, 3 failed, 4 succeeded (checked through `IsRunning`, `IsAvailable`, `HasSucceeded`, `HasFailed`, `IsCompleted` on sample quests of each state).
- Quests are matched between the copies by a hash of the object name (`Instance_Quest_...`), so the order of the arrays does not matter.
- Same delta mechanism as for the story words. A *live* change (a few quests) is applied through the game's own functions (`StartQuest`, `SucceedQuest`, `MakeQuestAvailable`) so journal entries, notifications and rewards happen for the local hero too; if the function leaves a different state, the byte is written directly. A *bulk* change (first sync, more than 20 quests) is written directly so the guest is not flooded with 80 "quest started" notifications.
- Verified: starting a quest on the host puts it into the running state on the guest; setting it finished on the guest finishes it on the host; resetting it resets it.
- `SucceedQuest` on a quest that was just started can refuse to change the state (quest logic of its own). The sync itself is consistent in that case (both copies show the same state); the automated test therefore sets the finished state directly.

### 1.3 Items lying in the world

- Items lying in the level (`BP_ItFo_Plants_*_World_C`, `BP_ItAI_BrushWood_World_C`, pouches, ...) are `InteractiveObjectActor`s with `m_WorldItemDefinition`. The module tracks the ones within 3500 units of its own hero (a sliced scan of the object table, 30000 objects per second, so a full pass takes about 15 s).
- An item that gets **destroyed** (`bActorIsBeingDestroyed`) while it was within 2500 units of its hero is a **pickup**; its id goes into the pending list and the other copy destroys the matching actor. If the other copy has not loaded that actor yet (streaming), the id is remembered and the actor is destroyed the moment it appears.
- **Identity across the two copies:** placed items have a 16-byte `m_PersistentId`. Items the level spawns at runtime (plants, wood) have an all-zero id, so their key is a hash of the class name and the position rounded to 25 units (deterministic in both copies). Keys of chests are told apart from item keys by flipping a byte.
- **False pickups were the hard part.** The game removes items by itself in groups when the hero teleports or a sub-level is unloaded. Rules that made the detection reliable: ignore everything for 15 s after the hero moved more than 1500 units in one second (teleport / load); if three or more tracked items vanish in the same second, treat it as streaming; a pickup is one item at a time. Items already destroyed and waiting for garbage collection are skipped when scanning.
- **Core bug found on the way:** `obj_alive(ptr, name)` caches a verified name *per FName index*, but objects that differ only by the number suffix of their name (`BrushWood_World_C_2147347916` vs `..._2147348295`) share the index, so the function reported living objects as dead (and this produced phantom pickups and "removed on arrival" noise). The story module therefore checks identity on the raw FName (index + number) instead. Other modules still use the old call; fixing it in the core is a todo.
- Each hero keeps their own inventory (intended). Only the *world* is shared.

### 1.4 Chests

- A chest actor (`Interactive_Chest_*`, `IO_*_Chest_*`) keeps its contents in a `DataModule_Container` inside its `DataModuleComponent`; the module's `m_Inventory` struct starts with two `TArray`s of items.
- The module counts the items (sum of both array lengths) of tracked chests. When a chest that had items becomes empty next to its hero, the id is sent and the other copy empties the same chest by giving both item lists length 0.
- The game's own `Server_Debug_EmptyInventory` was tried first: it faults (null read, caught by the DLL's exception guard) because the copy has no server authority, so it is not used.
- **Only "emptied completely" is synced.** Taking one item out of several is not.
- Verified in both directions on two different chests (test below).

### 1.5 Ambient birds removed (crash mitigation)

The game crashed three times with `EXCEPTION_ACCESS_VIOLATION reading 0x200` at `G1R-Win64-Shipping.exe+0x5be3977`. The stack runs through `fmodstudio.dll`, and the objects found on the stack each time were ambient birds (`Pidgeon_bp_C`, `Crow_bp_C`, `AmbientLifeWarningFlock`, a `GothicAudioComponent` on a crow). Our own code was not running at the moment of the crash. As a mitigation the story module destroys these actors in both copies (`native/build/ambient_keep.txt` switches this off). **It is not yet verified that this removes the crash.**

### 1.6 Probe commands added

- `ioscan [classSub] [max]`: live actors that have a persistent id, count per class, and for the first few the id and position (skips destroyed ones).
- `contscan [max]`: container modules with their raw inventory bytes (used to find the layout above).
- `emptychest <ptr> [dry]`: prints the item counts of a chest, empties it (test helper), `dry` only reads.
- Earlier this stretch: `heroinfo`, `npcinfo`, `npchp`, `gedamage`, `tp`, `tpto`, `lookat`, `inject`, `attached`, `@N` prefix to address one seat.

## 2. Shared NPCs and per-NPC ownership

Module `native/npc_module.c`.

- **Principle:** every NPC is simulated by exactly one copy, its *owner*; the other copy mirrors it. The owner is the copy whose hero is clearly nearer (hysteresis of 600 units so that ownership does not flap). Everything starts with seat 0. Both copies run the same code and send only the records of NPCs they own.
- Record per NPC: stable id (FNV hash of the instance name), position, yaw, speed, flags (defeated, dead, weapon state), health (in a spare field), animation hint. Sent on the second channel (`N|`), chunked and reassembled.
- The mirror has collision off, is placed every frame, gets its health applied every 400 ms and its weapon sockets synced every 700 ms (melee weapon / bow, holster <-> hand follows the owner).
- Both players can fight: whoever is nearer owns the NPC and takes the hits; health and death follow the owner on the mirror.
- The AI controller of a mirrored NPC stays possessed. Unpossessing it crashed the game's perception code (an earlier attempt), so `Controller` is left alone.
- World change (loading a save) resets all state; bone-driven bodies are created only when the new world is 8 s old.
- Actors whose calls fault (the engine streamed them out while their pointer still looked valid) are forgotten instead of being touched again; this removed a storm of thousands of caught exceptions.
- Classification of NPC classes uses a hashed cache that is large enough for the thousands of classes the game has (an earlier, too small table found no NPCs at all).

## 3. Knocked-out and dead NPCs (bone-driven bodies)

Problem: a knocked-out NPC lay correctly on the host but was shown standing, T-posed or twisted on the other copy; his sword, bow and quiver floated above him; textures were "torn" when a player came close.

What was tried and rejected: playing the knock-out animation clip on the mirror (`PlayAnimation` single-node gives a T-pose for the additive `FA_*` clips and crashed in `GothicAnimationComponent`); `SetLeaderPoseComponent` (crashed the game).

What works now:

- For **defeated or dead** NPCs only, the mirror gets a `PoseableMeshComponent` with the NPC's own skinned asset, attached to the original mesh (which is hidden, with tick, physics and collision off). The owner sends the **real component-space bone transforms** (sparse list of bone scales included), and the mirror applies them exactly: `T_i * T_parent^-1 * C_parent` (UE multiplication order), parents resolved with `GetParentBone`; `ik_*` bones and bones that only matter in close-ups are left in the reference pose.
- Items (sword, bow, quiver, ...) are re-parented from the original mesh to the poseable mesh, so they lie with the body.
- LOD is forced, and `BFGTickOptimizerSystem::SetTickOptimizationRuntime_Enabled(actor, false)` is called for these actors; without it the game's own tick optimizer crashed (`0xd50`).
- Standing and sitting NPCs stay on the normal path (position + the owner's real animation); the bone-driven path made sitting NPCs' heads and arms stretch, so it is not used for them.
- Switches in `native/build/`: `npc_off.txt`, `npc_nobones.txt`, `npc_skip.txt` (names to leave alone), `npc_unpossess.txt` (old behaviour, for experiments).
- Crashes that came with it: loading a save while a clip played (fixed by the world-change reset), the `0xd50` tick-optimizer crash (fixed as above), crashes with the UE4SS loader in the stack (UE4SS is disabled in the test copy by renaming `dwmapi.dll`).

## 4. Network layer

- UDP, loopback in tests. Packet types: `P|` (position, rotation, speed, action, crouch, ...), `B|` (full-skeleton pose of the puppet), `N|` (NPC channel), `S|` (story / quests / items / chests).
- Large blobs are chunked (1400-byte payloads, header: tag, `|`, chunk index, chunk count, blob sequence byte).
- **Robust reassembly (`BlobRing`):** up to four blobs in flight per channel, chunks may arrive in any order, duplicates are ignored, an older blob is never delivered after a newer one, an incomplete blob is dropped for a newer one. The sequence byte is per channel.
- **Network impairment proxy:** `tools/tests/netproxy.py` sits between the two copies (`native/build/net_proxy.txt` makes both send to the proxy ports) and applies packet loss, delay, jitter (reordering) and duplicates.
  - 10 % loss, 150 ms delay: suite passes.
  - 25 % loss, 300 ms delay with jitter: suite passes.
  - Reports: `docs/reports/net_loss10_delay150.md`, `docs/reports/net_loss25_delay300.md`.
- Per-channel cost log: every 10 s the core logs the average / maximum cost of each module per frame.

## 5. Automated tests and tools

All of these run against two live game copies, no human input.

| Tool | Purpose |
|---|---|
| `tools/harness_start.ps1` / `harness.ps1 stop` | start / stop both copies (seat 0 host, seat 1 guest) without CouchLink; autoload takes them into the newest save |
| `tools/winshot.ps1`, `tools/wininput.ps1`, `tools/realclick.ps1` | window screenshot (works for covered windows via `PrintWindow`), input to a window, bring a window to the front (the game reads input only while it has focus) |
| `tools/test_ko.ps1` | a hero fights an NPC with real input actions until it is knocked out; both windows are photographed |
| `tools/tests/run_all.ps1` | the full suite, 20 checks: boot, NPC sync by numbers, knock-out, ownership takeover, health and death, weapon state, two quick loads, fps, crashes; report in `docs/reports/last_run.md`; optional `-Net` scenarios with the impairment proxy |
| `tools/tests/test_owner_fuzz.ps1` | ownership fuzz test: heroes are teleported to random NPCs many times (absolute coordinates just above the NPC, rescue of a hero that fell through unloaded ground); afterwards both copies must agree on every owner, no ownership change in a quiet period, positions and health match, nothing in our code faulted |
| `tools/tests/test_story.ps1` | story flag and quest state sync, both directions (6 checks) |
| `tools/tests/test_items.ps1` | world item pickup sync, both directions (8 checks); the test destroys an item next to the hero, which is what a pickup does to the actor |
| `tools/tests/test_chests.ps1` | chest emptied-state sync, both directions (6 checks) |
| `tools/diff_npcs.ps1` | host vs guest NPC positions, defeated flags and health as numbers (skips duplicates, actors at the world origin, NPCs not loaded in one copy) |
| `tools/logq.ps1` | query the log of the newest run: `-Summary`, `-Crashes`, `-Seat N`, `-Tag T`, `-Grep` |
| `tools/dev.ps1 probe "<cmd>"` | run commands inside the live game(s): `findall`, `class`, `members`, `get`, `set`, `call`, `ioscan`, ... |

Things the tests taught (and which are now handled in the scripts): a vacuous "positions are equal" check passed while nothing was synced (a "guest receives and mirrors" check was added); the camera inside the puppet's leg; heroes teleported into rocks or falling through unloaded ground; a hash/table overflow that hid NPCs; PowerShell quirks (`$home` is read-only, text passed through tools loses one level of backslashes, unquoted paths with spaces).

Known test weakness: the story, items and chest tests assume the heroes are near their start position and that the world around is loaded. Run back to back, each leaves the heroes somewhere else and the next test can fail for that reason. Run them after a fresh start or add a "heroes back to the start" step.

## 6. Startup speed and auto-continue

- Injection waits shortened: the second seat no longer waits extra; a 13 s settle time is the minimum (at 8 s the engine has not created its objects yet and the DLL never hooks). The hook retry now refreshes the object count.
- **Auto-continue:** `native/build/autoload.txt` (`wait=`, fractional seconds allowed, default 3.5) makes each copy press "Continue" in the main menu and skip the "press any key" screen, so a restarted game is back in the newest save without a click.
- The `g_nmods` counter must equal the number of modules (forgetting it once left the probe module, and with it auto-continue, unloaded).

## 7. Puppet: bow, arrows, equipment

- The bow is shown on the puppet (spawned with the hero as owner; spawning without an owner crashed in `FinishSpawningActor`).
- The nocked arrow is mapped from the hero's `arrow` socket to `weapon_r` on the puppet (the original socket hangs on an undriven IK bone).
- A fake arrow flight (`shot_tick` / `fl_launch`, test trigger `shoot_test.txt`) exists, but the arrow is not visible in flight. Postponed.
- The missing equipment / quick-slot bar in the second copy turned out to be GPU memory pressure (two copies on an 8 GB card).

## 8. Crashes found and what was done

| Crash | Cause | Status |
|---|---|---|
| `0xd50` near the puppet / mirrored NPCs | game's `BFGTickOptimizerSystem` ticks a registered actor | fixed: optimizer disabled for those actors |
| Perception code after `UnPossess` of an NPC controller | AI needs a controller | fixed: controller stays possessed |
| `SetLeaderPoseComponent` | engine crash | removed |
| `PlayAnimation` single-node on NPC mesh | T-pose and `GothicAnimationComponent` crash | removed |
| Quick-load while a clip plays | stale actors after world change | fixed: world-change reset, 8 s delay |
| Actors streamed out while pointers looked valid | thousands of caught faults | fixed: forget faulting actors |
| `0x200` at `exe+0x5be3977` (fmod) | ambient bird audio emitters on the stack, game-internal | mitigated by removing the birds, unverified |
| `Server_Debug_EmptyInventory` null read | no server authority | caught by the guard, function no longer used |

## 9. Mistakes made and reverted

Kept here on purpose so they are not repeated.

- A "performance profile" that changed `sg.*` quality groups at runtime degraded the picture and changed the saved settings file (it lives in the per-user game config, shared with the real installation). Removed. If the in-game quality looks lower than before, check the graphics menu.
- A frame-rate cap for the inactive window hurt the active one. Removed completely.
- Too many things at once ("1 fix becomes 5 fixes") led to a dead end on 2026-10-31; the work was restarted with automated tests first, which is why the test tooling above is so large.
- A "god mode" for local testing exists only as an untracked local file (`native/local_god.inc`, `native/build/god.txt`, both git-ignored) and did not demonstrably work.

## 10. Not done / not verified

- **Real two-PC test over the internet / LAN.** Everything so far ran on one PC through loopback.
- Visually verified: journal entries, notifications and rewards on the guest when a quest changes; both heroes getting a reward only once; a dialogue running on one copy while the other player stands nearby.
- Partial looting of chests, loot of bodies, items dropped by a player, trading.
- Arrows in flight; facial animation of the puppet.
- Transition frames of falling and getting up for NPCs.
- Whether the bird removal really prevents the `0x200` crash; a fuzz run with the NPC module off to see if that crash is the game's own.
- A long soak test (30-60 minutes) for leaks; a full suite run after the last module changes (last full run was before the story / item / chest modules).
- Memory: two copies of the game use nearly all of 32 GB of RAM; the last long test run froze the PC. Close other programs, or run one copy per PC (the real use case).
- Game updates change the fixed addresses; a new reconnaissance pass is needed after each update.

## 11. Credits

- **[CouchLink](https://github.com/cranebeaker/couchlink)** made the two-copies-on-one-PC testing practical: one game instance per seat on its own monitor with its own input. The recipe in `tools/couchlink/` starts the seats and the helper that injects the DLL; the whole co-op development loop (and most of the testing above) relied on it. Thank you to its author.
- The coop-anything write-up in `docs/coop-anything-writeup.md` describes the general approach this project borrowed.
- Gothic and Gothic 1 Remake belong to their owners. This is a fan project and contains none of their assets.

## Addendum (2026-10-31, later): test tooling and chest recon

- `tools/tests/lib.ps1` + `tools/tests/run_sync.ps1`: the story, item and chest tests can now run back to back. The first test after a fresh start records both heroes' positions (`native/build/test_spawn.txt`, deleted by `harness_start.ps1`), every test puts the heroes back before and after. `run_sync.ps1 -Start` restarts both copies first. Last full run: story 6/6 and chests 6/6; the item test had 7/8 and was then changed (it now checks that the *specific* destroyed item is reported and waits up to 30 s for the other copy) and **has not been re-run since the change**.
- `tools/harness_start.ps1 -Seats 0` starts only the host copy: enough for probing the game and half the memory. Two copies together fill almost all of 32 GB RAM; a PC freeze and a "cannot create processes" state were seen during long test runs, so keep runs short and stop the games afterwards.
- New probe commands: `contdump`, `peek <addr> [bytes]` (raw memory with object names), `structinfo <ScriptStruct>` (members of a USTRUCT).
- **Chest layout findings (for partial looting, not implemented):** a container's `m_Inventory` (at offset 64 of `DataModule_Container`) is a `ReplicatedInventoryMap`: a fast-array-serializer header, `m_Keys` (TArray at +16, 16-byte keys) and `m_Values` (280-byte struct that contains sparse-array / hash-set internals and an array of `ItemVirtualData` entries: `m_Id`, `m_InventoryType`, `m_SlotData` = `ItemSlot{m_ItemDefinition class pointer, m_ItemCount}`, `m_Payload` 136 bytes, `m_TimeLastAdded`). The item arrays are not plain arrays of items, so reading single items from memory needs a full decode of that map. The game's own `DataModule_Container` functions come in `Server_*` / `Multicast_*` pairs (`Server_MoveItemFromActorToOtherActor`, `Server_AddAllItemsFromContainer`, `Server_PickWorldItem`, `Multicast_*`); the core has no ProcessEvent observer (it only swaps the `GameEngine` tick vtable slot), so those calls cannot yet be intercepted and replayed on the other copy.
- **Partial chest looting and loot of bodies are therefore still not synced.** Two ways forward: a ProcessEvent observer in the core (also the right tool for dialogues and trading), or a full decode of the inventory map.

## Addendum 2: function observer (core API v11, `coopdll_52`)

- **Idea:** the native body of a `UFunction` is a pointer inside the UFunction object (offset `+0xd8` in this build, found by scanning a known function for a pointer into the exe image). The core swaps it for a small thunk that records the call (object + the parameter buffer, taken from `FFrame::Locals`, which is valid when the call came through `ProcessEvent`) and then calls the original body. No code is patched. Up to 24 functions; a function whose body address is shared with another one (script / blueprint thunk) is refused. API: `observe_fn(outer, fn)` returns a slot, `obs_pop(...)` drains the recorded calls on the game thread.
- The story module is now an "always" module (it also runs with a single copy) and observes the seven `DataModule_Container` functions that move items: `Server_MoveItemTo`, `Server_MoveItemFromActorToOtherActor`, `Server_AddAllItemsFromContainer`, `Server_GetItemsFromContainerInv`, `Server_PickWorldItem`, `Server_ConsumeItem`, `Server_AddNewItem`. Every call is logged as `S obs <function> on <object>: <parameter bytes>` followed by the names of the objects the parameters point to.
- **Verified:** all seven hooks install, the game keeps running, and a call made through the probe (`Server_ConsumeItem` with a dummy id) shows up in the log with its exact parameters.
- **Not done:** (1) a real loot by a player was not observed yet (injected input did not open the chest UI: the chest was probably not targeted); play once with the log open and read the `S obs` lines to learn which of the seven functions the UI really calls and whether the parameters arrive in a buffer; (2) the replay on the other copy (which item ids, how to remove them from the chest without giving them to the other hero) is not written; (3) `Server_ConsumeItem` and `Server_EmptyInventory`-style calls made from the probe fault without server authority, so a replay must probably write the container map directly or call the `Multicast_*` variants.
- Probe commands added: `fninfo <Outer> <Function>` (UFunction, native body RVA, parameters), `structinfo`, `peek`, `contdump`.

## Addendum 3: what the game calls when a player takes items from a chest (observed live)

Taking an item (click on the slot or "Take all") makes the game call, on the **chest's** `DataModule_Container` module, once per item stack:
1. `Server_MoveItemFromActorToOtherActor(Actor = chest, OtherActor = hero, ItemPos = n, InventorySlot = 1, Amount = -1, targetInventorySlot = 0)`
2. `Server_ConsumeItem(InventoryType = 1, ID = n, ItemAmount = stack size)`

The parameters arrive in the `ProcessEvent` parameter buffer, so the observer sees them. "Take all" is simply this pair repeated for ids n = 3, 2, 1, ... The ids of a chest's items are small numbers that count from 0 (the same state loaded in both copies gives the same ids).

**Replay (written, NOT verified):** the story module records every `Server_ConsumeItem` the game makes on a tracked chest's module and sends `(chest key, type, id, amount)` on the story channel (acknowledged and de-duplicated by a loot id); the other copy calls `Server_ConsumeItem` with the same parameters on the same chest and does not echo it back (a short suppression list). `tools/tests/test_loot.ps1` exercises the pipeline with an invented item id; in the one run seen so far the take was noticed on the first copy but the replay on the second copy reported `failed` (the call returned 0), and the run then hung and was stopped by hand. Not known: whether the call fails because the invented id does not exist in that chest or because it needs authority; whether the chest then really shows one item less. The test should use real ids (read them from a take made by hand: the `S obs` lines show them).

A chest UI that opened with empty panels and "Label" placeholders was seen in one copy during that run; the most likely cause is test interference (invented item ids, teleports while the window was open), not verified.

## Addendum 4: memory and CPU overload during two-copy test runs (fixed in part)

- **Symptom:** several times the PC went to ~100 % CPU and ~99 % RAM and froze during long runs with two game copies.
- **Cause found:** the story module cached only 300 classes for its object scan while the game has thousands, so for most objects the class name and property offsets were recomputed every second, allocating memory; a copy grew from 9 GB to 14.5 GB as soon as the second copy connected and the scan started. Fixed: all classes are cached in a 32768-entry hash table (`cls_has_item`). Idle one copy: flat at ~9 GB working set. Two copies after the fix: ~6-8 GB of RAM stays available (was 0.7 GB). A slow growth (about 0.4 GB per minute for both copies together) is still there and not explained.
- **A second cause is the game's own streaming:** a test that teleports both heroes to a far place makes both copies load new world cells (several GB each); the item test hit the safety limit again that way.
- **Safety net:** `tools/watchdog.ps1` (started by `harness_start.ps1`): game processes at BelowNormal priority; stops the games and the test scripts when available RAM (free + reclaimable cache) < 800 MB, CPU >= 97 % for 25 s, or the run lasts longer than 25 min; reason in `native/build/watchdog.log`.
- `harness_start.ps1 -Lite`: command-line-only settings (`r.Streaming.PoolSize 200`, `r.MipMapLODBias 3`, `r.ScreenPercentage 50`, ...), about 1.5 GB less per copy; nothing is saved to the user's settings. `-Seats 0` starts only the host copy. The second copy is started only after the first is in the game (two loads at once need ~13 GB each); the second copy gets `-NoLoadGap` so that autoload does not wait for the first copy a second time. **Do not start the game with `-nosound`: `fmodstudio.dll` crashes a few seconds after the start.**
- `scan_fast.txt` in `native/build/` makes the item scan 80000 objects per second instead of 30000 (tests only).
- **Still open:** the item and chest tests teleport heroes far away; with two copies that can exhaust memory. They should pick items and chests that are already loaded near the heroes instead of teleporting.

## Addendum 5: known difference between the two copies (NPC state)

A mirrored NPC keeps its own AI running (its controller must stay possessed). The copy that owns the NPC sends position, yaw, speed, health, weapon state; what the NPC does with its hands is not sent. So one copy can show an NPC walking while the other shows the same NPC carrying a crate (its local routine). Possible fixes: send the playing montage and the carried item; quiet the mirror's AI; or let the host simulate all AI and the guest only display.

## Addendum 6: the real memory leak (core), NPC animation sync, scan cost

- **Core leak found and fixed (`coopdll_54`).** `FName::ToString` allocates the string in the engine's allocator and the old `fname_str` never freed it (and the function does not reuse a string passed in, so reusing one `FString` did not help either). Every `obj_name` / `fname_to_str` call leaked ~100 bytes; the object scans of the modules make millions of calls. Measured by switching modules off one by one: all modules on +1.2 GB/min for two copies, story off +0.74, story+npc off +0.27, everything off +0.03 GB/min. Fix: every distinct FName (comparison index + number, 8 bytes) is converted once and kept in a hash table with a text arena (2M slots, 96 MB); repeated calls allocate nothing and are faster. With the fix the two copies stay flat (19.3 -> 19.05 GB over 3 minutes, all modules on).
- The function-pointer cache of the core was limited to 64 entries; with five modules it overflowed and later `call_fn` calls silently failed. Now 512.
- **Story module scan cost:** the object scan ran 30000 objects once per second (200-800 ms hitches). It is now time-budgeted per frame (1 ms; 6 ms with `scan_fast.txt`, which tests create and must delete), and far items are not re-examined for 12 s. The class cache is a 32768-entry hash table (the old 300-entry cache recomputed names for most objects).
- **A stale `native/build/npc_off.txt`** (left over from an interrupted experiment) had switched the NPC module off in every run for a long time; removed. Reminder: the switch files in `native/build/` (`npc_off.txt`, `story_off.txt`, `pose_off.txt`, `scan_fast.txt`, ...) must not be left behind.
- **NPC animation sync (npc module).** A mirrored NPC kept running its own AI, so it showed other idle actions than the owner (one copy: guard with crossed arms, the other: another idle montage; one copy carries a crate, the other does not). Now the owner sends the name and package of its body montage; the mirror plays the same montage through its own `AnimInstance` (`Montage_Play`, other montages stopped) and every 700 ms checks that exactly that montage is playing, stopping its own body montages when the owner plays none. Face / voice montages (run-time `AnimMontage_<n>`) are left alone. All montages of an AnimInstance are read from its `MontageInstances` array (at `+0x88`, found with the new probe command `miscan`), because `GetCurrentActiveMontage` often returns a facial montage that hides the body one. Verified with the probe command `npcanim` (prints each NPC's body montages): 10 of 10 NPCs near both heroes show the same montage in both copies. Not verified by eye: smoothness of the blend, NPCs that carry items (the carried item state is not synced; only the montage is), montages that need parameters from the owner's AI.
- New probe commands: `npcanim`, `miscan`.
- Sync test run after the changes: story 6/6, items 8/8, loot 10/10, chests 4/6 (guest -> host emptying not noticed in that run; not investigated).

## Addendum 7 (end of session 2026-10-31)
- Chest test: uses the new one-call probe `chestlist` and waits until both copies track the chest; the last full run of the four sync tests was interrupted before it finished (the watchdog's 25 minute limit stopped the games earlier; the limit is now 60 min). Last known results: story 6/6, items 8/8, loot 10/10, chests 4/6 (flaky: depends on which chest is picked and whether it is loaded in both copies).
- Not verified yet: the NPC montage sync by eye in the game; the loot replay with a take made by hand in the UI after the leak fix.

## Addendum 8: test results after the leak fix and test repairs

Last results with a clean start of both (lite) copies: story 6/6, chests 8/8, items 8/8 (run on the same games), loot 10/10 (run several times). Repaired on the way (all were test or module-noise problems, not sync bugs):
- the tests ran a process query per log line (`PidOf` inside the log filter): minutes per check; computed once now;
- variable name clash (`$pf`/`$pt` used for pids and chest pointers in the loot test);
- the item and chest tests teleported the heroes far away and waited for new world cells; they now use objects near the heroes, and for items only an item that exists in BOTH copies (items dropped by NPCs differ between the copies);
- loot pouches (`BP_Pouch_C`) are created and removed by the game all the time: they are no longer treated as pickups by the module (they produced false pickups and could remove pouches in the other copy);
- the tests looked for the log text "removed" while the module says "the other player picked it up";
- chests were looked for in new log lines only, but an already tracked chest is not logged again.
**The sync tests change the world (empty chests, take items): run `tools\tests\run_sync.ps1 -Start` (fresh start) for a trustworthy result; repeated runs on the same games drift.**
Not verified: the NPC montage sync by eye; a chest take made by hand through the UI after the leak fix; behaviour with real players over a network.

**Note:** the NPC animation sync, the loot / chest / item / story sync and the leak fix were verified only by scripts and numbers, not in the real game by a person playing. They need live testing.

## Addendum 9: loot of bodies (NPC inventories)

- An NPC's inventory is a `DataModule_Container` inside its **PlayerState** (`PlayerState.DataModuleComponent.m_DataModules`), the same class as a chest's container. The story module now also tracks characters (class with `PlayerState` and `m_CarryComponent`) within 3500 units of its hero; the key is the FNV hash of the instance name (stable and equal in both copies). A `Server_ConsumeItem` the game makes on such a module is sent and replayed on the same NPC in the other copy, exactly like a chest take (de-duplicated, acknowledged, no echo). Only loot calls are replayed for NPCs (no "emptied" detection).
- Probe commands: `npcinv <npc>`, `bodylist [radius] [max]` (NPCs that have a container module, one call).
- Test `tools\tests\test_bodyloot.ps1` (added to `run_sync.ps1`): picks the NPC nearest to the hero that exists in both copies, waits until both track it, takes item ids 1..5 through the probe until one is replayed `ok`; 10/10 on its first run. In the full run that followed, story 6/6 and items 8/8 passed; the run was then stopped by the watchdog (available RAM) before chests / loot / bodyloot finished.
- **Memory margin:** with a browser (~3 GB) and the Claude app (~2.7 GB) open, the two game copies leave almost nothing at the moment the second copy loads its save (available RAM fell to 450-610 MB, the watchdog stopped the run). Close the browser during test runs. The watchdog limit is now 600 MB. This is a property of the PC (32 GB), not a new leak: idle and under all modules the copies stay flat.
- Not verified in the real game (only scripts): body loot replay, as with everything else here.

## Addendum 10: the heroes died during the tests; clean run

- **Cause:** the loot tests take things from chests and from living NPCs in the Old Camp (guards). That counts as theft; guards attacked and killed the heroes (log: `FA_Man_S1H_...Defeated`, `PR god: health was 0.0 of 76.0`). The immortality of the local test setup (a git-ignored file, `native/local_god.inc` + `native/build/god.txt`, local to this PC only) restored the health every frame, which is too late for a hit that takes the health to zero inside one frame; it now also sets a huge maximum health (99999), so no hit can empty it before the next restore. The tests additionally send `cc Gothic.IgnorePlayerPerceptions 1` to both copies (the game's own "Invisible" cheat: NPCs ignore the player; per process, nothing saved; whether it has any effect was not verified).
- **Test readiness waits:** the story test waits until the first full sync is acknowledged in both copies, the loot test waits until the chest is loaded in both copies.
- **Montage flicker fixed:** when the mirror's own AI started another body montage next to the owner's, the old code replayed the owner's montage every 0.7 s; now only the foreign body montage is stopped.
- **Result of the last clean run** (`tools\tests\run_sync.ps1 -Start`, about 6 minutes after the start of both copies): story 6/6, items 8/8, loot 10/10, bodyloot 10/10, chests 8/8; both heroes alive at the end.
- Everything above is verified only by scripts, not in the real game by a person playing.

## Addendum 11: cutscenes (first step)

- **How the game starts a cutscene:** every cutscene is a subclass of `GothicCinematic` (`UIntroPt2Cinematic`, `UProphecyCinematic`, `UFireMagesCinematic`, ..., `UTESTCinematic`) with a LevelSequence, a teleport waypoint for the hero and story logic before / after (`SetupBeforeSequence` / `SetupAfterSequence`). Scripts start it with `UGothicCinematicManagerSubsystemScript::Get().ForceStartCinematic(<Class>)`. The manager (`GothicCinematicManagerSubsystem`) was designed for several players: it has a player list, skip requests per player and `Server_*` / `Multicast_*` functions.
- **What is done:** the story module observes `ForceStartCinematic`, `Server_OnForceStartCinematic`, `Server_OnSkipCutsceneRequest` and `StopCinematicServer` on the manager, sends the class name (start), a skip or a stop to the other copy (acknowledged, de-duplicated, no echo) and the other copy makes the same call on its own manager. Test `tools\tests\test_cine.ps1`: 4/4 (the TEST cinematic started on the host is started on the guest, no echo).
- While a cutscene really plays here (manager state != 0 and the cinematic object exists) the story module creates `native/build/cine_active.txt` and the npc module stops mirroring NPCs (they belong to the local cutscene).
- **Not known / not done:** a request made through the probe leaves the manager in state 1 and the cutscene does not actually start in my single-player test setup (the manager's player count stays 0), so playback of a real cutscene on two copies, the effect on the other hero (puppet), skipping together, story logic that runs twice (`SetupBeforeSequence` / `SetupAfterSequence` run in both copies) and NPCs' positions after the cutscene have **not been observed**; this needs a live test where a player triggers a real cutscene.

## Addendum 12: cutscenes on two copies (live)

- A real cutscene was started through the manager (`ForceStartCinematic` with `IntroPt2Cinematic`) on the host copy and **appeared on both copies** (both managers in state 3 = playing); skipping on the host (`Server_OnSkipCutsceneRequest`) skipped it on the guest too (both back to state 0). The game's own start of the new-game intro calls `Server_OnForceStartCinematic` directly, so that inner call is what is sent. `Prophecy` was started the same way and also appeared on both.
- Seen by the user: the picture was blurry and the frame rate low (the test copies run with the `-Lite` settings: half resolution, coarse textures, two copies on one PC); the camera angles of the two copies differ a little because their starts are a moment apart.
- **Crash (first copy) during the second scene:** `exe+0x5be3977`, access violation reading `0x200` (the fmod family seen before; this time a `CineCameraComponent` and the wind actor were on the stack). Just before it, our replay of `StopCinematicServer` faulted INSIDE the game (null read at `+0xf0`: the function cannot be called when no cinematic object exists). The replay now checks that a cutscene is playing before calling stop or skip. Whether that fault contributed to the later crash is not known.
- A manager left in state 1 (a request that never starts, e.g. the TEST cinematic whose assets are missing) blocks every later request; writing 0 to `m_CurrentCinematicState` / `m_RequestCinematicState` unstuck it in the test.
- Not verified: smoothness over a real network, NPC mirroring during and after a scene (it is paused while a scene plays), story logic that runs in both copies (`SetupBeforeSequence` / `SetupAfterSequence`), the second hero's puppet during a scene, other scenes.

## Addendum 13: all cutscenes played on two copies (clean restarts, at most two scenes per start of the game)

Result per scene (the scene is started on the host with the game's own call, both managers must reach "playing" with a cinematic object, then it is skipped on the starting copy and both must return to state 0; memory and the two copies are checked after each scene):
- **Pass on both copies, skip ends it on both:** IntroPt2 (the intro), Prophecy (also started from the guest side), Uriziel, SleeperTempleOpening, FireDemonBloodDoor, OldMineExplosion, UluMuluPresentation.
- **Extro and ExtroMagic** play on both copies; they are the last scenes of the game (the credits follow), so the manager does not return to state 0 after a skip: that is expected, not a sync problem (user's remark); the test treats it as informational.
- **NyrasFocusStone** does not start in this save on either copy (65 s, state never changes): the scene probably needs story conditions this save does not have. Skipped by the user's decision.
- **FireMages** is too heavy for two copies: the world data it loads (about 4.5 GB per copy) took the available RAM of the PC (32 GB, with the Claude app and Windows) from 7.7 GB to under 1 GB; the memory watcher stopped the games twice. It was not played on two copies. A scene by scene run after a restart is the only way; not done.
- **Stability:** no crash at the audio predicate (`exe+0x5be3977`) in any of the runs after the guard patch (`coopdll_55`; its self test passed in both copies: NULL view -> false, zero view -> normal path). One unexplained crash of a copy (`0x1d0`, reported by the user, no log kept) happened during a restart of a batch. Heavy scenes raise the memory of both copies by 1-4 GB each; two copies must be restarted after every second scene.
- **Third player in the shot:** the puppet of the other player was visible in cutscenes; it and its items are now hidden while a cutscene plays on the copy (`cine_active.txt` written by the story module). Not verified by eye.
- Not verified: quality of the shots (the test copies run with half resolution and coarse textures), story logic that runs in both copies, NPC positions after a scene, smoothness over a real network. Pictures of both windows for every scene: `docs/img/cutscenes/`.

**Open problems reported after the cutscene runs:** (1) the chapter start banner is not synchronized: the second player does not get it; (2) after the UluMulu cutscene the players fell through the textures and kept falling (cause not known; see STATUS.md). Both are recorded, neither is fixed.
