# Known bugs and gaps (private notes; "not verified in a real game" unless stated)

> **Исторический документ.** Описывает переносную раскладку (
ative\build + start_net.ps1) до установщика.
> Актуальный поток — docs/HOW_TO_PLAY.md (установщик, ярлык «Gothic 1 Remake Co-op»).



## FIXED — the trader's stock never matched between the copies (verified on the pair 2026-11-07 15:00)

Was: a purchase on one copy left the item with the trader on the other one. Four separate faults, in the order they were
found and fixed:

1. the fingerprint event (type 30) resolved the merchant through `m_LastTraderConfig`, which is only set on the copy that
   traded - on the receiver it is null, so **every count was dropped silently**. Both paths now share `trade_config_at()`
   (m_InstancedTraders by position, or the position resolved by name).
2. the 8-bit class fingerprint can repeat inside one list (24 items make a collision likely), and the match always took
   the **first** entry — one item's count was written twice onto its neighbour. Matching now skips entries already used.
3. a bought-out item is **not deleted** from the map: the game blanks its class and keeps the slot (the buyer's dump
   showed three entries with no name instead of three items). Counts alone cannot say "this one is gone", so entries the
   sender does not list at all are taken off the shelf (count 0) on the receiver.
4. nothing named the items, so every mismatch was a guess. The sender logs `S stock sent: name#fp ...` and the receiver
   `S stock here: ...`, one line each per change, with the fingerprint of every entry.

Verified on the pair: a purchase in each direction, and entries disappearing on both copies afterwards. Two known limits:

* an **open** trade window does not repaint itself — the window reads `GothicTraderPayload`, a snapshot the game rebuilds
  only when the window is opened (no UFunction exists for a refresh; see `docs/NOTES.md`). Reopening shows the right
  stock. Decision on 2026-11-07: leave it as is, do not touch the UI.
* entries that exist only on the sender cannot be created on the receiver (a count is written, no new row).

## OPEN — the guest rewrites the clock every 5 s and its time stands still (2026-11-07 14:03, after 0.4.2.71)

Seen on the guest right after 0.4.2.71 changed the clock to `GameTimeSubsystem::CurrentGameTime`:

```
14:02:36  S time: clock set to 08:58 (ok)
14:02:41  S time: clock set to 08:58 (ok)
14:02:46  S time: clock set to 08:58 (ok)
14:02:51  S time: clock set to 08:58 (ok)
14:03:05  S time: clock set to 08:58 (ok)
14:03:06  S time: clock set to 08:58 (ok)
```

90 of these in 3000 log lines - roughly one every five seconds - always to the same value, so the guest's clock is
pinned at 08:58 and never advances. The write happens because the comparison still sees a difference after writing:
either the read returns something that the write does not affect (a different field, or a copy taken before the write
lands), or the value is re-read before it settles.

What to check first: log the value that is read *right after* a write (same call site, next line). If it equals what was
written, the comparison is comparing seconds against something else (a tick count, or a different time base), and the
15 second window is meaningless. If it does not equal, the write goes to a different field than the read.

Until this is fixed the guest's time of day is frozen and time-of-day dependent behaviour (sleep, schedules, lighting)
cannot be trusted on that copy.



## OPEN — the trade code costs 40-49 ms every 2-3 s (live co-op, 2026-11-07 04:20, after 0.4.2.54)

Still true after the stock fix (re-measured 2026-11-07 15:30, story build `200ca3af`): `S slowfn: trade_poll 27-35 ms`
every 3 s, on a loaded world with **no trade open and the friend disconnected** (`link lost`). The comment in
`trade_task_alive` says the scan is capped at one per three seconds "so the cost stays around 1%", and that is exactly the
cost measured — so this is the accepted trade-off, not a regression.

**Updated 2026-11-07 16:42** (build `2f557975` + npc `FF57608E`, peer connected, 8 minutes of play): not a single
`trade_poll` line above 6 ms. The scan only happens when no trader config is cached — after any trade the manager answers
from `m_LastTraderConfig` and `trade_task_alive` returns immediately. So the cost is a **cold-start** cost: it appears in
the main menu, right after a world load, and with the friend offline. Two things would make it free:

* return before the scan when there is no peer at all (`!a->have_remote`): **done on 2026-11-07** — `trade_poll` and
  `trade_lock_watch` now return early, which is the case that was measured in the menu;
* the scan itself walks every object (500k) looking for an `AbilityTask_TradeWith`; the CDO class is already cached, so
  only a cheaper index would remove the last of it (it only bites before the first trade).

**Fixed on the receiver side, 2026-11-07 16:55** (`e92071fb`): the guest never gets a `m_LastTraderConfig`, so its scan
never became a cold-start one — measured 281 lines of `trade_poll 23-26 ms` in its tail, every 3 s, forever. The empty
scans now back off to one per 10 s and anything trade-related (a stock message, a notice) resets the fast path. Measured
after the deploy: one `trade_lock_watch 21.7-22.0 ms` every 10 s instead of every 3 s, about 0.22% of a frame instead of
0.8%. Trade detection is still inside 3 s for the copy that is trading.

What that trade-off costs, to be honest about it: the copy that opens a trade after a long idle period can notice its own
window up to 10 s late, so a purchase made in the first seconds of the window may reach the other copy only on the next
stock change. The other direction is covered by the notice the trading copy sends, which resets the receiver's fast scan.
If that ever bites, the number to change is the `10000` in `trade_task_alive` (`native\story_module.c`), not the gate.

Measured on the guest right after 0.4.2.54 was installed, with the game simply standing still:

```
04:20:51  S slowfn: trade_poll 46.9 ms
04:20:53  S slowfn: trade_lock_watch 41.6 ms
04:20:54  S slowfn: trade_poll 43.8 ms
04:20:57  S slowfn: trade_poll 48.9 ms
04:20:59  S slowfn: trade_lock_watch 39.6 ms
04:21:00  S slowfn: trade_poll 45.2 ms
```

`trade_poll` runs every 1.5 s and `trade_lock_watch` every 2 s, and each call costs 40-49 ms - about three frames at
60 fps, i.e. a visible hitch every couple of seconds even when nobody is trading.

Likely causes, in the order worth checking:

1. **`trade_state()` calls `trade_dump()` on every poll** (added by 0.4.2.54 to compare the two copies' item lists).
   `trade_dump` -> `trade_sorted` -> `obj_name` for every item in the trader's list, and `obj_name` goes through FName
   resolution. This is the newest code, and the symptom appeared with it.
2. **`trade_manager()` / `trade_config_from()` / `trade_task_alive()`** are called from both paths; if any of them walks
   the object array (13k+ objects) instead of using a cached pointer, that alone explains tens of milliseconds.

What to do: keep the dump behind a switch (`story_trade_dump.txt`), cache the trader manager/config pointers,
and make `trade_lock_watch` answer "is a trade task alive" without a full scan.



Status words: OPEN = not fixed, WORKAROUND = a way around exists, SKELETON = works once or twice, needs repeats in varied conditions, FIXED? = looks fixed by user report, tested little.

## FIXED — the mirrored mesh was turned 90 degrees (2026-11-07, 0.4.2.29/30, verified in play)

Found while watching a real two-PC session (host on the GOG machine, guest over Radmin). The diagnostic line repeats
twice a second while the other player stands still:

```
N diag guest mirror f5eb5f22: want yaw 97, actor yaw 97, mesh yaw 7, control yaw 97, speed 0, montages 3 (A_Man_IdlePose_Montage)
```

`want`, `actor` and `control` all agree (97), and `mesh` is 7 - a stable 90 degree difference, not a one-frame glitch.
So the puppet actor is placed and rotated correctly and the *mesh component* is turned against it, which is exactly the
kind of thing that looks "wrong" without being obviously broken.

Context worth keeping:

* the same line shows `montages 3` vs `montages 1` alternating between samples - the montage count also flickers;
* the session itself was healthy at that moment: `N3 remote at ... shown ok=1 (seq=5839)`, `P received pose #5401 (425
  bones, interval 82 ms)`, `N seat 0: 4 characters known, simulating 1, mirroring 3`, clock applied (`14:10` vs `14:11`);
* the mesh yaw is the value the npc module computes for the mirror; the 90 degrees smells like a coordinate-system
  convention (the mesh's own forward axis versus the actor's) rather than a per-frame bug.

Two things to do next: (1) make the diagnostic print only when the mismatch exceeds a threshold and only when it
changes - it currently writes twice a second into a 200 MB log; (2) decide whether to correct the mesh yaw by the
constant offset or to fix the convention where it is computed.

## Fixed (2026-11-07, found on a second PC with a GOG install)

### The mod runs but sees no properties (the whole reflection dead)

Symptom: on the guest PC the core was injected (`LoadLibrary returned 0x...`), the modules loaded, the black box wrote
history, `findall` worked and class names resolved - but `members` printed `0 props` for every object, the menu module
reported `MENU: no anchor button in the main menu (class 'W_MainMenu_C')` and no Co-op button appeared.

Cause: `detect_ffield_layout` guessed the property layout from "plausible looking" FNames and ran once, early. On this
machine it accepted a wrong chain (the class's `SuperStruct`) and never tried again. The log line `detect: no first
property` hid the two real problems: the offset was wrong *and* the engine had not filled the class yet.

Fix (0.4.2): accept a layout only when it shows at least two properties every Actor must have (`Tags`, `bHidden`,
`Instigator`, `Owner`, `RootComponent`, ...), try several `ChildProperties` offsets and `(Next, Name)` pairs, and retry
the detection every 2 s until it succeeds. On that PC it resolved to `ChildProperties +0x50, next +0x18, name +0x20,
Offset_Internal +0x44` (the Steam build uses different values), and both buttons appeared.

Lesson worth remembering: **an empty property list is not "the object has no properties", it is "the layout is wrong"**.
Any new symptom of the form "the mod does nothing on this machine" should start with `probe members` on a known CDO.

## Fixed (2026-11-05, found by the parity suite, not by eye)

- **FIXED: NPC health never reached the guest.** `npc_module` kept health sets in a cache capped at 600 entries; the world has thousands, so `health_set()` returned NULL for most NPCs, `npc_health()` returned -1, the record carried "unknown" and the mirror never touched health at all. Cap raised to 8192. Verified by the `npc_health` scenario (owner 270 → mirror 270).
- **FIXED: health was sent as one byte.** `uint8_t pad` clamped every value above 254, so the guest's health bar lied for every NPC with real health (people 320, Templar 444). Field widened to `uint16_t` (record 24 → 25 bytes). After the fix the whole NPC set matches between the copies again.
- **FIXED / not a bug: the puppet pose.** Measured across copies: worst bone deviation 0.4 units.

## Automated checks (run after any change)

- `tools\parity_suite.ps1` — passive gate: two copies alive, state parity (puppet, hero↔puppet position, camera, chests, NPC set within 3000 units with health and defeated, hero inventory, UI widget visibility, pose bones), fps, exceptions, corpse-pose indicator from the log. Writes `docs/reports/parity_<stamp>.md`, exit code 1 on any failure.
- `tools\scenarios.ps1` — action scenarios: `npc_health` (writes health on the owner, checks the mirror, restores) and `soak` (60 s of parity samples + exceptions + memory).

## Loading and UI
- **FIXED 2026-11-05** (verified on 3 load cycles, both directions; full write-up in docs/BUG_UI_AFTER_LOAD.md): the load was applied TWICE on the receiving copy + caught access violations in the equip module during the load + a transparent saved-games page. All three fixed. Previous note: after F9 both copies lose Esc, dialogues and pause; `<MISSING STRING TABLE ENTRY>`, placeholder choice texts ("Write your choice text here"), only movement works. Tried without success: switching the game language ru -> en -> ru (`langtoggle` test aid); `cam_fix` (forcing camera behaviour 16) is now OFF by default (needs `cam_fix_on.txt`; it fired constantly, value 2 may be normal). Not yet done: a control run of the plain game without our core (F5, F9, then Esc/dialogue) to learn whether the game itself breaks after the 1.2 update. A forum report (other users, after a patch) links the string-table message to a non-English game language.
- OPEN: white veil / `<MISSING STRING TABLE ENTRY>` after some loads. Manual cure: swing a pickaxe. Seen again after an F9 load from the death screen (host).
  **Measured 2026-11-05:** `m_CurrentBehaviour` = **2 on both copies in a fully healthy state** (heroes, puppet, chests, NPC health, UI all in parity). So "stuck at 2" is NOT the cause — 2 is the normal value. The `cam_fix` that forced 16 was fighting normal behaviour and is correctly off by default. Look elsewhere: the parked F9/UI-loss entry above is the same symptom and points at the game itself after 1.2.
- OPEN / WORKAROUND: the death screen of a copy killed by our shared-death call has no clickable buttons; F9 while dead loads the last save (synced). Labels and the "Revives left: x" line are fixed.
- WORKAROUND: loading a save is risky in some situations (UI can break, saves keep a bad state). Keep clean save backups; do not load during tests without need.
- OPEN: item pickup shows "+1" and then "+N" (two notifications).

### An NPC does not attack the guest (2026-11-07, FIXED and verified)

**Verified in play after 0.4.2.31:** the molerat walked up to the guest and attacked him, so the cause was the movement
component staying disabled after ownership moved back (see the fix in the 0.4.2.31 entry of `docs/CHANGELOG.md`).
Kept here as the record of how it was found.

Reported: *"the molerat does not attack the guest."*

The ownership model is working as designed - the guest's log says `N seat 0: 1 characters known, simulating 1,
mirroring 0` while the host mirrors the same NPC, so the guest's copy owns and runs the creature's AI. The question is
therefore not "who simulates it" but why the AI does not act on the guest's hero.

Two possibilities, to be separated with one test:

1. **the AI does not perceive the hero on that copy.** The mirrors keep their controller possessed (unpossess is only
   used with `npc_unpossess.txt`), so perception should run; but the creature was seen with `speed 0, flags 0` and no
   attack, which looks like an idle AI rather than a missed hit;
2. **the AI attacks and the damage does not travel.** Then the log would show `N dmg` from the guest to the host; it
   does not.

What separates them: stand the guest right next to the creature and watch whether it walks up to him (1) or stays put
(2). Then the owner's hero standing next to it as a control.

### A corpse ends up in a different place on the two copies (2026-11-07, open, decision needed)

Reported: *"the dead beetle's corpse is in a different place on the guest and on the host."*

Death itself is synchronised - the kill travels (host log `N dmg: ... (10 -> 0)` and `kill effect ... ok`), the owner
flag moves with the death, and both copies release the body (`N death: mirror ... released (ragdoll ok/ok)`). What
diverges is the **ragdoll**: once the mirror is released, the game owns that corpse on each side and simulates the
fall independently (different collision, different step times), so the two bodies land differently. The module stops
driving a corpse once it is really dead (`if (m->nkill >= 1) continue;`).

Three ways out, none free:

1. **leave it** - correct physics, cosmetic difference of a few tens of centimetres, sometimes lying on the other side;
2. **stiff corpse** - stop the mirror's physics at death and place the body at the owner's final transform: the
   positions match, but the corpse can look frozen and may hang over a slope;
3. **bone-sync the corpse** - send the dead NPC's skeleton like the player's pose: correct visually, expensive, and it
   still fights physics on uneven ground.

Where the physics starts, for whoever takes option 2: `native\npc_module.c:1068-1082` - when the owner's flag says
dead, the mirror is released and the code turns physics on explicitly (`SetSimulatePhysics` +
`SetAllBodiesSimulatePhysics`, both logged as `ragdoll ok/ok`). Option 2 is that block replaced by "leave physics off,
snap the actor to the owner's last transform"; the pose stream for a dead NPC does not exist today, so the corpse would
then freeze exactly where the owner left it.

### A sitting NPC "jumps" on the other copy (2026-11-07, FIXED in 0.4.2.27 and 0.4.2.45)

Seen in the first real two-PC session: **some animation divergence, the guest sometimes sees a seated guard hop.**
Everything else about that NPC is right - it is in the right place, it is mirrored (`N seat 0: 2 characters known,
simulating 0, mirroring 2` on the guest, `simulating 2` on the host), health and death follow the host.

Two suspects, in order of likelihood:

1. **position versus sit animation.** The guest sets the mirror's actor location from the host's data every update
   (`K2_SetActorLocation`, no sweep, teleport) while the sit montage moves the hips inside the mesh; if the host's
   z and the montage's root offset disagree by a centimetre, the body visibly bobs. The check to run: log the
   mirror's actor z and the host's z on the same tick while a guard sits, and see whether the hop correlates with a
   correction;
2. **montage replay.** The module replays the host's montage on the mirror; if the clip is restarted (rather than
   kept) when the reported montage name flickers, a seated pose restarts from its first frame, which looks like a
   jump. The earlier chest work hit exactly this class of flicker.

Not investigated further in this session: it is cosmetic, and the two-PC pair was being used for the broader
end-to-end checks at the time.

### A picked-up item stays visible on the other copy when it was never tracked (2026-11-07, FIXED in 0.4.2.35 and 0.4.2.42)

Reported: *"an ore nugget was not picked up on the host - the guest took it."* The logs show it precisely:

```
host : S gone received: 3dd46272-e8cbb50c (tracked here)      <- removed, fine
host : S item BP_ItMi_Orenugget_World_C_...: the other player picked it up
host : S gone received: ac7dec1e-89df753f (not tracked here)  <- nothing to remove
guest: S item BP_ItMi_Orenugget_World_C_... picked up here, tracked item (id ac7dec1e-89df753f)
```

The removal event travels and the guest reports it correctly, but the host could not apply it because that item was
never in its tracked list: the list is filled by a periodic scan with a radius, and an item the guest reaches before
that scan has run is unknown to the host, so the actor stays in the world on the host's copy - the player sees an item
that is already gone for the other player.

Shape of a fix: when a "gone" arrives for an id that is not tracked, look the actor up on demand (a bounded scan for
world-item actors, or a lookup by the id hash over the item classes) and destroy it. The alternative - tracking items
in a wider radius - costs scan time per second and only moves the window.

### Harvesting (berries and herbs) is not mirrored (2026-11-07, FIXED - verified in play) (2026-11-07, open)

Reported: *"the guest picked the berries, but on the host they stayed."*

The pickup sync that does work is the one that watches a world object disappear - the log is full of
`S item <class> removed on arrival (picked up by the other player)` for loose planks. A berry bush is different: the
bush stays in the world, the game only plays a harvest interaction and puts the fruit into the inventory, so nothing
is removed and nothing travels. The guest's log at that moment shows only the animation:

```
A local action -> A_Man_N_PickUp_Down_L
A local action -> FA_Man_S2H_PickUp
```

while the host's log has no item event at all in the same seconds.

**Verified on 2026-11-07 (host, live session):** three harvests, both directions, all synchronised. The proof, one
line per side:

```
#1 guest picks   -> host: S gone received: fcdda38d-b100466e (tracked here)  + S item ... the other player picked it up
#2 guest picks   -> host: S gone received: d44a7bd6-d2de248f (tracked here)  + S item ... the other player picked it up
#3 host picks    -> guest: S gone received: bfde7366-19817d3c (tracked here) + S item ... the other player picked it up
```

and on the picking copy the bush actor really is gone (`where <ptr>` -> "not a live game object"). What made it work was
not a harvest-specific feature: the item sync keys items without a persistent id on a 2 m cell (0.4.2.42), so the bush
is recognised as "the same item" on both sides and the removal applies.

Two things were *not* bugs and are worth remembering when the next report comes in:

* two bushes standing close together look identical - after a harvest the neighbour is still there and can be mistaken
  for "the bush came back";
* the picking copy keeps an empty plant model (the game swaps models), while the other copy removes the actor. That
  difference is cosmetic and has not been observed to confuse anyone since.

This is the same family as the cooking pan: **interactions that do not destroy a world object are not mirrored.** The
shape of a fix: observe the harvest interaction (the montage is already visible in the log) and replay it on the other
copy so the same bush becomes picked, or send "harvested <bush actor>" and mark it there.

### Cooking / interaction props are not mirrored - only the animation (2026-11-07, open)

Reported in the first two-PC session: *"I took a pan to cook something and on the guest the pan did not appear in my
hand - I am doing something with air."*

The log says exactly what happens:

```
S chest: Multicast_PlayInteractMontage seen (montage 'Object_Interact_Pan_Montage', ...)   <- replayed on the guest
E local equipment: W=0;V=-                                                                  <- unchanged since start-up
```

So the **interaction montage travels** (the other copy sees the arm movement) but the **prop does not**. The equipment
sync only reports visuals attached to the hero's mesh (`AttachChildren` of `Mesh`, owner == hero), and this pan is a
world object the game spawns for the interaction - it is not worn equipment, so it never enters that list.

What this class needs (it will also cover workbenches, cauldrons and similar stations): when the host starts an
interaction montage that has a prop, the prop's actor (class + transform + parent socket) has to travel too, or the
prop has to be spawned on the guest from the same montage. The chest work already showed the pattern for replaying a
montage; the missing half is the object.

Not fixed in this session: the two-PC pair was being used for the broader end-to-end checks, and this is a niche
interaction. It is recorded here with the evidence so the next session starts from the log line, not from the report.

**Measured again on 2026-11-07 (host, live session) - the prop is not a simple actor:**

| probe | result |
|---|---|
| new actors in the world when the cooking montage starts | **none** - the object count does not change at all |
| components attached to the hero's mesh during cooking | **16, exactly as before** - no pan appears |
| what those 16 are | camera boom, hurt/hit boxes, capsules, health bar, HUD marker, Mutable component |
| the montage | arrives normally: `Object_Interact_Pan_Montage` |

So the pan is not spawned and not attached. The remaining explanation is the character's **Mutable (customisation)
system**: `CustomizableSkeletalComponent` -> `CustomizableObjectInstance` regenerates the character mesh, so a held prop
can be part of the generated mesh rather than an actor of its own. Mirroring that means replicating Mutable parameters,
which is a different kind of work from everything else in this mod.

**Also learned the hard way:** a diagnostic that walked the object list inside the interaction callback (to look for the
prop) blocked the game exactly when the cooking UI opens, and the window appeared filled with `Label` / `Lorem ipsum`
placeholders. Any future recon here must stay out of game callbacks and behind a file flag - that rule is now in
`docs/ONLINE_TESTING.md` and in the notes at the top of the story module.

### "This save was made with a different modlist" (2026-11-07, ROOT CAUSE FOUND, fixed in 0.4.2.38)

Still seen after 0.4.2.32 (which made both copies ship the same core, `coopdll_109`). The dialog lists `G1RCoop 0.0.1`
and appears both on F9 and in the main menu before loading.

**Root cause:** the game has its own mod system - a descriptor at `G1R\Mods\<name>\GothicMod.json` plus the enabled
list in `%LOCALAPPDATA%\G1R\Saved\Mods.ini` - and it records the enabled mods in every save. This PC carried an old
`G1RCoop` descriptor with `"modVersion": "0.0.1"` from an earlier experiment, while the installer never created one at
all. Every save therefore recorded `G1RCoop 0.0.1`, and a PC without that descriptor (or with another version) gets the
warning.

**Fixed:** the installer now writes the descriptor with the package version and enables it in `Mods.ini`; the uninstaller
removes both. Both copies must run the same package version for the descriptors to match.

Next things to check, in order:
1. whether the dialog also appears when loading a save that was made **with** the mod on both sides (if it does, the
   list is compared by something else - a hash, a build id or a version resource that our DLL does not carry);
2. the DLL's version resource: `G1RCoop 0.0.1` looks like a name plus a default version, so the game may be reading a
   VERSIONINFO that we never set; giving both copies the same explicit version resource is the cheapest experiment.

#### A mirrored NPC walks in place while the owner stands and talks (2026-11-07, open)

Reported: *"Drax walks on the spot on the guest, while on the host he stands and talks to Ratford."*

So the owner has speed 0 and is in a dialogue, and the mirror keeps playing a walk cycle without moving. Two suspects,
and the log can tell them apart (the mirror's diag line prints `speed`, the montage count and the current clip):

1. **the mirror's own AI still asks for movement.** The module switches the movement component's tick off and calls
   `StopMovementImmediately` while the owner's speed is 0, but the animation blueprint drives its locomotion state from
   the character's velocity / input, not only from the movement component. If a velocity remains, the mirror keeps
   walking in place;
2. **the dialogue uses a clip the sync skips.** Voice and facial montages (`AnimMontage_<number>`, `GVL_*`, `DialogFacials`)
   are deliberately not mirrored - there is no asset to load - so on the mirror the body falls back to its own state,
   which for an NPC whose script walked it to a talk spot is "walking".

**Experiment to run (recorded, not tried yet):** create 
pc_unpossess.txt on the guest - the module already has that
switch and it unpossesses the mirror's controller, which should stop the AI-driven walk. If the walk stops and no T-pose
appears, the fix is to unpossess only while the owner is stationary and re-possess when he moves. If a T-pose or a crash
appears, the switch stays off and the animation has to be forced another way (for example by zeroing the anim instance's
speed each update).

What the log will show: `N diag guest mirror <id>: ... speed 0 ... montages N (<clip>)` for Drax. If the montage list is
empty and the clip is a walk/idle of its own, it is (2); if a velocity is non-zero, it is (1) and the mirror needs its
velocity zeroed every update instead of once.

## NPC scripts address one player and then fire again for the other (2026-11-07, open, needs a decision)

Reported: *"some NPCs address the host or the guest - whoever was first - again: to warn about something, to demand ore,
the guard at the gate."*

The cause is structural: a Gothic script is written for **one** player. Our version gives each copy its own actor for
every NPC (one simulates, the other mirrors), and a script that talks to "the player" runs on both copies - so a
reminder, a demand for ore or a gate check happens twice, once per player, and the dialogue lands on whoever is near
that copy's actor.

The NPC module does not touch interaction at all (no `SetForceDisableInteraction`, nothing similar), so a mirrored NPC
stays fully talkable on the copy that does not own it. That is where the second dialogue comes from.

Options, cheapest first:

1. **disable interaction on mirrors.** Only the copy that owns an NPC can talk to it; the other player sees it and can
   fight it, and gets the dialogue only once ownership moves to him (he walks closer than the owner). Predictable and
   cheap to implement; the cost is that a player cannot talk to an NPC while the other player is standing nearer to it;
2. **replay script outcomes instead of preventing them** - synchronise the flags the script sets (already partly done
   through the story block), which does not stop the second dialogue but makes its consequences consistent;
3. **do nothing** - the double reminder is visible and, for anything that consumes items (ore demands), it costs the
   players twice.

Checked against the code on 2026-11-07: option 1 needs no new engine knowledge. The story module already locks a chest
exactly this way while the other player is inside it - `InteractiveComponent::SetForceDisableInteraction(Value=1)` on the
object's `InteractiveComponent` (`native\story_module.c:557`), and the `Value=0` call to lift it again (`:489`). The same
two calls on the mirror's own interactive component would make a mirrored NPC untalkable on the copy that does not own
it, and ownership changes already run through one place (`own_*` in `npc_module.c`), so the lock can be raised and
lowered there. The npc module itself has no interaction code today (grepped: nothing but the movement component).

## NPC and combat
- FIXED?: NPC missing on the guest (runtime-named spawner NPCs); a group of monsters was in sync, killed, lootable (tested once).
- FIXED?: NPC "walks on the spot" in a dialogue on the guest (movement component off while the owner stands); tested on two NPCs.
- NOT A BUG: NPC turns to the hero at the start of a dialogue (the host does it too).
- OPEN: human animations appear on the guest about 1.5 s late (clip check every 0.7 s, clip starts from 0).
- OPEN (corpse bodies only): the bone-driven bodies of defeated NPCs are not reliably applied on the guest ("bone-driven 3", "applied 0"). **This is not the player puppet:** the puppet pose is measured and correct — hero bones of one copy match the puppet bones of the other within 0.4 units (see "Automated checks"). The corpse path is a different one (`npc_module` bone-driven mirror).
- SKELETON: guest ranged hits on host NPCs (aim-cone claim), damage bridge of the other agent; boss fights not tested.
- OPEN: monsters that exist only on one copy when the heroes are far apart.
- OPEN: NPC animation bugs after a mirror death (user to describe).

## A dead meatbug spins around its own axis (2026-11-07, open, needs the side)

Reported: *"the meatbug died by itself and now spins around its axis."*

The host's log around that moment:

```
13:22:09  N death: mirror 1c7757f0 killed here (ok, try 99)
13:22:09  A resolve 'Meatbug_Montage_Death'
13:22:16  A resolve 'Meatbug_Montage_Idle'
13:22:41  A resolve 'Meatbug_Montage_Eat'
13:22:57  N seat 0: 3 characters known, simulating 0, mirroring 2, missing 0, bone-driven here 0
```

Two things stand out: the kill needed **99 attempts** before it took, and after the death montage the same mirror plays **Idle and then Eat** - an animation sequence that belongs to a living creature. A body that is dead on the owner's copy but still running idle/eat clips on the mirror, while the mirror's own controller keeps turning the actor, would look exactly like "spinning around its axis".

**Update (same session):** the spinning stopped by itself after a while, so it is a transient state rather than a
permanent one - most likely the period between the owner's death and the mirror's release, which the 99 kill attempts
stretched out. Recorded, not chased further.

Next step is one question: **which copy spins** - the one that simulates the creature, or the other one? If it is the mirror, the fix is to stop replaying clips for an NPC that is dead on the owner's copy and to stop letting the mirror's controller rotate the actor after the death.

## The clock the mod read was not the clock the game runs (2026-11-07, FIXED in 0.4.2.71)

Reported: *"the host shows 18:25, the guest shows 12:00, and the guest's time tries to move to 12:01 but rolls back all
the time."*

The logs said exactly that - the guest was doing the right thing:

```
host : S time now: 12:00:00                      <- what the mod read
guest: S time: the host's clock is 12:00, this copy had 12:01
guest: S time: clock set to 12:00 (ok)           <- so it rolled back, every five seconds
```

The host's display showed 18:25 while the mod read 12:00, so the read was wrong. `GameTimeSubsystem` has two clocks:

| field | what it is |
|---|---|
| `CurrentGameTime` (double, offset 72) | **the clock that runs**: seconds since the start of the day. The live value `222828.6` decodes to 13:53, which matched the in-game display |
| `GetCurrentClockTime()` / `SetCurrentClockTime()` | a static struct that returns whatever was last *set* to it and does not follow the game |

Everything used the second one, so setting the time only wrote a shadow value: it "worked" (`clock set to 08:00 (ok)`) but
the world kept its own time. That also explains the earlier "the morning never came" report: the sleep jump wrote the
shadow clock, and the guest was then synced back to the frozen value.

Fixed: `clock_now` reads `CurrentGameTime` and converts it to h/m/s, `clock_set` writes it (keeping the day counter, so
only the time of day changes), and the old calls stay as a fallback if a future build moves the field.

Verified: `set 08:00` -> five seconds later `S time now: 08:01:31` - the clock runs.

## The "the NPC took your items" message does not appear (2026-11-07, open)

Reported: *"I fought an NPC, he took the ore, but no message popped up that he had taken everything"* - the same kind of
notification the game shows when a toll is paid.

Nothing about it is in either log: no ore line, no trade line, only the slow `trade_poll` (33-55 ms) in those seconds,
which means the mod was busy with the trader component at that moment but does not report the removal.

Two ways this can happen, and the next test separates them:

1. **the removal happened on the other copy.** If the NPC is owned by the other player, his copy runs the dialogue and the
   script takes the items there; this copy then loses them through the synchronisation, without the game's own message,
   because the game never ran that branch locally;
2. **the mod suppresses the message.** We do touch the UI in two places (the death screen's demo text and the trade
   notice, which goes to the window title), so a message widget being hidden is possible.

Test: have the same NPC take items twice - once with the owner's player standing nearer (he talks, his copy removes the
items) and once with the other player nearer. If the message only appears for the owner, it is (1).

## Notifications show a missing localization string (2026-11-07, open, same family as the rune names)

Reported: when an NPC takes items (ore, a toll-like removal) the notification does not show readable text - it looks
like the `<MISSING STRING TABLE ENTRY>` case already recorded for runes in the inventory.

So the widget is there and the event happens; what is missing is the localized string it formats. Two things can cause
it, and they are cheap to tell apart:

1. **the game has no string for that message in this language.** The same happens with rune names, which have no
   localized text at all - if the notification is built from a format string that the Russian table lacks, nothing we do
   will fix it except supplying a translation;
2. **we set the label ourselves and lost it.** The mod writes text into UI in three places (the death screen's four
   button labels, the trade notice in the window title, and the demo text it hides). If the notification reuses one of
   those widgets, our write may be what leaves it empty.

Next step: catch the notification once with `obs_log.txt` (every observed UI call is logged) or with the probe on the
live text widget, and see whether the string arrives empty from the game or is overwritten.

## Dialogue
- **PARTIAL 2026-11-05: dialogue lines reach the guest, but the display does not render reliably.**
  What WORKS: the host's line is read from `W_ConversationMain_C -> RichTextBlock_DialogueLine ->
  Text`, sent in the story blob and written into the guest's `W_SimpleSubtitlesGothic_C`
  (`Text_Dialogue -> SetText(name, text)`); the FText in the widget really contains the line
  (checked with `probe members`), and on one earlier build the text was visibly on screen (screenshot).
  What does NOT work now: the created widget does not draw, and `SetText` throws a **caught**
  `EXCEPTION 0xc0000005 in ProcessEvent(SetText)` inside the game function. Tried and failed:
  `UpdateText(ConversationVoicelineData&)` (returns 0), writing the RichTextBlock `Text` directly
  (writes fine, draws nothing), `SetAnchorsInViewport`/`SetAlignmentInViewport`/`SetPositionInViewport`
  (broke SetText), the canvas slot (Slot is null for a widget added with AddToViewport), and
  `Visibility` (4 and 0 both shown, no change). `SecondsDisplayed` was 0 on a fresh widget - it now
  gets 8 s, which stops the widget from closing in the same frame.
  Also tried and failed: creating a plain W_SimpleGothicText_C or W_PlayerSpeak_C instead (the game
  reuses W_SimpleSubtitlesGothic_C for its own ambient lines and overwrote ours) - WidgetBlueprintLibrary::Create
  returns null for both when the OwningPlayer is missing, so those widgets cannot be created this way.
  The existing variant does draw (screenshot at 20:39), is placed bottom-centre via
  SetDesiredSizeInViewport/SetPositionInViewport, is read every 30 ms for smooth typing and is removed
  2.5 s after the last line.
  **Bytecode note (important):** every function of the dialogue system is AngelScript/Blueprint
  bytecode, and this core can hook only native C++ bodies. Verified live, none of them can be
  observed: ConversationWidget::ShowVoiceline, CinematicMainWidget::BP_OnVoiceline,
  AbilityTask_SayVoiceline::TaskSayVoiceline, AbilityTask_Speak::TaskSpeakGenericVoiceline[Queue],
  ConversationTopic::Act. They CAN be called (call_fn works on bytecode), just not hooked.
  **Voice idea:** the right way is not streaming audio but letting the guest's own game play the same
  voiceline from its local assets (that would fix the subtitles too, natively, in the right place).
  The hook must therefore be a NATIVE function on the audio path - the FMOD event call in the exe
  (search for the signature behind PlayEvent/FMOD in the exe, then capture the event id). Not done
  yet; this is a separate task, larger than a reflection-level change.
  NEXT IDEA (not tried): let the game show it itself - `AbilityTask_SayVoiceline::TaskSayVoiceline`
  (OwningAbility, Text, SoundKind) is the native path the game uses for subtitles; call it on the
  guest's speaking character instead of drawing a widget.
  Voice stays host-only in any case (the audio plays in that process and cannot be sent to another).
- NOTE (not a desync): the chest SET can differ for a few seconds while a cell streams in - observed
  `CHESTS DIFF 17/18, only seat B: Interactive_Chest_C_UAID_...` and after the heroes moved deeper it
  became 19/19 with identical lists. Treat a chest difference as real only if it survives a minute.
- **FIXED 2026-11-05/06, verified in play: the chest lid opens on the other copy.** For a long time this
  was recorded as "animation set, position runs, ticks forced, but the pose is not rendered". The real
  cause was found by reading the state with `probe` instead of looking at the screen:
  * the guest's chest anim instance (`AnimSingleNodeInstance`) had **`CurrentAsset = null`** while the
    host's held `PT_LockedChest_AnimMontage` - there was simply nothing to play;
  * the game does **not** call `Multicast_PlayInteractMontage` on a chest: it writes the asset straight
    into the single-node instance. So observing that function (registered anyway, harmless) never
    helps. What works is sending the *state* - the host's chest poll already watched every change of
    (asset, playing, rate) for its log, and now also sends it as a type 4 event `"<asset>|<position>"`;
  * the guest could not resolve the asset by name, because a copy that never animated a chest does not
    have the montage in memory - the type 4 handler now falls back to `load_asset`, like the section
    path already did.
  Confirmed afterwards: the guest's anim instance holds `PT_LockedChest_AnimMontage` and the open chest
  is visible on the guest's screen. Commit `860e95d`.
  **Second half of the fix (2026-11-06, also verified in play):** right after a module reload neither
  copy had the chest in its tracked list yet, so the opening was lost (`S chest event kept: the chest is
  not tracked here yet` at the receiver, and the sender could not even send). Both sides now resolve the
  chest on the spot:
  * the host adds the chest to its list **from the actor pointer the observer hands over**
    (`chest_add_by_ptr`, log `tracked on the spot (a lid call named it, N items)`);
  * the guest finds the chest **from the four id bytes in the message** (`chest_by_id4`,
    log `found by its id, without waiting for the scan`), so no 10 s wait and no dropped event.
  Verified: open the chest immediately after a module reload -> the guest's lid goes up on the first try.
  Commits `860e95d`, `f7a5b0e`-era changes.
  Note from the same test (checked in game, contents are identical - so this was a false alarm): the log
  showed `tracked on the spot ... (10 items)` on the host and `found by its id ... (1 items)` on the guest.
  That number is `t->base`, read at the moment the chest entry is created; on the guest the container is
  not filled yet at that instant. It is not a comparison of the contents and must not be read as one.

- OPEN, cosmetic: **the lid opens on the other copy but closing leaves it half open, and opening feels delayed.**
  What is in place now:
  * the **slot-0 bug was found and fixed** - `observe_fn` returned slot **0** for
    `Multicast_JumpSectionInteractMontage`, while every mapping loop in the module required `slot > 0`.
    That is why those calls showed up as `S obs ?` and never reached a handler. Registration also
    re-registered every second (slot 0 looked like "not registered"), so the log was full of noise. Both
    are fixed: each chest function registers once and slot 0 maps to its name. After this the host sends
    the real lid calls (`JumpSection` sections, `Stop`) instead of guessing.
  * opening: the state event reaches the guest in **57-130 ms** (measured over several opens:
    host `45.013 montage ... (sent)` -> guest `45.070 animation ... played`). So the transfer is not the
    reason the lid feels late - most likely the player waits for the host's lockpicking animation
    (`A_Man_Lockpicking_Chest_In`) before the lid moves at all.
  * closing: two stop events were arriving - one with the real frame (`10.07`) and one from the observed
    `Stop` call carrying the placeholder `"s"`, which `atof` turns into **0.00**; the second overwrote
    the first and left the lid half open. The observed stop now sends the real frame too, and an echo
    guard (`t->ign`) stops the receiver from sending back what it just applied.
  Result after all of that (still reported by the player): closing leaves the lid half open and opening
  still feels delayed. So the remaining cause is not the transport.
  **Next idea (not tried):** stop copying the montage position and just replay the game's own calls -
  `JumpSection` with the section name the host used, `Stop` for the end. Our type 6 already does
  `Multicast_JumpSectionInteractMontage(SectionName, AnimMontage)` on the receiver, and the section hash
  is what the host sends (`lid section 0001693100000000 replayed (ok)`). Make the receiver ignore the
  position events entirely and let the montage run its own timeline; if the half-open state disappears,
  the position copying was fighting the montage.
  Note: the tested chest is a *locked* one (`A_Man_Lockpicking_Chest_In`), so `PT_LockedChest_AnimMontage`
  may be the lockpicking timeline rather than a plain open/close one - worth one test on an unlocked chest
  before more work.


- SKELETON: dropped items and stacks (water 15/51/99, ore 13 both ways); stack cap is 99.
- **VERIFIED WORKING 2026-11-05 (was reported as broken): ore picking up is synchronised in both
  directions.** Tested live in the mine with `probe`: the host took `BP_ItMi_Orenugget_World_C_2147365576`
  -> the guest logged `S item ... the other player picked it up` and destroyed its actor; then the guest
  took `..._2147365564` -> the host did the same. The number of nuggets in the world stayed equal
  (30 -> 30 -> 29 on both copies) and `parity` reported `INV OK`. The item path works because the nugget
  class has `m_PersistentId` + `m_WorldItemDefinition` (checked with `probe class`), which is exactly what
  `cls_has_item()` keys on.
  How to re-check in one minute: `probe "@0 findall ItMi_Orenugget * 60"` on both copies, take one nugget
  on one copy, repeat - the lists must stay identical.

## Items on the ground

- OPEN, cosmetic (confirmed with two screenshots 2026-11-05/06): **a torch thrown on the ground burns on
  the guest but not on the host.** In the host's screenshot both torches lie there as plain sticks; in
  the guest's one of them has a visible flame. So the receiving copy is the one that adds fire: the
  spawn creates the item together with its fire child actor, while the game on the host has already put
  it out.
  What makes this hard: none of the reflected state tells "burning" apart. On both copies every dropped
  `BP_ItMw_1H_Torch_World_C` had a live `Fire Actor`
  (`TorchFire_Actor_Child_NoShadow_C`), the same components (Niagara, `LogicalLightSource`,
  `PointLight_Fire`, `OriginalIntensity` 50), `TimeSinceFireStarted` 0, **`Intensity` 0** and
  `ActorComponent::IsActive` = 0 on the particle component — identical numbers, different picture.
  The runtime particle state is not exposed through reflection, and the game's own light/extinguish path
  is AngelScript bytecode, so it cannot be hooked either.
  Two pragmatic options, neither is real synchronisation:
  1. after spawning a dropped torch on the receiving copy, destroy its fire child actor — the guest then
     sees an extinguished torch, like the host (but loses fire if the host's really is burning);
  2. force the fire on for both copies — the cave gets light, but that changes the game's behaviour.
  Decided to leave it: a torch on the ground affects nothing. `TorchId` differs per copy (10 vs 5) but
  behaves like a plain id.

## Journal / quest log

- OPEN (found 2026-11-05 in live play): **journal entries are not synchronised.** After a
  conversation that adds a note to the quest log the entry appears only on the host; the guest's
  journal stays unchanged. Quest STATES are synchronised (the story module writes them through the
  game's own StartQuest / SucceedQuest / MakeQuestAvailable), so what is missing is the journal data
  itself, most likely a separate object the game fills when a conversation ends. Where to start:
  compare the `QuestSubsystem` / journal objects on both copies right after the same conversation,
  then look for the **native** function that adds an entry (see the note about bytecode below).
  **Where it lives (found 2026-11-05, with a screenshot of both journals):** the entry is a
  glossary/document unlock, not a quest — the "Справочник" tab listed "Диего" and "Дрейк" on the host
  and only "Диего" on the guest. `/Script/G1R` has `DocumentSubsystem` and `Document` with
  `RememberSegmentUnlocked(Reader, DocumentClass, SegmentClass)`, `FindSegmentsUnlockedByReader`,
  `IsSegmentUnlockedByReader`, and `DocumentSubsystem::NotifyPotentialSegmentUnlock(Reader,
  InvolvedCharacterUniqueNames)`. The per-character pages are `GlossaryDocument` assets
  (`..._Glossary_OM_GRD_DRAKE_Introduction`, `_Beer`, `_Info` ...) with `DocumentSegment` children;
  the journal lists the documents whose segments the reader has unlocked. These are C++ classes, so
  unlike the dialogue functions they **can** be hooked — the module now observes
  `Document::RememberSegmentUnlocked` and logs `S doc: ... document '<class>' segment '<class>'`.
  **Result (verified live): those hooks do not attach.** Checked one by one —
  `Document::RememberSegmentUnlocked`, `DocumentSubsystem::NotifyPotentialSegmentUnlock`,
  `ConversationTopic::Act`, `AbilityTask_SayVoiceline::TaskSayVoiceline`,
  `AbilityTask_Speak::TaskSpeakGenericVoiceline[Queue]` — none of them registers, while the nine
  engine-level functions we already use (DataModule_Container, CarryComponent, ItemVisualWorld,
  widgets, GameStory) hook fine. Conclusion: the gameplay layer is AngelScript bytecode and only
  native engine functions can be observed.
  **So the journal must be fixed by polling, not by hooking:** `Document::IsSegmentUnlockedByReader`
  and `Document::FindSegmentsUnlockedByReader` can be *called*, so the host can poll which segments
  its reader has unlocked, diff them, and the guest can call `RememberSegmentUnlocked` with its own
  reader for the new ones. That needs the reader object (likely the player state) and a document
  enumeration; a job for a fresh session, not a patch on top of a long one.

### Journal: OPEN -> FIXED (2026-11-06), verified in play

**The journal is synchronised now.** How it works, in the module:

* every copy polls `Document::FindSegmentsUnlockedByReader(reader, anyDocumentCdo)` every 3 s. One call
  returns the reader's **whole** unlocked set, so a poll is one engine call, not one per document.
* `reader` is the hero's `m_CharacterState`, the `Default__Document_*` CDO is only there to have a valid
  `this`; the `DocumentClass` argument does not narrow the answer.
* the first successful read is taken as the snapshot and sent nowhere (both copies start from one save).
  After that, any segment that appears in the set but not in the snapshot is queued as an event
  (type 15, the segment's class name) and sent immediately on the next tick.
* the receiver resolves the name to a class - by `find_object("Class", name, …)` and, when that class is
  not loaded on that copy, through the class of its `Default__<name>` object - reads the owning document
  from that default object's `InDocument`, and calls
  `Document::RememberSegmentUnlocked(itsOwnReader, owningDocument, segmentClass)`.
  It then drops its snapshot so its own unlock is not sent back.

Verified live: unlocking `DocumentSegment_Glossary_OM_GRD_DRAKE_Info` on the host produced
`S journal: '…_Info' unlocked here, sent to the other player` and, **160 ms later**, the guest logged
`S journal: '…_Info' unlocked here (from the other player, ok)` and its own count went 8 -> 9.

Protocol change that came with it: a cutscene-channel event record grew from 53 to **69 bytes**
(4-byte lid + 1-byte type + **64**-byte name) so a segment class name fits - old builds are not
compatible with new ones, both copies have to run the same module.

### What the exploration found on the way (kept for reference)

Everything below was measured with `probe` on a live copy, not guessed:

* `DocumentSubsystem_<id>` has a single property, **`AutoConditionalSegmentInstances`**, an array of
  **173 `DocumentSegment` instances** - these are all the journal fragments that exist. The array data
  pointer sits at object offset 64 (`peek <subsystem> 96` shows `data`, then `count`/`max` packed in the
  next qword: 173/186).
* each instance has three properties: `Contents` (empty in all of them), `InDocument` (a **class**
  pointer to the document this segment belongs to) and `AutoEvaluateUnlockFor` (array, length 1).
  There is no "unlocked" flag on the segment itself.
* the API is `Document::IsSegmentUnlockedByReader(Reader, SegmentClass) -> bool`,
  `Document::FindSegmentsUnlockedByReader(Reader, DocumentClass) -> array` and
  `Document::RememberSegmentUnlocked(Reader, DocumentClass, SegmentClass)`.
* **the open question is what `Reader` is.** Tried the `G1RPlayerState`, the player controller and the
  hero; `IsSegmentUnlockedByReader` returns 0 for all of them, even for
  `DocumentSegment_Glossary_OM_GRD_DRAKE_Introduction`, which is definitely unlocked on that copy. The
  call was made on the *class* object taken from `InDocument` (a `ClassProperty`), and the C++ side
  expects a `Document` instance - that is the likely reason it answers 0, not a wrong reader.
* documents are assets: only the native `GlossaryDocument` class is loaded, the per-character classes
  (`GlossaryDocument_OM_GRD_DRAKE_*`) appear in memory only while the journal UI is open. So a poll
  would first have to `load_asset` the document classes it wants to ask about.

**Second attempt, with the journal open (2026-11-06), also negative:**

* even with the journal open, only the native `Default__GlossaryDocument` CDO is in memory - the
  per-character document classes are never loaded as UObjects;
* `InDocument` on a segment instance is an **`ASClass`** (an AngelScript class object), not a `UObject`
  with properties. So documents live on the AngelScript side, and `Document::IsSegmentUnlockedByReader`
  / `FindSegmentsUnlockedByReader` expect a real `Document` instance as `this`; calling them on the
  ASClass object (or on the subsystem) returns zeros for every reader tried (player state, player
  controller, hero), on every property of the 64-byte return buffer.
* conclusion: the journal unlock state is **not reachable through reflection**. The remaining options
  are (1) read it from the save-game data, or (2) read the journal widget's list while the journal is
  open (`GlossaryMainWidget::GetDocuments`) - which only gives a signal in that moment, and the unlock
  happens at the end of a conversation, usually with the journal closed.

**Third attempt, with GORE (2026-11-06) - this one produced the answer to "what is a Reader":**

Installed the GORE toolkit (`dh0er/gore`, CLI 0.4.0, at `C:\Tools\gore-cli`) and decompiled the
game's AngelScript: `gore as emit-all <PrecompiledScript_Shipping.Cache> C:\Tools\gore-src` writes the
whole script tree as `.as` sources (7263 modules in the cache, ~5600 files written before I stopped it).
That tree is the single most useful thing we now have: the game's own logic is readable.

* the **Reader is the character's `m_CharacterState`** - on the hero that property holds the
  `G1RPlayerState` object, which is an `AGothicCharacterState`. (I had tried the player state before, but
  called the function on an `ASClass` instead of a real `UObject`, so the answer was meaningless.)
* the unlock path in the game's code is
  `GAS\GASCharacterStateMixins.as:1502 UnlockDocumentSegment(CharacterState, DocumentClass, DocumentSegmentClass)`
  which calls `UDocument::IsAllowedToUnlockSegment` and then `UDocument::RememberSegmentUnlocked`.
  Nothing else in the emitted tree calls `UnlockDocumentSegment`, so the game triggers unlocks from
  native code (a conversation action), not from script by name.
* documents are **script classes**: a segment's `InDocument` points at e.g. `Document_CH1_LOSTNEK`
  (an `ASClass`); segments are `DocumentSegment_*`. The subsystem's 173 instances are the segments of
  all documents.
* `probe nativefn Document IsSegmentUnlockedByReader` says the function pointer is not a native body -
  these are **script-bound** API functions: callable, not hookable. Same reason `RememberSegmentUnlocked`
  never attached to the observer.

Still not working: calling `IsSegmentUnlockedByReader` / `IsAllowedToUnlockSegment` /
`FindSegmentsUnlockedByReader` returns 0 for every combination tried (this = the native
`Default__Document`, this = the document's `ASClass`; reader = the character state; several segment
classes). The likely reason is the same one that made the earlier attempts meaningless: the function
needs a real **Document instance**, and the per-document classes appear to be instantiated only while
the journal is open (only the native `Default__Document` CDO exists in memory otherwise).

**Fourth attempt, journal open (2026-11-06) - the read works, the write needs one more piece:**

* with the journal open, the per-document CDOs exist as real objects (`Default__Document_CH1_LOSTNEK` etc.),
  and **the API answers when `this` is such a CDO** and the reader is the hero's `m_CharacterState`:
  ```
  IsAllowedToUnlockSegment(reader, doc, segment)      -> 1
  FindSegmentsUnlockedByReader(reader, doc)           -> array: data ptr + count 7
  ```
  The returned array is the reader's **whole** unlocked set (7 entries: Diego, FireMagesLetter, OldMine,
  Scavenger, Ratford x2, Molerat) - the `DocumentClass` argument does not narrow it. So ONE call per copy
  gives the complete journal state: exactly what a poll needs.
* **writing does not work yet:** `RememberSegmentUnlocked(reader, doc, segment)` was called with the
  Drake introduction segment (`IsAllowedToUnlockSegment` said 1) but the unlocked count stayed 7 and the
  segment never appeared - the document class passed was `Document_CH1_LOSTNEK`, and a segment clearly
  belongs to the document it was declared in. So the missing piece is **which document class owns a given
  segment**, per segment.
* live segment *instances* exist only for some documents (the CH1 ones are there, e.g.
  `DocumentSegment_CH1_LOSTNEK_Dead_2147445442`); the glossary segments of Diego/Drake exist only as
  CDOs here. Each instance has `InDocument` (a class pointer), which is where the owning document can be
  read from - but only when an instance exists.

**Next step:** for each unlocked segment find its owning document class. Two ways: (1) read `InDocument`
from the segment instance when one exists; (2) if a segment has no instance, look the class up in the
game's script sources (`C:\Tools\gore-src`) - the document classes are named `Document_<topic>` and the
segments `DocumentSegment_<topic>_<name>`. With the right pair:
`RememberSegmentUnlocked(guestReader, owningDoc, segment)` on the guest, once per new segment.

**Previous note (still true):** open the journal on a copy, list objects of the `Document_*` classes,
and call `IsSegmentUnlockedByReader` on one of those instances with the character state as Reader. If
that answers 1/0, the poll is straightforward: the host watches its own unlocked segments and sends the
new ones; the guest calls `UnlockDocumentSegment` (or `RememberSegmentUnlocked`) with its own state.

**Tooling note:** `probe call` used to print only the first 8 bytes of the return buffer, which hid
out parameters that live further in (this function returns at +16). It now prints all 64 bytes, so a
`ReturnValue bytes: 000...0` line really means "zero", not "not shown".

## Dialogue: the line goes through `AI.Say(textId)` (lead, 2026-11-06)

From the decompiled scripts (`gore\src\Story\G1R\Conversation\*.as`), every spoken dialogue line is
one call:

```angelscript
(this.GetDrax().GetAI()).Say(::LocText("ORG_819_DRAX_CREATURES_06_01"), GameplayTag::Expression_Neutral,
                              nullptr, false, NAME_None, NAME_None, FGameplayTag::Empty);
```

So a line is fully identified by its **localization text id** (`ORG_819_...`), the speaker and an
expression tag. If the other copy plays the same call, its own game does the rest: voice from the local
audio bank, the subtitle widget, lip sync and the camera - exactly what the widget experiments could
never achieve.

What is known:

* the call site is script, so it cannot be observed, but `Say` itself is **not declared in any script**
  (grepped the whole emitted tree) - so it is a native function and can be hooked by `observe_fn`,
  which is the same route that made the journal work;
* `probe findfn Say` lists 18 functions; the only plain `Say` is `GameMode::Say(Msg@0/16)`, whose
  signature does not match the call (one 16-byte message) - so the AI's `Say` belongs to a class or
  mixin whose name is still unknown;
* `Cast<UGameplayAbility_CharacterAI_Gothic>(CharacterState.GetAI())` in the scripts suggests the owner
  is the character's AI ability object.

**Next step:** with a talking NPC next to the hero, take `CharacterState` -> `GetAI()` and dump that
object's class and functions with `probe members ... fns`; the class that owns `Say` is the one to
observe. Then: capture the text id on the speaker, send it, and call the same `Say` on the matching
character of the other copy.

### Dialogue: everything on that path is script-bound (measured 2026-06-06)

Follow-up to the `AI.Say(textId)` lead - the whole chain was checked against the running game:

* `Say` is an AngelScript **mixin** in `AI\NativeAICommands.as:1026`. It calls `TaskSpeak(AI, Text,
  Expression, ...)`, sets fields on the returned `UAbilityTask_Speak` and wraps it in an
  `FAbilityTaskExecutor` that the ability system runs.
* `AbilityTask_Speak::TaskSpeak` (and `TaskSpeakGenericVoiceline[Queue]`) **cannot be observed**:
  `observe_fn` returns slot -1 for all three, and `probe nativefn` reports no native body. Same for
  `GenericVoicelineComponent::SayVoiceline[WithContext]`. They are callable, not hookable - the same
  class of functions as `Document::RememberSegmentUnlocked`.
* there is no state to poll either: the character's `GenericVoicelineComponent` carries only the base
  `ActorComponent` fields - no "last voiceline", no current tag, no current text.

So capturing a spoken line needs a different level: the native FMOD/audio call (that is where the
`REA`-style binary work would come in), or the conversation has to be started on the other copy so the
game speaks natively. What still might work without any of that:

* `TaskSpeak` **can be called**; the open question is whether the task runs when it is created outside
  the mixin (the executor normally calls `ReadyForActivation`). If it does, the guest could be made to
  show the *text* (built from the string we already read from the host's widget) even without the audio.
  Worth one test: create the task on a talking NPC and call `ReadyForActivation` on it.

### Dialogue: measured in a real conversation (2026-11-06)

A live conversation (Torrez in the Old Camp, host) with the observation trace on showed **only three**
things on the dialogue path, and it settled several questions:

| Function | Result |
|---|---|
| `AbilityTask_HandleSubdialog::HandleTopicSelected(Topic)` | **hookable** (slot 5) - fires once per topic choice and hands over the topic object (`Topic_Torrez_2147316887`) |
| `ConversationWidget::ShowVoiceline(Text@0/16, ForeignLanguage@16/1)` | hookable (slot 7) - **but never fires**, even during a full conversation |
| `ConversationTopic::Act()` | **not hookable** (slot -1), and calling it on a topic's `Default__` object runs (call ok) but **starts nothing** - the defaults are not live topics |
| everything else (`TaskSpeak`, `TaskSpeakGenericVoiceline[Queue]`, `GenericVoicelineComponent::SayVoiceline[WithContext]`) | not hookable (slot -1), callable |

**`probe nativefn` must not be trusted:** it prints the same "no UFunction native within 16 KB below"
for a function that certainly is hookable (`InteractiveObjectActor::Multicast_StopInteractMontage`) as
for one that is not. Some earlier conclusions in this file were drawn from it and are wrong where they
say "no native body" - the reliable signal is `observe_fn`'s slot number (>= 0 means hooked).

Side observation from the same conversation, and a good sign: the **journal sync worked by itself** -
Torrez's glossary entries (`DocumentSegment_Glossary_OC_KDF_TORREZ_BasicMagic`,
`DocumentSegment_CH1_FIREMAGESLETTER_TorrezNo`) were unlocked on the host and applied on the guest
while the conversation ran.

Where that leaves the dialogue problem: the only capture point we have is the *topic selection*, and the
only playback we could not achieve is *starting a conversation from outside*. The remaining approaches
are (a) the native FMOD call (binary work), (b) finding the entry point the game itself uses to start a
conversation with an NPC (`GameplayAbilityConversationV2` looks like it) and driving that on the guest.

## Voice for the guest: what was built and where to continue (2026-11-06)

Goal: the guest's own game should play the dialogue voice line, instead of us trying to mirror the
subtitle widget. That needs two halves - know *what* the host played, and be able to *play the same* on
the other copy.

### What was learned about the game's audio

* Gothic uses **FMOD Studio**, both `fmod.dll` and `fmodstudio.dll` are loaded into each game process.
* `fmodstudio.dll` is attached through the exe's **delay import** table, with **C++ mangled names**:
  `?getEventByID@System@Studio@FMOD@@...`, `?createInstance@EventDescription@...`,
  `?start@EventInstance@...`, `?update@System@...`, `?lookupPath@System@...` (70 entries in total).
  So the ordinary import table has nothing for FMOD, and `GetProcAddress` is resolved before the mod is
  injected - only the delay table is usable.
* the game plays events **by GUID**, not by path string; `System::lookupPath(guid)` turns a GUID into
  `event:/...`.
* the plain C exports are all there too: `FMOD_Studio_EventInstance_GetDescription`,
  `FMOD_Studio_EventDescription_GetID`, `FMOD_Studio_System_LookupPath`, `FMOD_Studio_System_GetEventByID`,
  `FMOD_Studio_EventDescription_CreateInstance`, `FMOD_Studio_EventInstance_Start`.

### What is implemented (in the core, `native/n2.inc`, COREAPI_VERSION 17)

* a **delay-import patch**: the core walks the delay descriptors and swaps the slot of
  `EventInstance::start` and `System::update` (the latter hands us the Studio system pointer every frame).
  This is the first native (non-UFUNCTION) hook in the mod - reusable for anything else in a delay table.
* `EventInstance::start` is wrapped: it resolves the instance's description, its GUID
  (`GetDescription` -> `GetID`) and its path (`LookupPath`), and logs
  `F fmod: start <guid> path 'event:/...'` whenever the GUID changes.
* the C exports are resolved **lazily** (at hook-install time `fmodstudio.dll` is not loaded yet).
* playback is ready and exposed to modules: `fmod_system`, `fmod_guid` (last event) and
  `fmod_play_guid(guid16)` - it does `GetEventByID -> CreateInstance -> Start` on this copy's system.

### Where it stopped

Only the music event was captured (`event:/MUSIC/MUSIC_MASTER`); a live conversation produced **no new
`start` line**. So either the hook does not fire for one-shot events, or voice does not go through
`EventInstance::start`.

**Next steps, in order:**

1. **Validate the hook first**: draw a weapon / hit something (a sound that is definitely a one-shot) and
   look for a new `F fmod: start ...` line. That single test separates "hook is broken" from "voice uses
   another path".
2. if the hook is blind to one-shots: hook `EventDescription::createInstance` instead (every playback
   creates an instance), and identify the event from the description with the same C exports.
3. if voice is not a Studio event at all: check `fmod.dll` (core API) - the dialogue audio may be played
   as a plain sound; then hook `System::createSound`/`Channel::setCallback` equivalents.
4. when the voice paths are known (something like `event:/VO/...`), the sync is small: the host sends the
   16-byte GUID when the path matches the voice prefix, the guest calls `fmod_play_guid`. No audio data
   crosses the network - the guest has the same banks.
5. the subtitle is a separate problem, but once the guest's own game starts the event, the game's own
   subtitle path may run too (it is triggered by the same audio event) - worth checking at that point.

### Notes for whoever continues

* each core build needs **both copies restarted**; the module hot-reload does not cover the core.
* do not patch the exe's ordinary import table for FMOD (nothing there) and do not rely on
  `GetProcAddress` (already resolved). The delay descriptor is the only door.
* `probe nativefn` is useless (see the earlier note); the real signal is `observe_fn`'s slot or an actual
  observed call.

## Chest lid: state matches, the picture still does not (2026-11-06, last state)

After the opening fix the closing still looks wrong to the player ("half open, with a delay"). What the
log says now, on the same frame:

* the guest receives the closing section (`lid section ... replayed (ok)`), the montage play and the stop;
* the guest's anim instance ends in exactly the host's state: asset `PT_LockedChest_AnimMontage`,
  `playing 0`, position `10.06` - the same numbers as the host;
* `TickAnimation` and `RefreshBoneTransforms` **cannot be called by name** through the reflection
  (`pose refresh failed`), so the pose is not re-evaluated that way; forcing the mesh and actor to tick
  instead works (`mesh ticking forced ... component ok, actor ok`) but the picture is still reported as
  half open.

So the data is right and the drawing is not. Remaining ideas, in order:

1. **the mirror widget/camera**: the guest may be looking at a *different* chest actor than the one we
   animate (the UAID actor vs a variant) - compare the actor the guest has selected in `chestlist` with
   the one the host opens;
2. drive the lid through the **anim blueprint** instead of the single-node asset: the mesh may be drawn
   from `MainAnimInstance` (an AnimBP), where `SetPosition` on `AnimSingleNodeInstance` has no effect on
   what is drawn;
3. accept it: the chest opens correctly, closing stays off; it is cosmetic and the chest can be used.

Delays seen in the same test are the same class as the rest of the chest events (one engine frame plus
the 200 ms send tick); they are not a separate bug.

## Chest lid: closing is fixed, opening keeps a 3-4 s visual delay (parked)

State after the last round of tests:

* **closing works.** The guest gets the closing section, the stop and the host's frame (10.06 / 9.40),
  and the lid goes down. Forcing the mesh and actor to tick at that moment is what made it work.
* **opening is still late by 3-4 s on the guest**, and none of the following changed it:
  * the events themselves arrive in the **same millisecond** (host `montage ... (sent)` and guest
    `animation ... played` are 100-150 ms apart, the section jump lands in the same millisecond);
  * `VisibilityBasedAnimTickOption` on the guest's chest mesh is **0** (always tick) - the write sticks;
  * forcing the mesh/actor tick at the opening does not help;
  * forcing the montage to the opening frame (`SetPosition(0)` + `SetPlaying(true)`) does not help;
  * `TickAnimation` and `RefreshBoneTransforms` cannot be called by name through the reflection.
  So the chest's own animation state on the guest is right, its mesh is allowed to tick, and the picture
  still lags - the game is drawing that chest from something we are not driving. The next suspect is the
  **AnimBlueprint** on the chest's mesh (the single-node instance we set may only be a fallback), and the
  ~4 s coincidence with the "in use" heartbeat is worth remembering.
* the delay is cosmetic: the chest opens and closes, and it can be used.

**Do not spend more time here without a new idea from the script side**: with GORE the chest's own
interaction/anim blueprint is readable (`gore\src`), and that is the cheaper way to see what actually
drives the lid on a copy that is not the one being interacted with.

### The mesh heading is not the cause (checked 2026-11-06)

The guest's diagnostic showed `want yaw 180, actor yaw 180, mesh yaw 90`, which looked like the body being drawn
90 degrees away from the actor. Measured the same NPC's mesh on the host with `K2_GetComponentRotation`: the
host's mesh yaw is **also ~90**, so both copies agree and the mesh is not what differs. The record now carries
the mesh heading anyway (it costs two bytes and keeps the drawn body in step if it ever does drift), but it
does not fix anything by itself.

**So the only cause left is the ownership model** (below): the copy that owns an NPC runs his AI, and what he
is doing is never synchronised.

### Option that was decided but NOT done yet: let the host own every NPC

The ownership rule today is "the copy whose hero is nearer simulates the NPC" (`own_set` / `own_force` in
`npc_module.c`, decisions logged as `N owner of <id> -> seat N (<why>)`). Because the owner also runs the NPC's
own AI, idle behaviour diverges whenever ownership moves - the player sees the same NPC sitting and whittling on
one copy and standing and turning on the other.

The change would be small: make the host the owner of every NPC and drop the nearest-hero rule, so the guest
only ever mirrors.

**The user asked to write this down, not to do it yet.** Points to settle before doing it:

* what the guest loses when every NPC is simulated elsewhere (his own hits, talking, pickpocketing - anything
  that needs the NPC to react locally);
* whether the guest can still start a conversation with an NPC the host owns, and what happens if both talk to
  the same NPC;
* the cost on the host side: he would simulate every NPC in the loaded area, including ones far from either
  hero (today that work is split).

## An NPC can be doing different things on the two copies (2026-11-06, open)

Seen in play: an NPC sits and whittles a piece of wood on the host, while on the guest the same NPC stands up
and turns around.

This is not the pose mirror failing - it is the **ownership model**. The npc module lets the copy whose hero
is nearer simulate an NPC (its own AI decides what it does) and the other copy mirrors the bones. So the
copy that owns an NPC runs its own behaviour, and "what the NPC is doing" (sitting at a work spot, whittling,
patrolling) is never synchronised - only where his bones are.

Consequences: idle behaviour can differ, and it differs the most exactly when both players are near the same
NPC and the ownership moves between them.

**Diagnosis that is already available:** `N owner of <id> -> seat N (<why>)` is logged on every ownership
change, and the diag lines carry the nearest NPC's clip. Reproduce, then look for the whittling NPC's id:
if it flips between seats, the ownership model is the cause; if it stays on one seat and the other copy
still shows a different pose, the bone mirror is not being applied.

**Possible directions**

1. force the **host** to own every NPC (drop the nearest-hero rule), so at least one copy is always the
   authority and the other only ever mirrors;
2. sync the NPC's **state tag / current montage** from the owner and replay it on the mirror (the module
   already sends the montage name for the nearest NPC - extending that to the action state is the natural
   next step);
3. accept it as a known limitation: it is visual, and it does not affect combat, health or quests.

## A journal entry arrives without the "new entry" banner (2026-11-06, known limitation)

The entry itself synchronises: `S journal: '<segment>' unlocked here (from the other player, ok)` and the dump
(`build\journal_dump.txt` makes each copy write its whole unlocked list) showed 19 entries on the guest,
including the ones unlocked during the session. What does not happen on the receiving copy is the popup that the
game normally shows when a document is discovered.

Why: the unlock is a plain `UDocument::RememberSegmentUnlocked` through the `UnlockDocumentSegment` mixin
(`GAS/GASCharacterStateMixins.as:1502`), and **no script shows a notification** - a search of the decompiled tree
finds the unlock call in hundreds of conversations and quests, but no notification call next to it. The banner is
raised by native/UI code from an event our direct write does not produce.

The game does expose `HUDNotificationController::AddNotification` / `AddNotificationSoft`, so it could be raised by
hand, but the notification data is a struct we would have to fill correctly - not worth it for a cosmetic popup.
Journal entries are visible in the journal; only the popup is missing.

## The mirrored player's face is deformed (2026-11-06, open)

Seen from the host, the guest's character (Fingers) has a grotesquely stretched face - eyes bulging out,
the mouth and nose pulled - while the body and clothes look right. Reported with a screenshot: the
deformation is on the copy that does **not** own the character.

What was checked:

* the character has **one** skeletal mesh (`CharacterMesh0`, a GothicSkeletalMeshComponent, 425 bones); the
  attached children are only collision capsules, so there is **no separate face mesh**;
* the pose sender transfers all 425 bones (the blob is 5104 bytes = 425 x 12 + the header), so nothing is
  dropped on the way out;
* the receiving side applies the bones it can match by name.

So the data is sent and the body follows it, which leaves two suspects:

1. **the facial bones get wrong transforms on the receiving side** - they are small bones, and the rotations
   travel as quantised 16-bit values, so precision or an axis mix-up would show up on the face first;
2. **morph targets / blend shapes** - a UE5 face is often animated by curves rather than bones, and if the
   puppet's morphs sit at an extreme value that is exactly what this looks like.

Next step when this is picked up: on the host, dump the puppet's facial bone names and transforms and compare
them with the guest's own copy (the pose module already logs "P child" for the mesh's components and the
receiver prints how many bones it applied). That decides bones versus morphs; the fix differs completely.

Measured on 2026-11-07 16:30 (story/pose build `2f557975`, session of the same day): the sender's own diagnostic
`P diag bone` flagged **60 distinct bones** whose local transform comes back as identity-at-origin
(`loc 0 0 0`, `quat 0 0 0 1`), among them `eye_l`, `eye_r`, `Jaw`, `helmet`, `hood`, `horn_r`, `breastbone`,
`chestpiece`, the whole `rib_01..06_l/r` set, `belt_01..03`, `bag_r_01/02`, `kneecap_*`, `radius_*`, `fibula_*`,
`lowerarmarmor_*`, `armorboot_01_*`, `footarmorboot_01_*`, `legarmorboot_01_*`, `ik_foot_root`, `ik_hand_root`.
`P bad bone` stayed at 0 and no bone had a scale other than 1, so the data is not corrupt - these bones simply
carry no pose on this mesh, and the receiver skips them, which leaves the face and the armour pieces at the
reference pose. That supports suspect 1 (per-bone transforms), not morph targets.

## `<MISSING STRING TABLE ENTRY>` in the HUD quest tracker (2026-11-06, open)

On the guest the top-left quest tracker shows `<MISSING STRING TABLE ENTRY>` with a fragment of text under it.
Screenshots show that **the quest names themselves are fine** in the journal (Призрачный шанс, Приглашение в
старый лагерь, Кольцо для Фингера, Рецепт Снафа, Письмо от магов огня), so this is not a broken UI and not a
missing language: it is the **objective line** of one quest that has no Russian string.

Context at the time: the guest was running `Quest_OldCamp_OCCHAPTER1_MAGICTRANSACTION` (Torrez's magic
transaction), which had reached the guest through the quest sync at 19:44 and whose `..._OBJ_RETURN` objective
followed at 19:45. The game is in Russian (`m_DisplayLanguage=Russian`, `m_VoiceOverLanguage=Russian`), the
guest's hero was alive, no exceptions in the log, and there was no double load.

**Open question:** does the *host* show the same entry for the same quest? If the host is fine, the objective's
localised text is not being picked up when a quest is started through the synchronisation (we call the game's
`StartQuest` on the receiving copy); if the host is broken too, it is a gap in the game's own Russian
localisation for that objective and the mod is not involved.

#### After the component rebuild: the creature is drawn, its placement is wrong (same evening)

The driven component is recreated when the puppet's mesh asset changes (`P the puppet's mesh changed, rebuilding the
driven component`), so the swapped mesh is the one actually drawn. With a bloodfly the guest now shows a bloodfly
instead of a human - but it **lies on the ground and does not follow the host**, while on the host side the
transformed player moves normally.

That splits the remaining problem in two:

1. **placement/orientation**: the creature is drawn lying down, so the driven component's transform relative to the
   puppet is not right for this rig (the human mesh happened to line up; the creature's mesh/root does not). Worth
   comparing the driven component's relative transform with the source mesh's on the sending side;
2. **position following**: the puppet actor's position comes from the core's remote position, which still tracks the
   right actor, so this is probably a consequence of (1) - the mesh is offset/rotated away from the actor.

#### The creature now arrives almost intact (same evening)

After three fixes the transformed player is visible on the other copy and **almost one to one**:

1. **the receiver keeps its own bone list** (`R`, resolved from the puppet's mesh) instead of the local hero's -
   with one shared list, the host turning into a creature made the *guest's* animation freeze, which is why it
   looked "wooden";
2. **the transform range comes from the puppet's skeleton** (`for (int i = 0; i < R.nb ...)`); it used the local
   hero's count (425) and wrote bone indices far past the end of a 53 bone creature, which is exactly the broken
   shape that was seen;
3. **the interpolation state is reset when the skeleton changes** (`interp_reset()` inside the receiver's resolve) -
   otherwise the creature's pose started from the human's rotations and converged with a visible twist.

State now: the host is a wolf, the guest's copy draws a wolf that repeats his movement
(`P received pose ... (53 bones ...)`, about 38 bones smoothed per frame), and both directions work
(`425 bones` back when the transformation ends).

What is still off: **the head is turned the wrong way** and there are small inaccuracies. The body matches well, so
the suspects are the creature's head/neck bones (possibly animated by a look-at system, or carrying a non-1 scale
that the sparse scale channel does not cover) - worth dumping those few bones' transforms on both copies.

#### Next attempt: the mesh travels, the pose is still twisted (same evening)

What works now, all confirmed in the log:

* the core follows the possessed pawn both ways - `HERO: the player now controls 'CharacterCanTransformInto_Wolf_C'`
  when transforming and back to `PlayerCharacterBP_C` when it ends;
* when the hero's skeleton changes, the sender reports the mesh: `S poly: my skeleton changed to 53 bones, mesh
  'Wolf/SK_wolf' sent`. The Mutable generated human mesh has no package path, so the sender maps "no path" to the
  word `human` and the receiver restores its own hero's mesh from that;
* the receiver loads and sets the mesh: `S poly: loading '/Game/Assets/Characters/Creatures/Wolf/SK_wolf'` then
  `the puppet's mesh is now 'Wolf/SK_wolf' (ok)`, and its own bone list is rebuilt from the puppet
  (`P receive: the puppet has 53 bones, first 'Root'`);
* the pose stream follows: `P received pose #6001 (53 bones ...)` and about 40 bones are smoothed per frame.

What is still wrong: the creature is drawn **twisted** - the body looks broken. The bones are applied (the counts
match, the smoothing runs), so the remaining suspects are the transform space of the creature's bones (the sender
uses `RTS_Component` / `RTS_ParentBoneSpace`, which may not hold for this rig), the sparse non-1 scales (the sender
reported `4 bones with scale != 1` for a creature earlier), or root motion on the creature's root bone.

Checked again on 2026-11-07 (build `2f557975`): the path rule the sender relies on is right - real creature meshes do
live under `/Game/Assets/Characters/Creatures/`, verified with `SkeletalMesh` objects and `pkg`: `Scavenger/SK_Scavenger_Med_LOD5`,
`Meatbug/SK_Meatbug_LOD5`. (`SK_Fire_Scavenger` is under `/Game/Assets/Environment/General/Food/`, so a `findall` hit can
belong to a prop, not a creature.) So the "mesh 'X' sent" branch is not the weak point; the twisted draw is.

### Transformation: the core follows the new pawn now (2026-11-06, in progress)

Measurements that changed the picture:

* a transformation does **not** swap the hero's mesh - the game **possesses a different actor**. With the player
  turned into a bloodfly, the player controller's `Pawn` property pointed at
  `CharacterCanTransformInto_Bloodfly_C_...` (found through `PlayerController::AcknowledgedPawn` / `Pawn`, not
  through `GetPawn` - that is not a UFUNCTION here);
* the mod kept mirroring the old hero, so the other copy saw a human standing still.

The core now follows the controller's `Pawn`: every two seconds it reads the property, and when it differs from the
hero it switches to it (`HERO: the player now controls '...' (a transformation?), following it`, and the pose sender
immediately reported `P sender: 56 bones, first 'Root' 'Pelvis' 'backleg_01_r'`). `build\no_hero_follow.txt`
switches this off.

**Where it stops:** after the switch the guest stops receiving poses altogether - the last line is
`P received pose #1401 (425 bones ...)` from before the transformation. The receiving side evidently rejects a blob
whose bone count differs from its own, and the puppet stays a human. Two things are needed next:

1. let the pose receiver accept a different bone count and re-resolve its own bone list (the sender already
   restarts its list when the count changes);
2. swap the puppet's mesh to the creature's mesh: the sender has to send the skeletal mesh asset (name and, if it is
   not a plain asset, its package path) and the receiver has to load it and call `SetSkeletalMesh` on the puppet
   before applying the bones.

## Transformation (polymorph) is not mirrored correctly, and death after it does not load (2026-11-06, open)

Two problems seen in the same test:

**1. The transformed hero is mangled on the other copy.** The host turned into a mole rat (кротокрыс). On the
guest the result is not a mole rat: the screenshot shows a human body sitting with its neck/head stretched into a
long vertical spike - the human skeleton being posed with data meant for a creature, or the creature mesh with
the human animation. The guest's copy never sees a proper creature.

Why this is expected with the current design: the pose mirror resolves the bone list **once per mesh** and only
re-resolves when the bone count changes (`pose_module.c`, "the hero mesh is rebuilt when the outfit changes"). A
transformation swaps the whole skeletal mesh (different skeleton, different bone names), and the *puppet* on the
other copy is a separate actor whose mesh is chosen by the game - we mirror bones, we never swap a mesh. So the
puppet keeps its human mesh and receives creature bone transforms (or the other way round), which is exactly the
stretched shape in the screenshot.

**2. The shared death did not fire.** When the transformed hero died, neither copy loaded - the "one dies, both
see the death screen and load together" path did not run. The likely reason is that the death check reads the
hero's health/defeated state from the human character, and after a transformation the hero is a different actor
(or its health lives on a different attribute set), so the condition never becomes true.

Next steps when this is picked up:

* log what the pose sender resolves when the bone count changes, and whether the receiver ever re-resolves its
  own bone list (the puppet's mesh cannot change, so the creature's bones have to be **matched by name** where
  possible and the rest skipped);
* find how the game represents the transformed actor (a new actor? the same pawn with a swapped mesh?) and have
  the puppet swap its mesh the same way, or hide the puppet and show a plain creature;
* for the death path, make the death detection independent of the hero's mesh: the transformed state should keep
  the same player state / health set, and the log will show which lookup fails.

## FIXED: a dead NPC stayed on its feet on the other copy (2026-11-06)

On the copy that mirrors an NPC, the NPC turned dead in the data (`IsDead` was 1 on all three scavengers) but the
body stood upright. Reason: a mirror is frozen and driven by us, so the game never ran its own death visuals -
health and the death flag were written, the animation was not played.

Two paths needed the same treatment and now have it:

* the "already dead" path, where the mirror notices the owner's death flag;
* the "kill effect" path, where the module applies `GameplayEffect_KillCharacter` to the mirror itself.

Both now hand the body back (`release`) and switch the skeleton to physics (`SetSimulatePhysics(bSimulate)` and
`SetAllBodiesSimulatePhysics(bNewSimulate)`), so the corpse falls. Confirmed in play from both seats: spell damage
from the guest and from the host, the body falls on either copy, and the log shows the kill effect reported `ok`.

## Light: the friend's light cannot be reproduced properly (2026-11-06, unfinished)

Status after a long session of trying, all measured on the running game:

* **the game spawns `BP_LightSpellVisual` only on the copy that casts.** After a clean restart the guest had
  **0** instances while the host had 1, so there is nothing on the friend's copy to re-bind;
* **re-binding the game's actor works only while one player holds a light.** The light then looks exactly right
  (it is the game's own actor), but the two casts share that one actor, so the second cast takes it over;
* **spawning our own copy does not work**: `a->spawn_actor` returns NULL for that blueprint even when the class
  is resolved and loaded by path (`/Game/Items/Magic/Light/BP_LightSpellVisual`) - the debug spawn logged
  `probe spawn 0000000000000000`. A plain `PointLight` can be spawned instead, but it gives illumination only:
  no glow object and no animation;
* the class *is* only loaded on the casting copy, which is why loading it by path was added at all.

So today the honest state is: a single light works if it is re-bound (the version that was in the build before
this attempt), and a second simultaneous light cannot be shown. The animated glow of the friend's light needs a
different approach than spawning the blueprint - most likely the game's own spawn path (an ability or a gameplay
cue) or an explicit Niagara component configured the way the blueprint does it.

## Light: two casts fight over one actor (2026-11-06, open)

After the fix that rebinds the friend's light to his puppet, the light works - but only when **one** of the two
players holds it. Reported in play:

* the caster can cancel his own light and it disappears;
* if the host is holding a light and the guest casts Light at the same moment, the light **jumps to the guest**
  instead of continuing on the host and starting a second one.

Reason: the game keeps **one** `BP_LightSpellVisual` actor per copy and binds it to the local hero (`OwnerMesh`).
Our fix rebinds that same actor to the puppet when the friend casts, so the two casts share one actor and the last
one wins.

The fix that fits the machinery: do not move the game's actor - spawn **our own** `BP_LightSpellVisual` instance
for the friend (`a->spawn_actor` already exists, the equip module spawns visuals that way), bind its `OwnerMesh` to
the puppet's mesh, and destroy it when the friend's light ends. Then the own light stays on the own hero and the
friend's light lives on its own actor.

## Spell effects with a visual of their own are local only (Light, 2026-11-06)

Casting **Light** makes the caster's surroundings bright on his own copy only; on the other copy nothing changes.
This is the general "the spell itself is not reproduced" problem above, but Light is the most promising one to fix
first: it has no projectile and no hit, it is a light (and probably a small VFX actor) attached to the caster, and
it lasts.

Why it happens is the same story: the game spawns the light from the ability/spell config, which is script-bound,
and nothing of that crosses the wire. The rune itself synchronises - the equip module already spawns
`BP_ItAr_Rune_Light_Visual`-style actors in the caster's hand on the other copy - so *spawning a visual actor on
the other copy exists as a mechanism*; what is missing is knowing that the light is "on" and keeping it attached
while the spell lasts.

Practical next step: find the actor (or light component) the caster's copy gets when Light is applied - list the
actors that appear around the hero between a cast and five seconds after - then spawn the same class on the other
copy attached to the puppet's head, and destroy it when the spell's effect ends on the caster (or after the same
duration the game uses).

## Magic: what works and what was left unfinished (2026-11-06)

**Works, checked in play from both seats**

* spell damage on **NPCs** travels both ways through the existing hit/health path: the caster's copy reports the
  exact drop (`N dmg: mirror <id> lost N hp here, sent to the owner`), the owner applies it and runs the game's
  kill effect (`N dmg: kill effect ... ok`);
* a dead NPC falls over on both copies (the body is released and switched to physics);
* the remote caster's **motion** is visible, because the pose module drives the body by bones. The cast *clip* is
  deliberately not played: the puppet's mesh is hidden while the pose module owns it, and the anim module pauses
  clips for that reason (`M clip mesh hidden: clips paused`).

**Not finished**

1. **The spell itself is not reproduced on the other copy.** No fireball, no projectile, no muzzle flash, no
   sound. The game spawns those from the ability, which is script-bound. A realistic next step is to spawn the
   visual actor ourselves when the remote player's action name says he casts (the equip module already spawns
   `BP_ItAr_Rune_Firebolt_Visual_C` for the rune in his hand, so the spawning machinery exists).
2. **Damage to the other player** does not happen: his character is the puppet, a plain `SkeletalMeshActor` with
   no character capsule, and projectiles pass straight through (collision was switched on for the mesh and it
   did not help). Recorded in `docs/IDEAS.md` with four directions, including the one that needs no collision at
   all - report the hit from the caster's side and apply the damage on the victim's own hero.
3. **Magic between players is therefore untested** end to end: nothing has ever been damaged by magic across the
   two copies except NPCs.

## Co-op core and flow
- SKELETON: shared death (5 runs, both directions), clock sync, save/F9 sync.
- OPEN: two-PC test over Radmin (needs save-file transfer and the menu button that opens the port with a localized status).
- OPEN: shared XP for kills (idea).
- OPEN: puppet head and pickaxe look bent while moving.
- OPEN (rare, caught): access violations inside the story module while it builds a packet
  (`send_blob+0x8a`, seen as `call=none module=story`, addresses like `0x8414b230d` and `0xa5f161`).
  A few per hour, one per event, the game continues. Not reproducible on demand; the code it runs
  touches only module state plus `set_local_blob3`, so the fault is probably in the core side of that
  call. They are recorded by `tools\load_audit.ps1`, which counts only NEW ones since its last run.
  The equipment ones (`K2_AttachToComponent`, exe+0x363628e) were addressed by the 5 s quiet period
  after a world change in `equip_module.c` - no new ones since.
- FIXED 2026-11-05: the new `probe near` command faulted on objects that report an Actor in their
  class chain but have no `K2_GetActorLocation` (`reading address 0x10`). Every object is now handled
  inside its own `__try`; verified with three runs, no new faults.

## Game updates
- Build 1.2 (exe 175124992): core profile added; both copies run; see `PATCHES_AND_BUILDS.md`. Every update needs a new profile (GUObjectArray, name pool, ProcessEvent slot, audio guard); automation is still a deferred task.

## Test aids to remove later
- Lite graphics (`-ExecCmds` in `start_coop_11.ps1`), `give_*.txt`, `time_sync_off.txt` (clock frozen at 07:00 locally), bisect switch files, `story_noscan.txt` etc.

## Two-PC test (prepared 2026-11-05)
- PREPARED: `docs/TWO_PC_TEST.md` and `tools/start_net.ps1` (one command per PC). The mod no longer has the developer folder compiled in: modules find `nativeuild` from their own location (`native/buildpath.h`, `bp()`), the core uses its own folder (`g_dir`) incl. gate_off/role files (core `coopdll_84`). Not yet run on a second PC. Save files are NOT transferred by the mod (copy the SaveGames folder by hand).

## Network emulation findings (2026-11-06; core 85/86, `net_sim.txt`, `scenario_netevents.ps1`)
- FIXED (retested 3 runs, guard fired 3 times): retransmitted acknowledged events (death 11, last save 12, drop 14, chest 4-8, ...) were applied again AFTER a world load, because the module restart clears the in-memory list. Applied ids now persist in `applied_lids.txt` (`pid:lid`).
- FIXED (one run, not repeated): the game calls `GameOverWidget::LoadLastSave` twice about 1 s apart; the host sent two load events and the guest loaded twice (the double load that kills the UI). Now one per 20 s (`lastsave_t.txt`).
- OPEN (seen once in 6 runs): after a shared-death kill the guest hero was dead (`IsDead` = 1) but NO death screen was created on it (no `S death screen` lines); the host's later "load last save" found no screen, the guest stayed dead until a manual F9. Not understood; idea: if the hero is dead for 20 s without a death screen, load the last save ourselves.
- Measured: death arrives in 1.5-1.6 s and the load in 0.5-1.0 s at 30-35 % loss + 100 ms delay.
- The teleport jump test (`-Jump`) can drop the hero out of the world: use only on purpose.

## OPEN (found 2026-11-07 19:03): package 0.5.0 lost the "game is running" guard

**Symptom.** `dist\Gothic1Coop-Setup-0.5.0\Setup.ps1` installs while Gothic 1 Remake is running. The release package
`0.4.2.75` refuses first:

```powershell
# 0.4.2.75, Install-Mod()
if (Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue) {
    throw "Игра запущена. Закройте Gothic 1 Remake и нажмите «Установить» ещё раз — файлы мода заняты запущенной игрой."
}
```

**Found by.** `tools\test_install_cycle.ps1 -AllowSideEffects`: the guard check failed against 0.5.0 (silent install
completed, `silent install done` in the log, app folder created) and passed against 0.4.2.75.

**Why it matters.** The mod's DLLs are loaded by the running game; the installer swaps `app` -> `app.new` and back.
Installing over a running copy is how a half-replaced module set appears, and a half-replaced set is exactly the state
that produces "random" bugs (the version check then reports MISMATCH, but the damage is already done).

**Fix.** Restore the guard at the top of `Install-Mod` in 0.5.0 (and check that the silent path goes through the same
function). A regression test already exists: `tools\test_install_cycle.ps1 -AllowSideEffects` fails without it.

## OPEN (found 2026-11-07 19:12): pressing load again before the friend finished breaks the shared load

**Symptom (user report + logs).** Five F9 presses about 19 s apart produced **five loads on the host and one on the guest**:

```
host:  19:11:23, 19:11:42, 19:12:00, 19:12:19, 19:12:38   S load: a new hero
guest: 19:11:32                                            S load: a new hero
```

The guest was still inside its loading screen when the next press arrived. After that, further loads happened only on the
host: the two worlds now have different "loaded at" state, and the guest keeps NPC/item state the host reset.

**Why it matters.** The whole point of the shared load is that both copies come back at the same save. A host that reloads
alone resets NPCs, chests and drops, while the guest keeps its own - the classic silent divergence that later looks like
"items disappeared" or "an NPC is alive for one player".

**Not a test-tool bug alone.** `tools\test_load_loop.ps1` did press on a timer without watching the guest; it now waits for
BOTH copies and stops if the friend does not follow. But the mod itself silently drops the guest's load when it is still
loading, instead of queueing it or telling the host "the friend is not ready".

**Possible fixes (decision needed).**
1. Cheapest: the host refuses to start a load while `S load` is still pending on the other copy, and prints why.
2. Better: queue the load - apply it when the guest reports its load finished.
3. Minimum: log a loud line when a load is dropped for this reason, so it is never silent.

**Rule until fixed.** Never press F9 (or use "load") again until both copies are back in the world.

## OPEN (measured 2026-11-07 19:31-19:32): a load pressed during the friend's cooldown is refused, and the host used to learn nothing

**Correction to the first version of this entry.** The refusal was never silent: `load_apply` has a deliberate
`LOAD_COOLDOWN_MS = 120000` guard and logs it on the copy that refuses:

```
[2348 19:32:21.948] S load: 'Q' ignored, another load started 70 s ago (cooldown 120 s)
```

The real gap was that this line exists **only in the guest's log**. The host reloaded alone and had nothing that explained
why the two worlds drifted apart.

**Fixed the same evening (build 33cb5968).** The refusing copy now sends event `type 31` with the seconds left, and the
other side logs:

```
[36388 19:38:30.186] S load: THE FRIEND REFUSED the load (cooldown 49 s left) - it did NOT reload, expect its world to differ
```

**Still open: should a refused load be replayed instead?** Right now it is dropped, so a player who presses too early stays
behind. A queue of depth 1 (apply the last refused load when the cooldown ends) would be friendlier, but it changes load
behaviour and needs its own test; the cooldown exists because without it repeated loads ping-ponged and killed the UI.

**Evidence (both logs, same run): the guest received the second request and refused it by cooldown.**

```
host  19:31:12  S load: F9 (quick load) pressed here, slot Q      guest 19:31:11  type 9 'Q' (new)
host  19:31:21  S load: a new hero                                guest 19:31:29  S load: a new hero     <- shared, ok
host  19:32:22  S load: F9 pressed, slot Q                        guest 19:32:21  type 9 'Q' (new)
host  19:32:33  S load: a new hero                                guest  --- nothing ---                 <- dropped
```

The guest received the second request, logged it as a new event (`type 9`, not a duplicate), and then did nothing: no
`StartLoadingSave`, no `a new hero`, no complaint. The host reloaded alone.

**Timing.** The second press came 93 s after the first, and 53 s after the guest's own load started. The guest's loading
screen is about 25-40 s, so the request arrived around the moment its own load was finishing - the most likely cause is that
the guest still considered itself "loading" and silently ignored the request instead of queueing it.

**Why this matters.** This is the mechanism behind "the friend stays behind after a reload": the host's world resets
(NPCs, chests, drops), the guest keeps its own, and nothing in either log says a load was skipped.

**Same root as the 19:11 finding** (five presses, one guest load): the load path has no queue and no rejection message.

**Fix options.**
1. On the guest, if a load request arrives while loading, remember the LAST one and apply it as soon as the current load
   finishes (queue of depth 1).
2. If queueing is too risky, log `S load: request ignored, still loading` and have the host show it - silence is the worst
   option.
3. Test that reproduces it: `tools\test_load_loop.ps1 -Count 2 -IUnderstand -Peer <ip>`; it stops at the first press the
   friend does not follow and prints the counts.

**Rule until fixed.** One load at a time: wait until BOTH copies are back in the world (the guest's `a new hero` plus
~40 s) before pressing again.
