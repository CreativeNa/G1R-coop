# Reporting a bug so it can actually be fixed

The mod writes everything into one file per copy, so a report has two halves: **what you saw** and **two log files**.

## What to send

1. **What you saw**, in one or two sentences: which copy, what you did, what happened instead. A screenshot helps but the
   log usually decides.
2. **Both logs.** On the host:

   ```powershell
   .\tools\diag_link.ps1 fetch -Peer <the other PC's address>   # the guest must be running diag_link serve
   ```

   That writes `native\build\guest_report_<time>.json` (the guest's log and module list) next to the host's own
   `%LOCALAPPDATA%\G1RCoop\app\coopdll.log`.
3. **The version hash.** Every log contains a line like
   `S versions: this build is <hash>`. If the two hashes differ, the two PCs run different builds and that alone can
   explain the bug - check that first.

## Where to look first, by symptom

| What you see | First thing to check |
|---|---|
| nothing connects | both PCs on the same Radmin/LAN network, `S versions` hashes equal, the host started first |
| "the other player is not here" but he is | `N3 remote` / `net:` lines - is the link up? |
| the friend's screen does not darken when you sleep | `S sleep:` lines on both copies |
| an item stays in the world after the other picked it | `S gone received` + `S item ... removed` on the other side |
| the trader shows a different stock | `S trade:` lines; the guest's stock must say `updated here` |
| the game stutters | `M cost ms` (should stay around 2 ms) and `S slowfn` lines |
| the interface stops answering | `S death screen` / `S load` in the log; if this appears, say so immediately - it is the one class of bug that makes a session unplayable |

## What to never do

* Do not edit the log files - send them as they are.
* Do not "fix" a session by restarting only one copy: a fresh copy always matches the save state and hides the bug.
