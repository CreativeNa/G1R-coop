# Limits, defects, open questions

Read this before trusting anything. Everything below is a known gap, not a guess.

---

## 1. Structural limits of the method

| Limit | Consequence |
|---|---|
| **No function bodies.** The SDK has names, offsets and types; the code inside a function is not reconstructed. | "What does X do" can only be answered by reading bytecode (blueprints) or by observing it at run time. |
| **No parameter lists in the dump.** A UFunction's layout exists only in the process. | Every new function you want to call needs one live query: `tools\dev.ps1 probe "fn <Class> <Function>"`. |
| **No `sizeof`.** The dump's last property end is a lower bound. | Layouts are exact up to the last member, class sizes are not known. |
| **Bool flags share bytes.** The dump has the byte offset, not the bit index. | For flags in the same byte, only `props.tsv` name lists are available; setting one requires the engine's own setter. |
| **Pointer targets are names, not types.** | Arrays of `TArray<T>` where `T` is neither a class nor a struct get `ByteProperty`; see §2. |
| **`/Script/Angelscript` has 35 486 classes.** | Gameplay lives there, and its bytecode is not in any asset (see §3). |

---

## 2. Known defects in the produced artifacts

### Mappings (`.usmap`)

* Array/set/map element kinds are **guessed** by name lookup (struct → `StructProperty`, class →
  `ObjectProperty`, else `ByteProperty`). A `TArray<int32>` therefore becomes `TArray<uint8>`; a
  `TMap` with non-struct keys may be mis-sized.
* The engine **can** report the exact element kind — the dump carries it as
  `ArrayProperty(ObjectProperty(SceneComponent))` when built from core 75 or newer, and
  `dump_to_usmap.py --precise` writes it. It is not the default because it made UAssetAPI 50–100×
  slower on the same 20 packages (44 s and 97 s versus 0.9 s) with one more package parsed.
* Two hypotheses were tested and disproved: missing struct schemas (only 5 of 18 828 references),
  and `TArray<bool>` bit arrays (forcing `Byte` made it worse). The slowdown is not one type; it is
  how UAssetAPI resolves schemas when many distinct types appear. Finding it needs a profiler.
* Consequence: some packages parse, but a few array/scalar-typed fields deserialize wrongly rather
  than failing loudly. Treat array/scalar-typed fields with suspicion and cross-check with `props.tsv`.
* 14 DataTable subclasses (`CommonGenericInputActionDataTable`, all `DT_Input_*`) still fall back to
  `RawExport`: their row struct `CommonInputActionDataBase` has a `TMap<CommonInputTypeInfo,
  CommonInputTypeInfo>` and the row read throws. Plain `DataTable` packages parse fine.
* Fixing both properly needs one more `prop_ref` extension: emit the element *kind* for arrays and
  the value type for maps (the FProperty walk already finds the pointers; only the kind of the
  inner property is not reported).

### Converter

* ~6 UI subfolders (`TradingNew`, `Notifications`, `Crafting`, `ArmorCustomization`, `CoreMenus`,
  `ManagementUI`) kill the process with `0xC00000FD` (stack overflow inside UAssetAPI). Raising the
  worker stack to 64 MB did **not** help, so it is unbounded recursion on specific widget graphs,
  not merely deep nesting. Skip those files.
* Materials, fonts and a few engine defaults stay `RawExport` by design of UAssetAPI.
* Output size: meshes and textures produce huge JSON (up to 57 MB per package). Do not convert
  `Assets` or `Textures` wholesale.

### Coverage

* 3 139 packages converted out of 215 137 (1.5 %). The selection is the one that carries gameplay
  data; the rest is extracted but not parsed.
* The full set would take ~25 hours at 2.3 packages/s and is mostly mesh/texture noise.

---

## 3. The AngelScript problem — the biggest open question

`/Script/Angelscript` holds 35 486 classes: quests (`GVL_Conversation_*`), AI states, combat
abilities. Their names, properties and function names are all visible in the SDK, and their
functions can be observed and called through `ProcessEvent`.

What is **not** available:

* their **bytecode** — it is compiled into the script runtime, not stored in `.uasset` files;
* the **source scripts** — not shipped.

`global.utoc` contains "script objects", but `retoc print-script-objects` prints only the object
registry (name, global index, outer index, cdo class index) — no code.

So for anything implemented in AngelScript the only approaches are:

1. **observe** the `UFunction` at run time and record the parameters (`CoreAPI::observe_fn`), or
2. **compare state** before/after (the coop project does this for story flags and quest states), or
3. **call** the function yourself with parameters taken from `probe "fn ..."`.

Item 3 is the most powerful and the least explored: `ConversationTopic::Act()` takes no arguments,
`TaskActConversationTopic(OwningAbility, TopicToAct)` takes two, and both are directly callable.

Open question worth investigating: whether the script runtime keeps its compiled buffers in memory
in a discoverable form (the engine must hold them somewhere to execute). Nothing has been tried
here beyond dumping the object registry.

---

## 4. What is unverified in the coop mod

These were written by the previous work and are carried forward as **unverified**, not as facts:

* every gameplay behaviour was tested with two copies on one PC, never between two real PCs;
* damage transfer on mirrored NPCs, dialogue sync (not implemented at all), shared save/load,
  player death — all open;
* chest put-in sync, body looting from the guest, arrows in flight — open;
* the fixes recorded in `AI_HANDOFF.txt` (targeting-based ownership, health-delta damage bridge)
  compile but have never been run with two copies.

---

## 5. Answers that still need to be found

Ordered by how much they would unlock.

1. **Where does the AngelScript runtime keep compiled function code?** Would turn the largest layer
   from "observe it" into "read it".
2. **What exactly does `GothicGASLibrary::ApplyDamageTo` do with `HitData`?** Its 296-byte struct is
   the key to replaying damage faithfully instead of approximating it.
3. **How is a dialogue owned?** `ConversationTopic::AreParticipatingCharactersInSameConversation`
   and `InviteParticipatingCharactersIntoConversation` suggest the game already has a notion of
   participants; coop needs to make the second player one of them.
4. **What is the save/load entry point used by the main menu?** Needed for shared saves.
5. **Does the game have a shipping console?** `CheatMode` exists under `G1R\Script`; if a console is
   reachable in a shipping build, much of the runtime recon becomes cheaper.
