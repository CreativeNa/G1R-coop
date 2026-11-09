# Gothic 1 Remake — reverse-engineering bundle

Everything known about the game's internals, gathered from the live product (no source code, no
leaks, no guesswork where a fact could be read out of the engine). Written for whoever continues
the work — human or AI.

**Version this was taken from:** `Build106_CL176207`, `G1R-Win64-Shipping.exe` = 175 124 992 bytes,
UE 5.4 — this is game **1.2**. The artifacts were first produced on 1.1 (`Build102_CL175960`, exe
175 029 760) and regenerated on 1.2; what changed between the two builds is in
[CHANGES_1.2.md](CHANGES_1.2.md). A game update moves addresses (see
[02_PIPELINE.md](02_PIPELINE.md)); class layouts barely move — 1.1 → 1.2 changed 6 classes'
members and added 107 new ones.

---

## What is in this bundle

| File | Content |
|---|---|
| [01_ENGINE_AND_CODE.md](01_ENGINE_AND_CODE.md) | what the game is built on, how its code is layered, the subsystems that matter |
| [02_PIPELINE.md](02_PIPELINE.md) | how every artifact here was produced, with the exact commands and the traps |
| [03_CONTENT.md](03_CONTENT.md) | what content exists, where it lies, what has been converted |
| [04_LIMITS_AND_OPEN.md](04_LIMITS_AND_OPEN.md) | what is still unknown, broken, or must not be trusted |
| [05_COOP_BRIDGE.md](05_COOP_BRIDGE.md) | each coop problem mapped to the classes, functions and offsets that solve it |
| [dossiers/](dossiers/INDEX.md) | one page per key class: inheritance, all own properties with offsets, functions, subclasses |
| [CHANGES_1.2.md](CHANGES_1.2.md) | what the 1.1 → 1.2 patch added, removed and changed |

Machine-readable artifacts live in `sdk/`, extracted content in `extracted/`. The running log of
every change made to the coop project is `AI_HANDOFF.txt` in the repository root.

---

## ✅ DONE — survive game patches (recon mode)

The core now finds `GUObjectArray`, the `FNamePool` block table and `ProcessEvent` by itself when
the exe size is not in `BUILDS[]`, saves the result to `native/build/learned_profile.txt` and
prints one line to paste into the table. Verified on 1.2 as a self-test
(`native/build/force_recon.txt`): the discovered RVAs are identical to the hand-made profile.
Full write-up and the after-patch checklist: [../RECON_MODE.md](../RECON_MODE.md).

The list below is kept as the historical plan; items 1 and 2 (automatic discovery, one command)
are what recon mode implements.

## (original plan, kept for context)

A game update breaks **only the core**, not the mod and not this analysis. Modules address
functions and properties by name; the SDK and `.usmap` are regenerated from the live game in
minutes. What breaks is four hard-coded things in `native/`:

| Hard-coded | Where |
|---|---|
| `GUObjectArray` RVA | `native/n2.inc` (1.1: `0x9E9FBC0`, 1.0: `0x9B9D440`) |
| `ProcessEvent` slot | taken from a UObject vtable |
| `FProperty` field offsets (`Next`, `NamePrivate`, `Offset_Internal`, `ElementSize`) | derived at start-up |
| audio-predicate patch offset | `exe+0x5be3970` on 1.0, new location on 1.1 |

Four things to build, in this order (value per effort):

1. **Version-independent recon mode.** `scan_gc.c` already finds `GUObjectArray` by scanning
   memory. Let the core load on an *unknown* build in "dump only" mode — no hooks, no network —
   so that after any patch one command still produces the dump, the SDK and the `.usmap`.
   The whole analysis then stops depending on the game version.
2. **One script for the whole cycle.** `tools\recon_after_patch.ps1`: check exe → start the game →
   dump → SDK → `.usmap` → verify on 20 packages → report what changed. Today this is seven manual
   steps and two game launches.
3. **Signatures instead of RVAs.** Find `ProcessEvent` by scanning a UObject vtable, the
   `FProperty` offsets by walking a known class's property chain, the audio patch by its byte
   pattern. Then the coop survives a patch with no code edit at all.
4. **Known-builds table.** Store size + hash + date + status ("core verified" / "recon only"), so
   the core can say exactly what it does not know about this build instead of refusing to load.

Items 1 and 3 are hours of work and low risk (they touch loading, not gameplay). Item 3–4 need a
real patch to validate; it can be emulated by feeding the core a wrong exe size.

Status: **not started**, recorded here on purpose — this is the highest-value remaining work for
keeping the project alive across updates.

---

## The three layers of the game

The game is not one program, it is three stacked ones, and each needs a different tool:

```
  +-------------------------------------------------------------+
  |  CONTENT        .uasset / .uexp / .ubulk  (61 GB, 215k)      |  retoc + UAssetAPI
  |                 meshes, textures, DataTables, blueprints     |
  +-------------------------------------------------------------+
  |  SCRIPT         /Script/Angelscript  35 486 classes          |  reflection + observe
  |                 the actual gameplay: quests, dialogue, AI    |  (no bytecode in assets)
  +-------------------------------------------------------------+
  |  NATIVE         G1R-Win64-Shipping.exe  (175 MB)             |  IDA / Ghidra + SDK
  |                 UE 5.4 engine + /Script/G1R game framework    |
  +-------------------------------------------------------------+
```

The single most useful discovery for planning: **gameplay logic is in the AngelScript layer, not
in the blueprints.** All 556 blueprints in the content are visual effects (banners, tornadoes,
decals, bridges). Quests, dialogue, combat rules and AI states live in `/Script/Angelscript`
classes, whose bytecode is **not** stored in any asset — it is compiled into the script runtime.
That is why the pipeline ends at "reflection + runtime observation" for logic, not at "read the
blueprint".

---

## The short version of what is known

* **Engine**: Unreal Engine 5.4, cooked with IoStore (`G1R-Windows.utoc/.ucas`, Oodle, 115 349
  chunks, 86 068 packages) plus separate containers for dialogue face animation in five languages.
* **Scripting**: Hazelight AngelScript (the same technology as *It Takes Two*), 35 486 script
  classes, exposed to the engine as ordinary UClasses. This is why the reflection dump is so rich.
* **Combat**: Gameplay Ability System. Damage flows through `GothicGASLibrary::ApplyDamageTo` →
  `GE_Ex_Damage` (an execution calculation) → the `AttributeSet_Health` attribute. 5 360 classes
  match combat keywords; the readable entry points are listed in `sdk/subsystems.md`.
* **Character data**: every character carries `DataModule_*` objects (combat, inventory, targeting,
  stats, …) reached through `GothicCharacter::GetDataModule_*`. These are the handles a mod needs.
* **Dialogue**: `ConversationTopic` / `ConversationTopicSet` with `Act()`, `EndConversation()`,
  driven by `AbilityTask_ActConversationTopic::TaskActConversationTopic(OwningAbility, TopicToAct)`.
  Separately, `GDS` (`/Script/THQGDS`) is an analytics/logging layer with ready-made events:
  `log_on_dialogue_execution`, `log_on_player_death`, `log_on_npc_killed`, `log_on_quest_update`,
  `log_on_inventory_update`, `log_on_combat_start` — cheap hooks for observing gameplay.
* **Story**: one `StoryG1R` object holds ~520 int/time words of story flags plus `Chapter`; 679
  quest instances hold a one-byte state. Both are plain memory and can be read/written directly.
* **Reflection**: 48 557 classes/structs, 61 392 properties, 37 361 functions, dumped from the
  live process in ~2 seconds. Property *targets* (which struct/class a property points at) are
  part of the dump, which is what makes a working `.usmap` possible.

---

## What this bundle is good for

* Finding the exact function and property behind any gameplay behaviour, instead of guessing from
  logs (`sdk/subsystems.md` → `sdk/functions.tsv` → `probe "fn <Class> <Function>"` for the
  parameter layout).
* Reading asset content as JSON (DataTables, item definitions, UI widget trees) for balance work
  and for understanding what the game ships.
* Re-doing the whole pass after a game patch in hours instead of days.
* Building a native mod: the coop DLL in this repository already uses this pipeline; the offsets,
  the `ProcessEvent` calling convention and the `DataModule_*` handles all come from here.

## What it is not

* Not decompiled source. Names and layouts are real (the engine reports them), function bodies are
  not reconstructed.
* Not complete on content: the conversion covers items, AI, blueprints and UI (3 139 packages of
  215 137). The rest is extracted but not parsed; see [03_CONTENT.md](03_CONTENT.md).
* Not stable across patches: every RVA moves, the layout of most classes does not.
