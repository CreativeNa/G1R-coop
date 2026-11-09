# Where the work stands — written at the end of the night of 2026-11-06/07

The session ended with the trade stock still being verified. Everything else that was found is either fixed or recorded in
`docs/BUGS.md`. This page is the short version for whoever picks the work up next.

## The very next thing

**Install 0.4.2.58 on both PCs and make one purchase at Mordrag.** The last log (before 0.4.2.58) showed two streams of
stock updates fighting each other:

```
host  (0.4.2.57): S trade here: 24 items:                      <- 24 items, not a single readable name
guest (0.4.2.57): S trade: the next stock update is for 'OC_ORG_Mordrag_826' (position 15 here)
```

Two causes were found in that one night and fixed in that order:

1. **both copies sent their stock.** `trade_poll` only sends while a trade window is open on that copy now (0.4.2.57);
2. **a closed trade's config still answered**, with garbage where the item array is, and that stream looked like a valid
   stock update to the other copy (0.4.2.58 refuses to describe a trader whose items cannot be named).

What to expect if it works, in the guest's log:

```
S trade: the next stock update is for 'OC_ORG_Mordrag_826' (position 15 here)
S trade: trader #15 updated here (24/24 items, purse ...)
```

If it still says `has a different item order here`, the next step is `trade_dump.txt` on both PCs (an empty file is
enough) and one purchase: the two `S trade here:` lines list the item classes on each side, and the difference will be
visible instead of guessed.

## Also fixed this night, in release order

| Release | What |
|---|---|
| 0.4.2.52 | the death screen no longer switches the input mode - that call could leave a session with no input at all |
| 0.4.2.53 | trade stock written in a sorted order |
| 0.4.2.54 | trade diagnostics (`trade_dump.txt`) |
| 0.4.2.55 | trade polls stop costing 40-49 ms: order independent hash, no object scan per lock check |
| 0.4.2.56 | the merchant is identified by name, not by his index in the manager |
| 0.4.2.57 | only the copy with an open window sends its stock |
| 0.4.2.58 | a stale trader config (no readable items) is never sent |

Measured after the performance work: the whole mod costs about **2 ms per frame** (`story` 0.45-0.52 ms with worst
calls of 1.0-1.9 ms, `pose` 0.6, `npc` 0.5-0.7).

## What is still open (see `docs/BUGS.md`)

* interaction props (cooking pan) and harvesting are not mirrored;
* a corpse lands in a different place on the two copies (the ragdoll is simulated twice) - a decision is needed;
* NPC scripts fire for both players (a reminder, an ore demand) - a decision is needed;
* the "the NPC took your items" message does not appear, and notifications show a missing localization string;
* the mirrored player's face is deformed;
* transformation (polymorph) is not mirrored and death after it does not load;
* two light casts fight over one actor;
* the dark screen arrives about a second after the sleeper's own fade (the game's fade is not detected yet).

## What has never been tested for long

The build is rated about **65%** in `docs/STATUS.md` for a reason: almost everything was verified in short bursts, and
the newest code (sleep, trade, the mod descriptor, the input mode) was changed in the same night it was measured. The
list of what to test first is in `docs/STATUS.md`; the short version is: sleep six or seven times alternating who sleeps,
items without a persistent id, seated and defeated NPCs, two hours of play watching for exceptions and the frame cost,
and death plus load in both directions.
