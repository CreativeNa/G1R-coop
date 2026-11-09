# Current state — 0.4.2.51 (night of 2026-11-06/07)

**Readiness: about 65%.** The mod runs a real session between two PCs and most of what it claims to do works, but this is
not a finished build: parts of it are held together by measurements taken minutes ago, and several behaviours were fixed,
re-broken and fixed again within one night.

## Verified on the pair (both logs, not by eye)

* connection over Radmin, roles (host/guest), reconnection;
* one clock authority, sleep (dark screen plus the time after it), morning;
* player poses (425 bones) and the puppet's facing;
* NPC mirroring: position, facing with the mesh's own offset, sitting clips, bone-driven defeated NPCs;
* combat: damage both ways, death, corpse release, and the shared death plus shared load;
* chests with the "in use" lock, loose world items, ore/items without a persistent id;
* quests, story words, journal, chapter banners, trade windows;
* hero progression (level, experience, skill points, strength, dexterity, max health) following the host.

## Still open (see `docs/BUGS.md` for the details)

* interaction props (cooking pan) and harvesting do not travel;
* a corpse lands in a different place on the two copies (the ragdoll is simulated twice);
* the mirrored player's face is deformed;
* notifications and rune names show a missing localization string;
* the "different modlist" dialog is fixed by keeping the descriptor version constant, but it was not re-tested on a save
  made before this build;
* two expensive polls remain in the story module (`trade_poll` ~30 ms, `trade_lock_watch` ~25 ms every few seconds);
* the dark screen arrives about a second after the sleeper's own fade - the game's fade cannot be detected yet.

## Why 65% and not more

Everything above was verified in short bursts on one evening. Several areas were touched in the same night they were
measured, so the newest code (sleep, time, item keys, the mod descriptor, the NPC rig) has been seen working exactly once,
sometimes twice, and then changed again. A build like that earns trust only by being played for hours.

## What to test first, in this order

1. **Sleep, six or seven times**, alternating who sleeps: the dark screen should appear for the other player only when the
   sleeper actually lies down, and both should end up at the same hour.
2. **Items without a persistent id** (ore, mutton, food): pick them up from both sides, then check that they disappear on
   the other copy within a couple of seconds.
3. **Sitting and lying NPCs**: a seated digger must stay seated on the mirror and must not bob; a defeated NPC must not
   stand up.
4. **Long session, two hours or more**: watch for exceptions in `coopdll.log` (there should be none), for a growing NPC
   "missing" count, and for the frame cost (`M cost ms` should stay near 2-3 ms).
5. **Death and load**, both directions, twice each.
