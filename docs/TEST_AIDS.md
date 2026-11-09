# Test aids: giving items, spawning, moving actors

Small in-game helpers that need no code change. They work while the game is running: the module polls
for a command file once a second, executes it and deletes the file.

## Give an item to a hero

Write one line into a file in `native\build\`:

| File | Copy it goes to |
|---|---|
| `give_host.txt` | the host (seat 0) |
| `give_guest.txt` | the guest (seat 1) |

Format: `<item definition name> <amount>`. The amount is optional (default 1).

```powershell
Set-Content native\build\give_host.txt  "ItMw_1H_Torch 15"
Set-Content native\build\give_guest.txt "ItMw_1H_Torch 15"
```

Rules that matter:

* **one command per file** — the file is deleted after it is read; writing a second command too early
  just overwrites the first one. Wait ~3 seconds between two different items;
* the name is an **item definition class**, not an asset path. The torch, for example, is
  `ItMw_1H_Torch` (there is also `ItMw_1H_Torch_Gob`).

### Verify

```
S give: item 'ItMw_1H_Torch' (object ItMw_1H_Torch) added to this hero (called, items 17 -> 17)
```

`items A -> B` is the number of **entries** in the inventory, not the amount: `17 -> 17` means the
item merged into an existing stack (it was already there, now +15). If the line says
`item ... not added (module ..., definition 0)`, the definition name is wrong.

### If the item does not show up

* it may have gone into an existing stack — open the inventory and look at the amount;
* an item of the weapon type may land in the **weapon slot**, not in the bag — check that tab.

### Finding the right definition name

```powershell
# in the SDK dump
Select-String sdk\classes.tsv -Pattern 'Torch'
# or ask the running game
.\tools\dev.ps1 probe "@0 findall Torch"
```

## Drop an item on the ground next to the hero

Same files, prefix the command with `dropnear:`:

```powershell
Set-Content native\build\give_host.txt "dropnear:ItMw_1H_Torch"
```

The item appears the way a dropped item of the other player does.

## Spawning actors through the console does NOT work

`probe "cc summon ..."` executes (the console command runs) but nothing is created — the cheat
manager is disabled in this shipping build. Verified with `BP_Torch_Mine_C` and `PointLight`: no new
actor within 700 units. Do not spend time on `summon`; use the item helpers above.

## Moving actors

```powershell
.\tools\dev.ps1 probe "@0 tp hero 120640 -87830 -5242"      # teleport an actor to coordinates
.\tools\dev.ps1 probe "@0 tpto hero <target ptr> 150"        # teleport next to another actor
.\tools\dev.ps1 probe "@0 heroinfo"                          # where the hero is
```

To bring the two heroes together, read the host's position with `heroinfo`, then `tp hero <x+150> <y> <z>`
on the guest.

## Game clock

```powershell
# find the subsystem, then set the time of day (morning, for example)
.\tools\dev.ps1 probe "@0 findall GameTimeSubsystem * 2"
.\tools\dev.ps1 probe "@0 call 0x<subsystem> GameTimeSubsystem SetCurrentClockTime Hours=i:7 Minutes=i:0 Seconds=i:0"
.\tools\dev.ps1 probe "@0 call 0x<subsystem> GameTimeSubsystem GetCurrentClockTime"
```

The host broadcasts its time of day every 20 s and the guest follows it, so setting it on the host is
usually enough (the module only adjusts when the difference is more than 2 minutes).

## Diagnostic tools (2026-11-06)

These three exist because every bug hunt started with the same three questions: "is the game healthy", "what did
the log just say" and "does the same object look the same on both copies". They are plain PowerShell, no rebuild.

### `tools\health.ps1`

One command for the state of the run: which copies are alive, the last frame rate and worst frame of each, the
per-module cost of the last sample, whether any exception was recorded, and the last lines of the log.

```
.\tools\health.ps1
```

### `tools\tail.ps1`

Filtered log tail instead of scrolling a 300 KB file: by pattern, by copy (host/guest, taken from the window
titles), by time prefix, and a count.

```
.\tools\tail.ps1 -Pattern 'S light' -N 10
.\tools\tail.ps1 -Seat host -Pattern 'N dmg|N death' -N 20
.\tools\tail.ps1 -Since '21:1'
```

### `tools\cmp.ps1`

The most useful one: it finds the same object on **both** copies by class (and optionally name), prints their
identities, and lists every property that differs. This is what one wants when something "looks different on the
other side" - the trader's stock, an attribute set, a component's flags.

```
.\tools\cmp.ps1 -Class AttributeSet_Health -Filter Health
.\tools\cmp.ps1 -Class TraderManager -Name TraderManagerComponent -Filter Liquidity
```

Two notes learned while writing it: the `members` filter is a plain substring, not a regular expression, and the
search has to look past the `Default__` objects, so `cmp` scans up to 40 matches per copy before giving up.

### The probe commands behind them

`arr <ptr> <Prop> [max]` lists an array property's objects, `hex <ptr> [bytes] [step]` dumps raw memory, and
`where <ptr>` prints an actor's world location - the last one exists because decoding `K2_GetActorLocation` by hand
twice produced garbage coordinates that then propagated through the position sync.

## Finding problems nobody sees (2026-11-06, evening)

The three tools above answer questions you ask. These watch on their own, because the expensive bugs are the ones that
happen while nobody is looking.

### `tools\blackbox.ps1` - the rolling recorder

```
.\tools\blackbox.ps1                 # follow a session until Ctrl+C
.\tools\blackbox.ps1 -Interval 5
```

Every sample it records one JSON line into `native\build\blackbox_<time>.jsonl`: for each copy the pid, whether it is
alive, its last frame rate, how many seconds ago it last wrote to the log, and the hero position. On top of that it
watches for the four things that are invisible in play:

* a copy disappears (crash) or is alive but silent for longer than `-LogSilenceSeconds` (a freeze);
* the frame rate below `-FpsFloor`;
* a new `EXCEPTION` in the log;
* the two copies' canonical state diverging (it calls `diff_npcs.ps1` for this).

The first anomaly writes `blackbox_report_<time>.md` - the last twelve samples, the last 200 log lines of each copy and
a full copy of the log next to it - so the state *before* the bug is preserved. A second report is written on exit.

Verified: started with no game running, it reported `no game copy is running` and produced the report and the log copy.

### The older passive checks

* `tools\parity_suite.ps1` asks both copies for their canonical state, compares them, scans for exceptions and fps and
  prints PASS/FAIL per check (exit code 1 when something fails). `-Watch 5` keeps checking.
* `tools\diff_npcs.ps1 [-Name Ratford] [-MaxDist 150]` compares NPC positions, yaw, defeated flag and health between
  the copies and returns 1 when they disagree. `blackbox.ps1` uses it as one of its checks.
