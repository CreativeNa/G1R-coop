# Fallback plan: co-op through the official ModKit (if the native DLL route is not allowed)

Status: research notes from public sources, nothing here has been run by us. Tags: SOURCE = read in the official ModKit repository, OURS = measured by us earlier,
OTHER = reported by another project, UNKNOWN = not known.

## The official ModKit is public and complete
- Repository: https://github.com/AlkimiaInteractive/G1R-Modkit (rendered docs and the native class reference: https://alkimiainteractive.github.io/G1R-Modkit, branch `gh-pages`). SOURCE
- It holds the **full AngelScript sources of the game as shipped** (about 7,300 `.as` files under `Script/`: AI, GAS, Items, Player, Save, Spawning, Spells, Stats, Story ...),
  the documentation (getting started, mod package, first mod, Steam Workshop, in-game tools, localization), and examples (new character, chest contents, item spawner,
  Diego conversation, settings, stats page ...). The licence in it is the THQ Nordic Modding Policy (the same text we have). SOURCE
- Feature Update 1 (2026-10-29) added it. A mod is a package in `G1R/Mods/<Name>/` with `GothicMod.json`, `Script/*.as`, `Config/*.ini`; the game compiles it at start; useful
  switches: `-as-development-mode` (lists compile errors), `-ingametools` (ImGui panels, actor outliner). SOURCE/OTHER
- The game's own scripts are the sanctioned way to read its logic. Everything the native route needed reverse engineering for (class and function names, how quests, dialogue,
  journal, trade, sleep, skills work) is readable here as source. Use it instead of memory dumps wherever a claim must be backed up.

## What the game already contains for co-op (SOURCE: scripts and the native reference)
- `class AG1RMainStoryGameMode : AG1RGameModeCooperative` (`Script/Story/Support/G1R/G1RGameMode.as`), `bUseSeamlessTravel = true`, `PlayerStateClass = AG1RPlayerState`.
- Class chain `AG1RGameModeCooperative -> ACooperativeGameMode -> AMultiplayerGameMode -> AGothicGameMode -> AGameMode`.
  - `AG1RGameModeCooperative`: `m_MainPlayerConfig`, **`m_SecondaryPlayerConfig` (an array of player configs)**, `m_CleanSaveGame`, `m_CanAutosave`, `m_WorldDefinition`.
  - `ACooperativeGameMode`: `StartGame()`, `HasLobbyMap()`, `FindSessions()`, `GetAvailableSessions()`, `GetCurrentSessionIdStr()`, `DestroySessionAndLeaveGame()`, `GetGameMapSoftPtr()`.
  - `AMultiplayerGameMode`: `MaxNumPlayers`, `GameMapName`, `MainMapName`, `LobbyMapName`, `MapsPath`, `MainStoryClass`, `DifficultyPresetOverride`, `MinRespawnDelay`, `NumTravellingPlayers`.
  - `AMultiplayerGameSession`, `UOnlineGameSession`, `FJoinSessionCompleted`, `UG1RGameInstance` (`CreateLocalPlayer`, `AddLocalPlayer`, `RemoveLocalPlayer`, `GetNumLocalPlayers`,
    `HandleNetworkError`, `HandleTravelError`, `DestroySession`).
- `Script/Player/PlayerConfig.as`: `UPlayerConfig_G1R` (the hero, `UG1RPlayer`) and **`UPlayerConfigTwo_G1R` .. `Five_G1R`** (character definitions `UGR2Player` .. `UGR5Player`).
  `AG1RPlayerState.PlayerStartLessons` gives every player his own lessons (skills) - the per-hero progression we saw working. Replication-style functions (`Server_*`, `Multicast_*`)
  are all over the gameplay classes. SOURCE
- Reading: the game is built on a multiplayer-capable skeleton (up to 5 player configs, a lobby map, sessions, seamless travel). It looks like a co-op mode that was designed and
  then shipped switched off or unfinished in the single-player build. UNKNOWN: whether any of it still works in the shipped binary.

## What we measured ourselves (OURS, from `docs/PATCHES_AND_BUILDS.md`)
- From script: `CreateSession(true|false)` crashes the game (null read 0x1d8), `open ?listen` and `open 127.0.0.1` crash (null read 0x80), `FindSessions` does nothing visible.
  So the engine's own session and listen-server paths are not usable in the shipped build as they are.
- Our spike mod `mod/G1RCoop` adds `UPlayerConfigTwo`-style second-player config; whether a second local player actually spawns and can be controlled is UNKNOWN (not tested).

## What other people found (OTHER)
- `Mjolniar/gothic-1-remake-megamod`: since the 1.1 hotfix the game exits when it sees UE4SS ("Potentially malicious code injection found ... use the provided API", it names
  `UE4SS.dll`). That author is porting to the ModKit. His fact files tag every claim by source (IN-GAME / DISASM / SOURCE / OFFLINE / UNKNOWN): a good habit to copy.
- `AKiteKid/gothic_remake_localization_editor`: the `.lcache` localization format (AES, dialogue trees); dialogue text can be looked up by key from the game's own data.

## Options if the native route is refused (see also the discussion in the chat history of 2026-11-06)
1. **Local second player from script + remote play.** `UG1RGameInstance::CreateLocalPlayer` / the secondary player configs may allow two heroes in one process with two input
   devices. Online play then runs through Steam Remote Play Together or Parsec (screen streaming), no mod networking needed. Costs: one strong PC, input and video latency.
   First experiment: `-as-development-mode`, a tiny mod calling `CreateLocalPlayer(1, ...)` and spawning `UPlayerConfigTwo_G1R`; record what happens.
2. **Wait for or ask for the official online mode.** The scaffolding is in the shipped scripts; ask THQ Nordic / Alkimia whether it is planned and why `CreateSession` and listen crash
   (`docs/THQ_questions.txt`, questions 10 and 11).
3. **Sidecar program** that copies sparse state (quests, items) between PCs through files the script reads and writes. Weak for real-time positions; legal status to be asked.

## What survives a switch to scripts
- Fully: the map of the game (classes, functions), the list of what must be synchronised and how each subsystem behaves, tests as specifications, the beta guide and report tools.
- Partly: save transfer, protocol thinking, parity checks (the way of reading state changes).
- Lost: native hooks, pose copying, the injected core and modules (to be rewritten in AngelScript).
- Easier in script: dialogue lines and voice calls, journal and conversation logic (they are script classes there, we can override them with `ReplaceParentClass`).

## Next steps that cost nothing
1. Read `Documentation/getting-started/*.md` and the examples in the ModKit; write down what a script mod may and may not do (files, console commands, networking).
2. Find in `Script/` every place that touches `m_SecondaryPlayerConfig`, `CreateLocalPlayer`, `AG1RGameModeCooperative`, `ACooperativeGameMode` and read how a second player is supposed to be spawned.
3. Run the first experiment above (one local second player) only after THQ Nordic's answer, or as a private test.
