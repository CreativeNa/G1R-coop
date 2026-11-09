# Bridge: from the reverse engineering to coop work

For whoever continues the mod. Each row is a coop problem, the RE artifact that answers it, and the
concrete handle to use. Nothing here is implemented unless it says so.

---

## Where to look first

| Need | Open |
|---|---|
| a class's fields and their offsets | `sdk\props.tsv` (grep the class), `sdk\G1R_SDK.h` |
| what a class does / what functions it has | `sdk\functions.tsv`, `sdk\subsystems.md` |
| parameter layout of a function | live game: `tools\dev.ps1 probe "fn <Class> <Function>"` |
| an asset's content | `extracted\json\...` (items, AI, blueprints, UI) |
| an effect blueprint's logic | `extracted\json_kismet\...\*.kismet.compact.txt` |
| what exists in the game at all | `sdk\assets.tsv` (450 156 paths) |

---

## Task by task

### Damage on an NPC the other copy simulates

| | |
|---|---|
| Problem | the guest's hits do not reach an NPC owned by the host; ranged attacks never work |
| Handles | `GothicCharacter::GetDataModule_Targeting` → `DataModule_Targeting::GetTarget()` (`m_Target` @40); `DataModule_Targeting::m_TargetComp` @52 |
| Combat path | `AbilitySystemComponent::BP_ApplyGameplayEffectSpecToTarget(spec, target)` → `GothicGASLibrary::ApplyDamageTo(Source, Instigator, DamageCauser, Target, HitData@32/296, SweepResult@328/248, SourceObject)` |
| Implemented | targeted-ownership claim + health-delta bridge (`native\npc_module.c`, see `AI_HANDOFF.txt` #1, #5) — **unverified with two copies** |
| Open | `HitData` is 296 opaque bytes; replaying damage faithfully needs its layout (`sdk\props.tsv`, grep `HitData`) and `ApplyDamageTo` would then apply mitigation twice if fed a post-mitigation number |

### Dialogue

| | |
|---|---|
| Problem | an NPC talks to one player and walks past the other |
| Handles | `AbilityTask_ActConversationTopic::TaskActConversationTopic(OwningAbility@0/8, TopicToAct@8/8, ReturnValue@16/8)`; `ConversationTopic::Act()` (0 args); `ConversationTopic::EndConversation()` (0 args); `ConversationTopic::InviteParticipatingCharactersIntoConversation()` → bool |
| Recipe | observe `TaskActConversationTopic` → take `TopicToAct` → send its object name on the `S|` channel → on the other copy find the topic by name and call `Act()` |
| Caveat | calls that arrive from AngelScript bytecode carry **empty parameters** in the observer — if `TopicToAct` is not visible, compare state instead of observing the call |
| Implemented | no |

### Player death and shared save

| | |
|---|---|
| Handles | `GDS::log_on_player_death` (telemetry hook, easiest); `/Script/G1R` save namespace; `MainMenuWidget::OnContinueClicked` (used by the coop auto-continue) |
| Implemented | no; the design decision (shared death vs revive) is still open |

### Chests and containers

| | |
|---|---|
| Handles | `DataModule_Container` (contents, two TArray item lists), `Server_ConsumeItem(type, id, amount)`, `Server_MoveItemFromActorToOtherActor(hero, chest, ItemPos, slot, amount, targetSlot)`, `Server_AddNewItem(InventoryType, ItemDefinition, ItemAmount, Payload)` |
| Implemented | take-out replay and "emptied" sync; put-in not implemented |
| Note | `ItemPos` is an index into the hero's inventory and carries no item class — read the definition from the hero's container module before the move |

### Inventory, items, definitions

| | |
|---|---|
| Handles | `ItemDefinition` and subclasses (`ArmorDefinition` 39 props, `WeaponDefinition`, …); `GothicCharacter::GetInventory()` |
| Data | item definitions are converted to JSON in `extracted\json\Items\...` — use it to look up stats, stack sizes, weights |

### AI and enemies

| | |
|---|---|
| Handles | `GameplayAbility_CharacterAI` (64 functions), `GameplayAbility_CharacterAI_Gothic`, `AIState_Combat_G1R`, `GothicCharacter::GetPerception()` |
| Trap | unpossessing a mirrored NPC's controller crashes the perception code — the coop mirror keeps the controller possessed on purpose |
| Data | `extracted\json\AI\...`, bytecode in `json_kismet\AI\*.kismet.compact.txt` |

### Story and quests

| | |
|---|---|
| Handles | `StoryG1R` (one block of ~520 words + `Chapter`), 679 `Instance_Quest_*` with a one-byte state, `GameStory::RequestChapterHUDNotification(NewChapter)` |
| Implemented | full story/quest sync in `native\story_module.c`, verified by scripted tests on one PC |
| Note | the chapter banner is a local HUD event: sending the chapter number does not show it, the function must be called on the other copy |

### Cutscenes

| | |
|---|---|
| Handles | `GothicCinematicManagerSubsystem::ForceStartCinematic`, `Server_OnForceStartCinematic`, `Server_OnSkipCutsceneRequest`, `StopCinematicServer` |
| Trap | `StopCinematicServer` faults when no cinematic is running — guard it |

---

## Rules that came out of this work

1. Prefer the game's own path (call the function it calls) over writing state directly. Writing
   health 0 leaves a body that lies there alive and cannot be searched; the kill effect does not.
2. `FGameplayEffectSpec` cannot cross processes. Anything built on a spec must be replaced by
   "which actor was targeted" plus the resulting state change.
3. Calls from AngelScript bytecode reach the observer without parameters. If a hook looks empty,
   compare state.
4. A spawned actor is registered by `BFGTickOptimizerSystem` and can fault later; opt it out.
5. Set offsets come from the SDK, never from guesses; RVAs come from the exe and change every patch.
