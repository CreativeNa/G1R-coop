# Engine and code structure

Everything here was read out of the running game: the engine's own reflection data, the container
metadata, and calls made through `ProcessEvent`. Nothing is inferred from file names.

**Build:** `Build102_CL175960`, exe 175 029 760 bytes, UE 5.4, Hazelight AngelScript.

---

## 1. What the game is made of

| Piece | Evidence |
|---|---|
| Unreal Engine 5.4 | package version `UE5: 1012`, `ObjectVersionUE5 = PROPERTY_TAG_COMPLETE_TYPE_NAME`, IoStore TOC version `OnDemandMetaData` |
| Hazelight AngelScript | 35 486 classes in `/Script/Angelscript`, `AngelscriptCode` module, `GVL_*` generated voice-line classes |
| Gameplay Ability System | `GameplayAbility*`, `GE_*` execution calculations, `AttributeSet_Health`, `AbilitySystemComponent` |
| BFG (Mass) | `BFGInstancedSkeletalMesh*`, `BFGTickOptimizerSystem`, `BFGInterpolationSystem` — this is the system that faults when a spawned puppet is registered in it (crash `0xd50` in the coop mod) |
| CommonUI | `CommonInputActionDataBase`, `CommonGenericInputActionDataTable`, most widgets |
| FMOD | `FMODStudio` plugin, `GothicAudioComponent`, `fmodstudio.dll` in the crash stacks |
| THQGDS | `/Script/THQGDS` — an analytics/session layer with `log_on_*` events |
| Alkimia story import | `/Script/AlkimiaStoryFileImport`, `ConversationDebuggerSubsystem` |

Plugin list from `G1R/Plugins`: `DLSS`, `FMODStudio`, `StreamlineCore`, `THQGDS`, `XeSS`.

---

## 2. Memory layout facts a mod needs

These are the constants the coop DLL uses; they are stable in 1.1 and were re-derived after the
1.0 → 1.1 patch.

| What | Value / how it is found |
|---|---|
| `GUObjectArray` | RVA `0x9E9FBC0` on 1.1 (was `0x9B9D440`); it is an `FChunkedFixedUObjectArray`, objects pointer at `+0x10` |
| Object → class | `UObject::ClassPrivate` at `+0x40` |
| Object → outer | `UObject::OuterPrivate` at `+0x20` |
| `ProcessEvent` | taken from a UObject vtable, **slot 95** on 1.1 (hooking it is how the coop core gets a game-thread tick) |
| Property list of a UStruct | `ChildProperties` at `UStruct + 0x50`, walked through `FField::Next` |
| Property name | `FProperty::NamePrivate`, offset found at start-up (`g_off_name`) |
| Property type | `FProperty + 8` → `FFieldClass*`. **This is not a UObject**: read its `FName` with `fname_str`, not `obj_name` |
| Property offset / size | `Offset_Internal` and `ElementSize` (size lives at `NamePrivate + 0x14` in this build) |
| Struct / class a property points at | a pointer at **`+0x70`** inside the FProperty; the same offset works for `FStructProperty::Struct`, `FObjectProperty::PropertyClass` and `FArrayProperty::Inner` |
| Map key/value | `+0x70` and `+0x78` (KeyProp, ValueProp) |

Function parameters are **not** in the reflection dump — a UFunction's layout only exists at run
time. Get it from the live game:

```
tools\dev.ps1 probe "fn GothicGASLibrary ApplyDamageTo"
→ GothicGASLibrary:ApplyDamageTo(Source@0/8 Instigator@8/8 DamageCauser@16/8 Target@24/8
                                 HitData@32/296 SweepResult@328/248 SourceObject@576/8 ReturnValue@584/8(out))
```

That string is exactly what `CoreAPI::call_fn(class, function, nargs, names, values, sizes, ...)`
needs.

---

## 3. How the game's own code is organised

### Character

`GothicCharacter : ClientAuthoritativeCharacter` — 38 own properties, 91 functions. It is not a
fat class: everything is composed out of `DataModule_*` components, each reachable by a getter:

```c
GothicCharacter::GetDataModule_Targeting()   → DataModule_Targeting   (m_Target @40, m_TargetComp @52)
GothicCharacter::GetInventory()              → the inventory module
GothicCharacter::GetAbilitySystemComponent() → the ASC used for every GE call
GothicCharacter::GetCharacterGlobalId()      → a stable cross-copy id (better than the object name)
GothicCharacter::IsDead() / IsDefeated()     → the two separate notions of "down"
```

`DataModule` subclasses seen in the SDK include `DataModule_Targeting`, `DataModule_Combat`,
`DataModule_BaseStats`, `DataModule_Container` (chests and bodies), plus an inventory module.

### Combat

Call chain, confirmed by observing a real hit:

```
weapon hit → AbilitySystemComponent::BP_ApplyGameplayEffectSpecToTarget(spec, target)
           → GothicGASLibrary::ApplyDamageTo(Source, Instigator, DamageCauser, Target,
                                             HitData /*296 bytes*/, SweepResult /*248*/, SourceObject)
           → GE_Ex_Damage (execution calculation: mitigation happens here)
           → AttributeSet_Health
```

`GothicGASLibrary` also exposes `InitializeHitData(Payload, HitContext)`, `ApplyDebuffGameplayEffects`,
`GetAbilitySystemComponent`, `FindAttributeSetsFromAttributeName`.

The spec (`FGameplayEffectSpecHandle`) is opaque between processes — it cannot be serialised and
sent to a second game instance. That single fact drives most coop design decisions.

### Dialogue

```
AbilityTask_ActConversationTopic::TaskActConversationTopic(OwningAbility, TopicToAct)
ConversationTopic::Act()                       // no arguments
ConversationTopic::EndConversation()           // no arguments
ConversationTopic::InviteParticipatingCharactersIntoConversation() → bool
ConversationTopic::AreParticipatingCharactersInSameConversation()
```

`ConversationTopic` carries 20 properties and 32 functions: `GetKnowledge`, `GetCurrentConversationGroup`,
`FindTopicClassByName`, `BP_IsVisible`, `AreParticipatingCharactersAbleToEnterConversation`.
`ConversationTopicSet` holds topic lists. `AbilityTask_HandleSubdialog` handles the branch where
the player picks a reply.

### Story and quests

* `StoryG1R : GameStory` — one flat block of ~520 int/time words (`Drax_GotBeer`, `Diego_After_Gamestart`, …)
  plus `Chapter` (property of the parent, offset 80).
* 679 `Instance_Quest_*` objects, each with a one-byte `State`: `0` none, `1` available, `2` running,
  `3` failed, `4` succeeded.
* `GameStory::RequestChapterHUDNotification(NewChapter)` shows the chapter banner. The game's real
  trigger does not go through the observed UFunction, so the banner has to be detected by a chapter
  number change.

### Save / load

`/Script/G1R` has a `Save` package namespace; the load path is reachable from the main menu
(`MainMenuWidget::OnContinueClicked`) and from the save subsystem. A world change is observable as
`GothicCharacter` pointer replacement — the coop core uses exactly that to reset all NPC state.

### AI

* `GameplayAbility_CharacterAI` (20 props, 64 functions), `GameplayAbility_CharacterAI_Gothic` in
  script, `AIState_Combat_G1R`, `GameplayAbilityConversationV2`.
* Perception: `GothicCharacter::GetPerception()`; unpossessing an NPC's controller crashes the
  perception code (a coop finding, not a game bug).
* Behaviour trees and states are mostly in `/Script/Angelscript`.

### Analytics (GDS)

`GDS` in `/Script/THQGDS` is a telemetry singleton with ready events:

```
log_on_dialogue_execution   log_on_player_death     log_on_npc_killed
log_on_quest_update         log_on_inventory_update log_on_equipment_update
log_on_combat_start         log_on_level_up         log_on_guild_changed
log_on_crime_registered     log_on_pickpocket_attempt log_on_lockpick_result
get_player_id               get_event_session_id
```

For a mod these are free observation points: if a gameplay event is hard to hook, the matching
`log_on_*` call is usually easier to catch.

---

## 4. Subsystem sizes (from the reflection SDK)

| Subsystem | classes matching the keyword |
|---|---|
| Combat / GAS | 5 360 |
| Character / Stats | 4 000+ |
| AI / Behaviour | 2 000+ |
| UI / HUD | 1 500+ |
| Animation | 1 000+ |
| Dialogue | 300+ |
| Story / Quests | 300+ |
| Inventory / Items | 300+ |
| Magic / Spells | 200+ |

The exact lists, with the classes that carry the most members and their entry-point function
names, are in `sdk/subsystems.md`.

---

## 5. Traps that cost time

* `FFieldClass` is not a UObject — `obj_name` on it returns nothing.
* The engine hides spawned characters every tick (`bHidden`), which is why a mod that spawns an
  actor must re-show it or hide a *component* instead.
* `BFGTickOptimizerSystem` tracks spawned actors and faults (null at `0xd50`) when one is
  registered and then left behind — opt the actor out with
  `SetTickOptimizationRuntime_Enabled(actor, false)`.
* `-nosound` crashes the audio library.
* An audio predicate crashes on a null argument at a fixed exe offset; the coop core patches it.
* `FName::ToString` allocates and leaked memory in a hot path; cache the conversion.
* Scanning every object takes tens of milliseconds — never per frame.
