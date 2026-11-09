# Testing a live online session (two PCs, two people)

The parity suite (`tools/parity_suite.ps1`) and the action scenarios (`tools/scenarios.ps1`) work on **two copies running on
one machine**: they read the local log and drive the local game. A real session is two machines, and that is what
`tools/cooptest.ps1` is for.

It does two things:

1. **invariants** - the checks that must hold all the time, run against the host's log locally and the guest's log
   pulled over the diagnostic bridge;
2. **guided scenarios** - it prints what the two players should do, waits, then verifies the log lines that prove it
   happened, on both copies, and only on lines that arrived after the scenario started.

Every run writes `docs/reports/online_<stamp>.md`: a table of PASS/FAIL/WARN/SKIP with the evidence line that proved each
check, so a session can be handed over without copying text by hand.

## One-time setup on the guest

The bridge is the same one the night sessions used:

```powershell
# guest PC, leave it running while you play
.\tools\diag_link.ps1 serve
```

The launcher starts it automatically (`blackbox.ps1` does), so usually nothing to do. Port 40004/TCP.

## Invariants (about 10 seconds)

```powershell
# on the host PC, with the guest playing
.\tools\cooptest.ps1 -Peer x.x.x.x
```

What it checks:

| Check | Why it matters |
|---|---|
| both copies running, guest reachable | a session that is not really connected tests nothing |
| **module versions match** | the most common cause of "it works on my PC": one side runs an older `npc.dll`/`story.dll` and the protocol silently disagrees |
| no exceptions on either side | every caught crash hides a race; they were the first sign of several bugs |
| host is the host, guest is the guest | a guest that believes it is the host pulls the clock apart |
| both know their NPCs (`missing N`) | a growing count means actors exist on one copy only |
| frame cost under 4 ms, no slow calls | the mod must not be what costs frames |
| frame rate at least 25 fps | |

Exit code 0 = all passed, 1 = a check failed, 2 = no game running.

## Guided scenarios

```powershell
.\tools\cooptest.ps1 -Peer x.x.x.x -Mode Run
.\tools\cooptest.ps1 -Peer x.x.x.x -Mode Run -Only trade,sleep
.\tools\cooptest.ps1 -Mode List
```

Each scenario prints the steps, waits for Enter (start), waits for Enter (done), then fetches both logs and evaluates the
lines that arrived in between - an old pass never counts for a new attempt. Available ids: `connect`, `clock`, `npc`,
`items`, `chest`, `trade`, `sleep`, `death`, `soak`.

`-Auto` replaces the prompts with a timer: it waits the scenario's own window and then checks. Handy for a scripted run,
and it is how the harness itself is smoke-tested (with `-HostLog`/`-GuestReport` it runs with no game at all, where the
checks are expected to fail because no new lines appear).

A scenario check is deliberately written as "the log line that proves it": if the line is missing, the feature did not run
on that copy, which is a different (and easier) problem than a sync bug.

## Analysing a session afterwards (no second PC)

The bridge saves what it fetched (`native\build\guest_report_*.json`), so a past session can be re-checked offline:

```powershell
.\tools\cooptest.ps1 -Mode Check `
    -HostLog "$env:LOCALAPPDATA\G1RCoop\app\coopdll.log" `
    -GuestReport native\build\guest_report_20261107_043311.json
```

This works with no game running, which makes it the way to look at a report a player sent you.

## What it found immediately

Run against the logs of the last night, it reported:

```
FAIL  module versions match   anim.dll host=2026-11-06 20:38:42 guest=2026-11-07 02:17:48; ...
WARN  guest knows its NPCs    missing 7
WARN  no slow calls           3 calls above 6 ms in the tail
```

The first line is the important one: the guest had been updated module by module, so several of his DLLs were older than
the host's. That is exactly the class of problem that makes a sync bug look random.
