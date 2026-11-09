# Developing and testing

> Moved out of the README. Some details (game build size, IP-only connection) predate the installer and game build 1.2: for the current state see [STATUS.md](STATUS.md) and [BETA_GUIDE.md](BETA_GUIDE.md). Build 1.2 is exe size 175124992 bytes.

## Build and test (Windows)

Requirements: Visual Studio 2022 Build Tools, your own Gothic 1 Remake install. The addresses only match the game build with `G1R-Win64-Shipping.exe` of **171704320 bytes**; on any other size the DLL stops by design.

```
native\build_dll.bat <suffix>      -> native\build\coopdll_<suffix>.dll   (a loaded DLL cannot be overwritten, use a new suffix)
native\build_module.bat [anim|dev.ps1 build [anim|equip|pose|npc|story|probe]|pose]   -> native\build\modules\*.dll  (hot-reloaded within ~1 s)
native\build.bat                   -> inject.exe
tools\play_net.ps1 -Dll coopdll_<suffix>.dll   starts two windows and injects the DLL
```

### Connect by IP

```
tools\join.ps1 -Peer <friend's IP or host name>[:port]     (both players run it with the other player's address)
```

The DLL only accepts packets from that address. LAN or a VPN (Radmin VPN, ZeroTier, Hamachi) is the easiest; over the internet both sides use each other's public IP at about the same time (UDP hole punching) or forward UDP port 40001. Details are in the header of `tools\join.ps1`. Tested so far only with both copies on one PC.

### Two copies on one PC with CouchLink

[CouchLink](https://github.com/cranebeaker/couchlink) can start one copy of the game per player on its own monitor with its own input. `tools\couchlink\gothic1r-coop-test.json` is a recipe for it (copy it to `%LOCALAPPDATA%\Couchlink\recipes\`, check the `vars` paths inside). For each copy the recipe starts `couchlink_seat.vbs` (hidden window), which finds the copy by its `-CoopSeat=<n>` argument, writes the network config (UDP 40001 <-> 40002 on 127.0.0.1) and injects the newest `coopdll_*.dll`.

Set up a **copy** of the game in a separate folder (`tools\setup_test.ps1`) so the real installation is never touched. Debug switches (files in `native\build\`): `dev.ps1 build [anim|equip|pose|npc|story|probe]_off.txt`, `pose_mode.txt`, `pose_skip.txt`, `equip_off.txt`, `try_clip.txt`.

### Performance with two copies

Copy `tools\couchlink\perf_cmds.example.txt` to `native\build\perf_cmds.txt`: its console commands (the example only sets the render scale) run in every copy once its hero exists.

## Development tools

`tools\dev.ps1` is the single entry point (header of the file lists everything):

| Command | What it does |
|---|---|
| `dev.ps1 build [anim|equip|pose|npc|story|probe]\|equip\|pose\|probe]` | rebuild modules; running games hot-reload them within ~1 s, no restart, no save reload |
| `dev.ps1 core <n>` | build `coopdll_<n>.dll` (needs a game restart) |
| `dev.ps1 probe "<cmd>" ...` | run commands in the live game(s): `findall`, `class`, `members`, `get`, `set`, `fn`, `call`, `cc` (console command); `probe help` lists them. Works already in the main menu |
| `dev.ps1 shots` | screenshot all monitors |
| `dev.ps1 status` / `dev.ps1 log` | running games, recent problems, newest crash dump decoded (`tools\dmpinfo.py`) |


The `probe` module (`native/probe_module.c`) reads `native\build\probe_cmd.txt` and answers in `probe_out_<pid>.txt`. Rule of thumb: put new game logic into modules, not into the core, so a change never costs a restart.

## Automated test harness (no human needed)

**Start here:** `tools\check.ps1` — one command, PASS/FAIL, and it names the layer that broke.
It runs the parity gate (`tools\parity_suite.ps1`: two copies alive, state parity, fps, new
exceptions, corpse pose) and the `npc_health` scenario. `-Quick` for the gate only, `-Soak 60` to
add a soak. How it works and how to extend it: [docs/TESTING.md](docs/TESTING.md).
If something is broken and you do not know where to start:
[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
Test aids (giving items, teleporting, the game clock, why summon does not work):
[docs/TEST_AIDS.md](docs/TEST_AIDS.md). — symptom → which log line, which file, which switch.
What a whole working session produced (fixed bugs, tooling, performance numbers, the unfinished
dialogue subtitles): [docs/SESSION_2026-11-05.md](docs/SESSION_2026-11-05.md).

The parity gate compares **state between the two copies** (puppet position, camera behaviour,
chest set and contents, NPC set with health and defeated flags, hero inventory, UI widget
visibility, pose bones) — not the same field on both, which would always differ.

| Tool | What it does |
|---|---|
| `tools\check.ps1` | the one command after any change (gate + scenario, `-Soak N`, `-Quick`) |
| `tools\parity_suite.ps1` | the passive gate: state parity, fps, new unknown exceptions, corpse pose |
| `tools\scenarios.ps1` | action scenarios: `npc_health` (writes health on the owner, checks the mirror, restores), `soak` |
| `tools\parity.py` | the comparison itself; `--watch N`, `--snap <Class> <props>`, `--raw` |
| `tools\winshot.ps1 -Seat N` | screenshot of one game window, even when it is covered |
| `tools\harness.ps1 near / hp / act / fight / shot / stop` | moves an NPC next to the heroes and aims the cameras, sets NPC health, presses game input actions, takes both screenshots |
| `tools\test_ko.ps1` | the host hero fights an NPC with real input actions until it is down, both windows are photographed into `docs\img\ko_*.png` (`-Attacker 1` lets the guest fight) |
| probe commands | `inject <InputAction>`, `tpto`, `lookat`, `npchp`, `npcs`, `attached`, `@<seat> <command>` (run in one copy only) |

| `tools\tests\run_all.ps1` | the full suite (boot, NPC sync by numbers, knock-out, two quick loads, fps, crashes): PASS / FAIL per check in `docs\reports\last_run.md`, about 7 minutes, no human needed |
| `tools\tests\test_owner_fuzz.ps1` | ownership fuzz test: random teleports of both heroes to NPCs, then both copies must agree on every owner, no flapping, positions / health match, no fault in our code |
| `tools\tests\test_story.ps1` | story flag and quest state sync, both directions |
| `tools\tests\test_items.ps1` | world item pickup sync, both directions |
| `tools\tests\test_chests.ps1` | chest emptied-state sync, both directions (run the three sync tests after a fresh start; see the note in the changelog) |
| `tools\tests\netproxy.py` | UDP impairment proxy (loss, delay, jitter, duplicates) for bad-network scenarios (`run_all.ps1 -Net`) |
| `tools\diff_npcs.ps1` | host vs guest NPC positions / defeated flags / health as numbers |
| `tools\logq.ps1 -Summary / -Crashes / -Seat N -Tag T` | query the log of the newest run by seat and tag (one log per harness run, older ones are in `native\build\logs\`) |

The game reads input only while its window has the focus; `tools\realclick.ps1 -Seat N -Click 0` brings a window to the front.

## Repository layout

| Path | What |
|---|---|
| `native/` | core DLL (`coopdll.c`, `n2.inc`), module API (`coreapi.h`), modules, injector, build scripts |
| `tools/` | launch and test-setup scripts, the earlier UE4SS Lua probe |
| `mod/` | the earlier AngelScript attempt (legacy, abandoned; still used by `tools\setup_test.ps1`) |
| `helper/` | the earlier UDP bridge (legacy, abandoned; only used by `tools\play_two.ps1`) |
| `docs/` | findings log and the coop-anything style write-up |

## Acknowledgements

- **[CouchLink](https://github.com/cranebeaker/couchlink)** was a big help in testing: it starts one copy of the game per player on its own monitor with its own input, which made the whole two-players-on-one-PC development loop possible. Thanks to its author.
- The general approach follows the coop-anything write-up in [docs/coop-anything-writeup.md](docs/coop-anything-writeup.md).

## License

Code in this repository is MIT licensed ([LICENSE](LICENSE)). Gothic and Gothic 1 Remake belong to their owners; this project contains none of their assets.
## Install (for players)

1. Download **`Gothic1Coop-Setup-<version>.zip`** from the releases page and unpack it anywhere.
2. Run **`Setup.cmd`** and follow the wizard - it finds Gothic 1 Remake by itself.
3. Start the game with the **"Gothic 1 Remake Co-op"** shortcut it puts on the desktop.
4. In the main menu: the host presses **Co-op**, everyone else presses **Join co-op**. No addresses, no ports.

Both PCs must be in one network - **Radmin VPN** is the supported way (addresses `26.x.x.x`); the installer shows
your address and tells you if Radmin is missing. Nothing in the game folder is modified; the mod lives in
`%LOCALAPPDATA%\G1RCoop` and is removed by the "Uninstall" shortcut in the Start menu.



## Which module binaries ship (decision 2026-11-09)

The package `dist/Gothic1Coop-Setup-0.5.3` ships the module DLLs that were actually tested (the 0.5.2 builds).
`native\build\modules\*.dll` is a newer build from the current sources and therefore has different hashes - that is
expected, not a broken build. Do not rebuild the package from `native\build` without a two-PC session and a fresh
antivirus check: that would ship different code under the same version number.
