# Ideas and nice-to-haves

Things that are not bugs and not urgent - recorded so they are not lost.

## Shipped (2026-11-07)

* **version handshake** - both copies hash their module set, exchange it on first contact and shout `MISMATCH` plus a
  `version_mismatch.txt` file (0.4.2.60);
* **status in the window title** - `[ХОСТ / HOST] 30 fps | friend 42 m | link ok` (0.4.2.61);
* **online test harness** - `tools/cooptest.ps1`, invariants across two PCs and guided scenarios
  (`docs/ONLINE_TESTING.md`).

## Next release, already decided

### Localize the "no host found" warning (small, do it first)

Reported from play: when the guest presses **Join** and nothing answers, the message he gets is not localized - it is the
English log line only. Everything the player sees must be in the language the game runs in, the same way the button
label already is (`JOIN_LABEL`, ten languages).

Plan:

* add a `NO_HOST_LABEL[10]` table next to `JOIN_LABEL` with the same ten languages (english, german, french, spanish,
  schinese, italian, japanese, polish, brazilian, russian), short enough for the button - for example "No host found" /
  "Хост не найден";
* on a failed search, put that text **on the button itself** (`set_label2`), so the player sees it without the log, and
  restore the normal label on the next press or after a few seconds;
* keep the detailed English line in the log for diagnostics (it names UDP 40002, the launcher and the network).

## Next, in the order I would do them

Each of these needs its own session and a check with `tools/cooptest.ps1` after it - the two areas below (widgets and
networking) are exactly where a mistake is silent.

### 1. HUD widget with the session state (half a day)

A small text block in a corner instead of the window title: friend's name, distance, health, "in trade"/"asleep"/"dead",
link quality. The title already proves the data is there; the work is creating a widget and filling it **without**
touching the input mode - that very call once left a session where no key or mouse reached the game, so the widget must
be created only when a world is loaded and removed when it goes away.

### 2. Health bars over mirrored NPCs (half a day)

The NPC records already carry HP, so a mirror knows how hurt an enemy is. Draw a small bar above it. Value: in a
two-player fight nobody can tell whether the friend's target is almost down.

### 3. Ping / waypoint for the friend (half a day)

A hotkey drops a marker in the world; the other copy shows an arrow on the compass and the distance (the distance half is
already in the title). The key poll exists (`any_key_poll`), the world-marker part is the new work.

### 4. Text chat through the event channel (2-3 hours)

The channel already carries strings; display them with **our own** text (not localized), which also sidesteps the
`<MISSING STRING TABLE ENTRY>` problem. Start as a line in the window title, then move it to the HUD widget from (1).

### 5. Reconnect without restarting both games (a day)

Today a dropped link means restarting both copies. The "first contact" logic (story block, clock, NPC set) can be re-run
on command instead of only at startup; the risky part is making sure nothing is applied twice.

### 6. "Wounded, not dead" instead of shared death (a day)

One player goes down, the other revives him by standing close for a few seconds. Shared death stays as an option. This
changes the feel of a playthrough more than anything else on this list.

### 7. Save handoff on exit (2-3 hours)

`save_transfer` already moves the save from host to guest at start. The missing half is the way back: when the session
ends, publish the newest save from the machine that has it, so the next session cannot begin with two different worlds
(and with the modlist dialog).

## Let the other player be hit by spells (the puppet has no collision)

Casting at the other player's character does nothing: the projectile flies straight through. The other player's
character is the **puppet**, a plain `SkeletalMeshActor` with the hero's Mutable-generated mesh (see `n2.inc`,
`T.puppet_char == 2`), so it has no character capsule and its collision was off.

Tried on 2026-11-06: on the puppet's mesh, `SetCollisionEnabled(1)`, `SetCollisionResponseToAllChannels(2)` and
`SetCollisionObjectType(2)` - all three report `ok`, and the projectiles still pass through.

Next ideas, cheapest first:

1. log the mesh's collision state right after the game tick - the core un-hides the puppet every tick, and that
   path may reset the component;
2. find out what the spell actually queries (a swept sphere against skeletal meshes, or a line trace against a
   capsule) - the answer decides whether a mesh can ever block it;
3. attach a real collision capsule to the puppet, the way the npc module already attaches capsules to characters,
   and make it block the projectile channel;
4. if damage is the goal rather than the visual: when the caster's copy registers a hit on the puppet, send the
   damage to the other player's own hero and apply it there - that works whatever the projectile does, because it
   does not need collision at all on the receiving side.

The user's verdict: not important right now, recorded as an idea.
