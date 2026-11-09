# Pipeline: how every artifact was produced

Reproducible from scratch. Commands are for PowerShell on Windows, run from the repository root
(`C:\Users\<USER>\Desktop\FOR GOTHIC 1 REMAKE`).

Total cost of a full pass: ~2 hours of machine time, of which ~80 minutes is the content unpack.

---

## Stage 0 — tools

| Tool | Where | Why |
|---|---|---|
| `retoc` v0.1.5 | `tools\bin\retoc\retoc.exe` | unpack IoStore (.utoc/.ucas) |
| Oodle runtime | `tools\bin\retoc\oo2core_9_win64.dll` | **required**; the game links Oodle statically and ships no DLL |
| .NET 8 SDK | system | builds the asset converter |
| UAssetAPI 1.1.0 | NuGet, referenced by the converter | parses .uasset |
| Visual Studio 2022 Build Tools | system | builds the coop core and modules |

`oo2core_9_win64.dll` is `oodle-data-shared.dll` from `WorkingRobot/OodleUE` (msvc-x64-release),
renamed. It must sit next to `retoc.exe`. **Without it retoc reports "Extracted 0 (N failed)" and
says nothing about the cause** — not even with `--debug` or `RUST_LOG`.

---

## Stage 1 — reflection dump (needs the game running)

The dump is the root of everything: it gives classes, property offsets, property types and, since
the `prop_ref` extension, what each property points at.

```powershell
# start one copy with the coop core injected (any recent coopdll_*.dll)
tools\start_coop_11.ps1 -Seats 0

# wait until a save is loaded, then:
tools\dev.ps1 probe "dumpall"
# → native\build\dump\classes_<pid>.txt
```

The dump takes 1.4–2.8 s for ~440 000 objects and produces 42 776 classes, 5 781 structs,
60 922 properties, 37 367 functions (8 MB of text).

Format:

```
# format: class|struct <Name> : <Super> [<Package>]
#         prop <Type> <Name> @<offset>/<size> [-> <Target>]
#         fn <Name>
class Actor : Object [/Script/Engine]
  prop ObjectProperty RootComponent @416/8 -> SceneComponent
  fn ExecuteUbergraph
```

The `-> Target` part comes from `CoreAPI::prop_ref`: for a struct property the struct's name, for
an object/class property the class's name, for an array/set the element type, for a map
`Key|Value`. It is found by scanning the FProperty for a pointer to an object of the expected
metaclass, so it survives rebuilds.

---

## Stage 2 — SDK tables

```powershell
python tools\sdk_from_dump.py native\build\dump\classes_<pid>.txt
```

| Output | Content |
|---|---|
| `sdk\G1R_SDK.h` | 4 675 C++ structs with exact offsets, `#pragma pack(1)`, compiles with `cl /std:c++17` |
| `sdk\props.tsv` | 61 392 rows: class, type, name, offset, size, target |
| `sdk\classes.tsv` | 48 557 classes/structs with hierarchy and counts |
| `sdk\functions.tsv` | 37 361 functions |
| `sdk\signatures.tsv` | 5 135 functions **with their parameter layout**, harvested from the live game (see below) |
| `sdk\README.md` | usage + limits |

### Function signatures (needs the game running)

The dump has function names only. `tools\harvest_signatures.py` asks the live probe for thousands
of them in batches (one `probe_cmd.txt` carries many `fn <Class> <Function>` lines) and writes
`sdk\signatures.tsv`: class, function, parameter count, whether it has an out parameter, and the
raw `Name@offset/size` string that `call_fn` needs.

```powershell
python tools\harvest_signatures.py --pid <game pid>
```

Coverage on 1.1: `/Script/G1R` 5 090 of 6 492 (78 %), `/Script/THQGDS` and the story-import package
almost complete, **`/Script/Angelscript` 0 of 13 322** — script classes are found by the probe but
their functions are not, neither through `find_object("Function", name, outer)` nor through the
`UStruct::Children` chain. Native functions inherited by script classes *are* found, which is what
matters for calling into the game.

Related fix in the core: the function cache used to hold 512 entries and then returned NULL, so
every later `call_fn`/`describe_fn` silently failed. It now falls back to a scratch slot.

```powershell
python tools\subsystem_index.py     # → sdk\subsystems.md, the map of gameplay subsystems
```

---

## Stage 3 — mappings (`.usmap`)

Without a mapping file UAssetAPI cannot read unversioned properties: every export comes out as
`RawExport` with base64. This game is unversioned everywhere.

```powershell
python tools\dump_to_usmap.py native\build\dump\classes_<pid>.txt sdk\G1R.usmap
# → 48 557 schemas, 84 775 names, 3.3 MB
```

Format (usmap version 0), reverse-engineered from UAssetAPI's `Usmap.cs`:

```
u16 0x30C4 | u8 version=0 | u8 compression=0 | u32 compressedSize | u32 decompressedSize
i32 nameCount, then per name: u8 length + ASCII bytes
i32 enumCount (0 — enums are written as plain bytes)
i32 schemaCount, then per schema:
    i32 nameIndex, i32 superIndex, u16 propCount, u16 serializedPropCount
    per property: u16 schemaIndex, u8 arraySize, i32 nameIndex, propertyData
propertyData: u8 type, then per type:
    struct  → i32 struct name index
    array/set/optional → recursive propertyData
    map     → recursive key, recursive value
    enum    → recursive inner, i32 enum name index
```

**Four traps, each of which produced a crash or a desync:**

1. The header must contain the compression byte and both sizes even at version 0.
2. Name indices are `i32`, name lengths are one byte at version 0.
3. `OptionalProperty` (28) is serialised **like a container** — writing it as a plain byte shifts
   every following schema and UAssetAPI dies with `List index out of range` in `ReadName`.
4. Arrays and maps only carry the element *name* in the dump, not its kind. `dump_to_usmap.py`
   guesses: a name that exists among structs → `StructProperty`, among classes → `ObjectProperty`,
   otherwise `ByteProperty`. This is a heuristic and the known source of remaining parse errors.

---

## Stage 4 — content unpack

```powershell
tools\bin\retoc\retoc.exe to-legacy `
    "C:\Program Files (x86)\Steam\steamapps\common\Gothic 1 Remake\G1R\Content\Paks" `
    "C:\Users\<USER>\Desktop\FOR GOTHIC 1 REMAKE\extracted\legacy"
```

**Pass the directory, not a single `.utoc`.** With only `G1R-Windows.utoc` and
`--no-script-objects`, every asset fails: script objects live in `global.utoc` and retoc merges
them when given the folder.

Result: 215 137 packages, 0 failures, 450 156 files, 61.0 GB in ~80 minutes.

```
.uexp    215 137   26.0 GB   package exports (the data)
.ubulk    19 882   32.1 GB   vertex buffers, textures, audio
.uasset  206 679    2.8 GB   package headers
.umap      8 458  160.1 MB   levels
```

The shader-library phase after the assets is slow, pointless for reading content, and can be
skipped by killing the process once the asset count stops growing (or with `--no-assets` on a
dedicated run).

---

## Stage 5 — content → JSON

```powershell
tools\uasset2json\bin\Release\net8.0\uasset2json.exe `
    "extracted\legacy\G1R\Content\Items" "extracted\json\Items" `
    --usmap "sdk\G1R.usmap" [--kismet] [--filter text] [--limit N]
```

Output: one `.json` per package with `Exports[].Data[]` as typed property arrays
(`ArrayPropertyData`, `ObjectPropertyData`, `StructPropertyData`, …) — real values, not base64.

Measured coverage: items 1 647/1 647, AI 103/103, blueprints 556/556, random sample 249/300
(the remainder are materials and fonts, which UAssetAPI keeps raw by design).

Build note: if a conversion is running, `dotnet build` cannot overwrite the exe (`MSB3021`).
Build to another folder: `dotnet build -c Release -o bin\kismet`.

---

## Stage 6 — blueprint bytecode

`--kismet` additionally writes `<Asset>.kismet.txt`: for every function, its bytecode as a JSON
AST (`Inst: LocalFinalFunction / JumpIfNot / CallMath / …`).

```powershell
python tools\compact_kismet.py extracted\json_kismet\Blueprints
# → <Asset>.kismet.compact.txt, one instruction per line
```

The compact form is what a human or an LLM can read:

```
== ExecuteUbergraph_AIAgentCharacter_Swampshark ==
   0: PushExecutionFlow(1761)
   5: ComputedJump(LocalVariable(?, EntryPoint))
  15: CallMath(Delay, KismetSystemLibrary, [Self, FloatConst(0.5), StructConst(...)])
  29: JumpIfNot(121, LocalVariable(?, CallFunc_IsValid_ReturnValue_2))
```

Productive use: the AI and visual-effect blueprints only. The gameplay logic is in AngelScript and
does not appear here (see [04_LIMITS_AND_OPEN.md](04_LIMITS_AND_OPEN.md)).

---

## Stage 7 — after a game patch

Everything that matters moves; this is the whole checklist.

1. `G1R\Version\version.txt` and the exe size change.
2. New core: re-derive `GUObjectArray` (`native/scan_gc.c` reads it out of memory), `ProcessEvent`
   from a UObject vtable, the FProperty offsets used by `list_members`, and the audio-guard patch
   offset (`native/scan_*` DLLs exist for this).
3. Re-run Stage 1 → 2 → 3. The `.usmap` and the SDK are regenerated in minutes; class layouts are
   stable, RVAs are not.
4. Re-run Stage 5 on the content if the game's data changed.
5. The coop modules usually keep working after a core update, because they talk to the engine
   through `CoreAPI`, not through hard-coded addresses.
