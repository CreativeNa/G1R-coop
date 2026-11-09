# Beta release checklist (for the developer)

> **Исторический документ.** Описывает переносную раскладку (
ative\build + start_net.ps1) до установщика.
> Актуальный поток — docs/HOW_TO_PLAY.md (установщик, ярлык «Gothic 1 Remake Co-op»).



Run through this before every beta package. Each line is a command or a thing to look at; do not skip the ones that need the game.

## Code and checks
1. `git status` is clean, everything is pushed to `private`.
2. Two copies running on one PC: `.\tools\check.ps1` is PASS (SKIP rows are fine). One controlled F9 test by hand: ONE press = ONE load on each copy
   (`.\tools\load_audit.ps1`), Esc and the inventory still work after it.
3. If the core or the packet format changed: both copies restarted on the new core before testing (a core cannot be hot-swapped).
4. Network emulation pass without game risks: `.\tools\scenarios.ps1 -Only netsim` (no `-Jump`).
5. No developer aids switched on in the package: `make_beta_package.ps1` refuses god.txt, give_*.txt, net_sim.txt, logs, saves and per-process copies.

## Package
6. `.\tools\make_beta_package.ps1 -Version <x.y.z-betaN>` (it rebuilds `probe.dll` without the local immortality code and checks the result).
7. Unpack the zip into a NEW empty folder (ideally another PC or a clean Windows user), read `docs\BETA_GUIDE.md` as a tester would, and run `start_net.ps1 -Role host`
   there: the game starts, the core injects (`coopdll.log` shows the build profile line), `collect_logs.ps1` makes a report with no IP, PC name or user name in it.
8. `VERSION.txt` shows the right version and git hash; `NOTICE.txt` is in the package (the "unofficial modification" notice).

## Publish (private repository only until THQ Nordic has answered the policy questions in `docs/THQ_questions.txt`)
9. GitHub release as a **pre-release** on `gothic1-remake-coop-private`, tag `v<version>`, asset = the zip, notes = what changed + known problems.
10. Send testers the link, the guide, and tell them the exact game build they need (exe size).

## After the test
11. Put every report into `docs/reports/beta_<date>/` (scrubbed zips only), list new bugs in `docs/BUGS.md`, note what was tested and how often (several runs, not one).
