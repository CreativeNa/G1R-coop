# Distribution plan: one archive, one installer, one button

> **Исторический документ.** Описывает переносную раскладку (
ative\build + start_net.ps1) до установщика.
> Актуальный поток — docs/HOW_TO_PLAY.md (установщик, ярлык «Gothic 1 Remake Co-op»).



Written before the implementation (2026-11-06 evening). The goal is a person who has never installed a mod: download,
double-click, install, launch the game, press a button, play.

## 1. What the mod actually is

The co-op is not a set of replaced game files. It is **one DLL injected into the running game process** plus seven
module DLLs that the core loads from a folder and hot-reloads. Nothing in the game folder is touched, and nothing
in the game folder has to be. That is the property the whole design leans on:

* the installer never writes into the game directory - a bad install cannot break the game;
* the mod lives in `%LOCALAPPDATA%\G1RCoop\` and the uninstaller deletes that one folder;
* the only thing the user "installs" is a launcher shortcut.

## 2. Components

| Component | What it is | Where it lives |
|---|---|---|
| `Setup.exe` (a compiled PowerShell script with a Windows Forms wizard) | detects the game, copies the payload, writes settings, creates the shortcut, registers an uninstall entry | anywhere; it is the download |
| payload | core (`coopdll_<n>.dll`), `inject.exe`, `modules\*.dll` (7), `autoload.txt` | `%LOCALAPPDATA%\G1RCoop\app\` |
| `CoopLauncher` | starts the game and injects the core once it is up; that is the shortcut the user double-clicks | `%LOCALAPPDATA%\G1RCoop\CoopLauncher.ps1` + shortcut |
| settings | `%LOCALAPPDATA%\G1RCoop\settings.ini` (player name, port, last address) | survives updates |
| logs | `%LOCALAPPDATA%\G1RCoop\logs\` (core log, launcher log) | survives updates, never shipped |
| `Uninstall` | removes `app\`, the shortcuts and the registry entry, keeps `settings.ini` and saves | shortcut in the Start menu |

## 3. Installation steps of the wizard

1. **Game detection.** Steam library folders from the registry (`HKCU\Software\Valve\Steam\SteamPath`,
   `...\Apps\...`, `libraryfolders.vdf` if present) plus the usual paths, looking for
   `G1R\Binaries\Win64\G1R-Win64-Shipping.exe`. If nothing is found the user can browse for the folder.
2. **Version check.** The mod is tied to one game build; the executable's size identifies it (`175124992` bytes for
   1.2). A different size is shown as *tested with 1.2, continue at your own risk* rather than a hard stop, since the
   core has a recon mode.
3. **Payload copy** into `%LOCALAPPDATA%\G1RCoop\app\`, with a check of every file against the manifest
   (name + size + hash). A failed copy leaves the previous version untouched (the new files go to `app.new`, then the
   folder is swapped).
4. **Settings** written only if absent, so an update keeps the player's name and last address.
5. **Shortcuts**: desktop and Start menu, both pointing at the launcher; plus an "Uninstall" shortcut.
6. **Verification**: the wizard re-reads the installed manifest, checks the game executable again, and only then says
   "installed". Everything that failed is listed with what to do.

## 4. Launching and injecting

`CoopLauncher` starts `G1R-Win64-Shipping.exe` with the same arguments the scripts use (`-windowed`, no intro), waits
for the process to settle (12 s, configurable in `settings.ini`), then runs `inject.exe <pid> <core dll>`. The window
stays hidden; failures are written to `logs\launcher.log` and shown as a message box with the next step.

The core's own folder (`%LOCALAPPDATA%\G1RCoop\app`) is where it looks for its modules, the log and its switches -
it already resolves its paths at run time, so nothing is hard-coded to the repository.

## 5. Auto-discovery of a host (the "Join" button)

Requirement: no IP, no port, no network settings.

**Architecture: broadcast discovery, no server.**

* The host, once it is hosting (the "Co-op" button or the launcher), listens on **UDP 40002** for the probe
  `COOP-WHO?` and answers `COOP-HOST <game port> <player name> <version>`.
* The guest presses **"Join co-op"**: the core sends `COOP-WHO?` to `255.255.255.255:40002` and to the broadcast of
  every local subnet (including the Radmin `26.x` one, where directed broadcast is used), collects answers for
  two seconds and joins the single host it found. Several hosts: the menu label lists them and the next press
  cycles; the log records what was answered.
* If nothing answers, the core falls back to the **last address that worked** from `settings.ini`, then says so.
* A rendezvous server is only needed for players who are not in one LAN/VPN. It is deliberately not built now: the
  supported path is Radmin VPN / LAN, where broadcast works and no third party is involved. The protocol has a
  version field so a server can be added later without breaking the client.

Manual entry stays as the escape hatch: an address in the clipboard means "join exactly this one".

## 6. Updates and maintenance

* `VERSION.txt` inside `app\` and a `manifest.json` with the file hashes. The installer compares an installed manifest
  with its own: same version = refuse to reinstall silently (offer "repair"), older = update in place, newer = warn.
* An update replaces `app\` only; `settings.ini`, `logs\` and the game folder are untouched.
* The uninstaller removes `app\`, the shortcuts and the registry entry, and asks before deleting `settings.ini`.
* The release process: `tools\make_installer_package.ps1 -Version x.y.z` builds the payload manifest, compiles
  `Setup.ps1` into `Setup.exe`, zips the two, and the zip is the release asset.

## 7. What is deliberately not done

* no writing into the game folder, ever - it is the single best protection against "the mod broke my game";
* no background service and no auto-start: the launcher runs, injects, exits;
* no telemetry; the discovery packets carry only a name, a port and a version.
