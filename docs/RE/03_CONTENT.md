# Content map

What the game ships, where it lies, and what has already been turned into readable form.

---

## 1. Containers

`G1R\Content\Paks\`:

| File | Size | Content |
|---|---|---|
| `G1R-Windows.utoc` | 22.8 MB | index of the main container |
| `G1R-Windows.ucas` | 26.2 GB | the game's data |
| `G1R-Windows.pak` | 373.9 MB | legacy pak, still present |
| `global.utoc` / `global.ucas` | 9.5 MB | **script objects** — needed for a correct conversion |
| `G1R_DialogFacials_<lang>.ucas` | 0.7–0.75 GB each | dialogue face animation, one container per language (English, German, Russian, Polish, + foreign) |

Main container metadata: 115 349 chunks, 86 068 packages, compression Oodle, flags
`Compressed | Indexed`, TOC version `OnDemandMetaData`.

After `retoc to-legacy`: 215 137 packages, 450 156 files, 61.0 GB, 0 failures.

---

## 2. Where the content lives

`G1R\Content\`, by package count:

| Folder | Packages | What |
|---|---|---|
| `Assets` | 116 022 | the bulk: props, environment, meshes, materials by area |
| `AnimLibrary` | 36 408 | animation sequences and montages |
| `Maps` | 17 905 | levels and sublevels (`.umap`) |
| `FMOD` | 5 832 | audio: events and banks, wrapped in uassets (no loose `.bnk`) |
| `UI` | 3 401 | widgets, textures, fonts, input tables |
| `Items` | 3 295 | item, weapon, armor, ammo, food definitions |
| `Materials` | 1 673 | materials and instances |
| `WeatherPlugins` | 1 631 | weather systems |
| `Blueprints` | 1 174 | **visual effects only** — see the warning below |
| `FluidFlux` | 748 | water/fluid simulation |
| `InteractiveObjects` | 575 | chests, doors, levers, pickups |
| `Cinematics` | 434 | cutscene sequences |
| `Inputs` | 364 | input actions and contexts |
| `GameplayCues` | 220 | GAS cosmetic cues |
| `AI` | 208 | AI definitions and behaviour data |
| `Textures` | 156 | shared textures |
| `PhotoMode`, `LensAndFilmPostProcess`, `AutomatedTest`, … | < 200 each | extras |

Plus `Engine\` (1 359 files, 163.7 MB) — engine default assets that came along.

**Warning about blueprints:** all 556 converted blueprint packages are visual effects (banners,
tornadoes, decals, bridges, spline meshes). Gameplay logic is not there — it is in the
`/Script/Angelscript` layer (35 486 classes) and does not exist as an asset at all.

---

## 3. Data that is plain memory, not an asset

Three things a mod reads directly instead of parsing files:

* **Story state** — `StoryG1R`, one object: ~520 int/time words (story flags) plus `Chapter`.
  Examples: `Drax_GotBeer`, `Diego_After_Gamestart`.
* **Quests** — 679 `Instance_Quest_*` objects, one byte of state each
  (`0` none, `1` available, `2` running, `3` failed, `4` succeeded).
* **Item definitions** — `ItemDefinition` and its subclasses (`ArmorDefinition`: 39 props,
  `WeaponDefinition`, ammo, food) are UObjects, reachable from the item actor and from
  `DataModule_Container` for containers.

---

## 4. What has been converted to readable form

| Folder | Packages | JSON | Bytecode |
|---|---|---|---|
| `Items` | 1 647 | yes | — |
| `Blueprints` | 556 | yes | 122 files, compacted |
| `UI` (without `Textures`) | 833 | yes | — |
| `AI` | 103 | yes | 32 files with functions |

Totals: 3 139 JSON packages, 374.6 MB; 122 bytecode files, 0.58 MB.
Index: `sdk\corpus_index.md`. Full file list: `sdk\assets.tsv` (450 156 rows).

The JSON is UAssetAPI's serialisation: `Exports[].Data[]` as typed property arrays with real
values. Example (`DefaultAnimBoneCompressionSettings.json`):

```json
"$type":"UAssetAPI.PropertyTypes.Objects.ArrayPropertyData",
"ArrayType":"ObjectProperty","Name":"Codecs",
"Value":[{"$type":"...ObjectPropertyData","Name":"0","Value":4}, ...]
```

---

## 5. What is extracted but not parsed

Everything else: `Assets` (116k), `AnimLibrary` (36k), `Maps` (17.9k), `FMOD` (5.8k), `Materials`,
`Cinematics`, `InteractiveObjects`, …

They are on disk as `.uasset/.uexp/.ubulk` and can be converted with the same command. Reasons not
to do it blindly:

* meshes and textures produce enormous JSON (`SM_MiltenColumn_RBD.json` is 57 MB) and carry no
  gameplay meaning;
* the whole set would take ~25 hours at the measured 2.3 packages/s;
* the valuable part (item definitions, UI trees, AI data, effect blueprints) is already converted.

If a specific area is needed (e.g. `InteractiveObjects` for chest behaviour), run the converter on
that folder only — a few minutes.

---

## 6. Localisation and audio

* No loose `.locres`, `.json` or `.csv` in the package tree: localisation lives inside the assets
  and inside `FText` values.
* Audio is FMOD: the banks are wrapped as `.uasset` in `G1R\Content\FMOD` (5 832 packages) and the
  streams sit in `.ubulk`. There are no standalone `.bnk`/`.wem` files, so extracting audio means
  parsing those wrappers, not copying files.
* Dialogue face animation ships per language in separate `.ucas` containers — that is why Russian,
  Polish, German and English each have their own ~700 MB file.

---

## 7. Numbers worth keeping

| | |
|---|---|
| Packages in the game | 215 137 |
| Files after unpack | 450 156 |
| Classes in the SDK | 48 557 (of which 35 486 are `/Script/Angelscript`) |
| Native game classes (`/Script/G1R`) | 2 349 |
| Properties / functions | 61 392 / 37 361 |
| Quests | 679 |
| Story flags | ~520 |
| Dialogue-language containers | 5 |
