# GameplayAbility_CharacterAI_Gothic

`class` in `/Script/Angelscript`, 30 own properties, 26 own functions.

Inheritance: `Object` → `GameplayAbility` → `GameplayAbilityBase` → `ScriptGameplayAbility` → `GameplayAbility_AI` → `GameplayAbility_CharacterAI` → `GameplayAbility_CharacterAI_Gothic`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 1944 | 8 | ObjectProperty | `ItemActionScoringEntryManager` | `ObjectProperty` |
| 1952 | 8 | ObjectProperty | `CombatTargetScoringEntryManager` | `ObjectProperty` |
| 1960 | 16 | StructProperty | `SelectedItemAction` | `StructProperty(ItemActionHandler)` |
| 1976 | 80 | MapProperty | `LastTimeItemActionUsages` | `MapProperty(ObjectProperty(Class),StructProperty(GameplayTag))` |
| 2056 | 8 | ClassProperty | `CrimeProcessingSubsystemClass` | `ObjectProperty(Class)` |
| 2064 | 1 | EnumProperty | `CrimeSeverityTowardsPlayer` |  |
| 2068 | 4 | IntProperty | `CurrentFineValueForPlayer` |  |
| 2072 | 4 | IntProperty | `CurrentFineCrimeCountForPlayer` |  |
| 2076 | 1 | BoolProperty | `bCanForgivePlayerWithFine` |  |
| 2080 | 80 | MapProperty | `States` | `MapProperty(ObjectProperty(GothicCharacterState),ObjectProperty(GothicCharacterState))` |
| 2160 | 8 | ObjectProperty | `CurrentCharacterStateOfInterest` | `ObjectProperty(GothicCharacterState)` |
| 2169 | 1 | BoolProperty | `bEnableDisengage` |  |
| 2176 | 8 | DoubleProperty | `DisengageDistanceFromPreferredLocation` |  |
| 2184 | 8 | DoubleProperty | `MinimumPreferredLocationConflictRadius` |  |
| 2192 | 8 | DoubleProperty | `CombatDistancePreferredLocationRadiusMultiplier` |  |
| 2200 | 8 | DoubleProperty | `WarnignHostileDistance` |  |
| 2208 | 8 | DoubleProperty | `MaximumRangedAttackHorizontalDistance` |  |
| 2216 | 1 | BoolProperty | `bRangedAttackRequiresRangedWeapon` |  |
| 2217 | 1 | BoolProperty | `bCanReachSwimmingTargetFromLand` |  |
| 2288 | 32 | StructProperty | `AllowInstantCancelInteractions` | `StructProperty(GameplayTagContainer)` |
| 2320 | 8 | DoubleProperty | `EngageConflictDistance` |  |
| 2328 | 8 | DoubleProperty | `EngageConflictHeightLimit` |  |
| 2336 | 8 | DoubleProperty | `MaxDistanceFromSourceCharacterToSynchAwareness` |  |
| 2344 | 8 | DoubleProperty | `MaxDistanceFromSensedCharacterToSynchAwareness` |  |
| 2352 | 32 | OptionalProperty | `InitialConflictPosition` | `OptionalProperty(DoubleProperty)` |
| 2392 | 8 | DoubleProperty | `FleeCurve_BaseThreshold` |  |
| 2400 | 8 | DoubleProperty | `FleeCurve_ThresholdScale` |  |
| 2408 | 8 | DoubleProperty | `FleeCurve_Steepness` |  |
| 2416 | 8 | DoubleProperty | `FleeCurve_LevelShield` |  |
| 2424 | 8 | DoubleProperty | `FleeCurve_GroupConfidence` |  |

## Functions

* `CheckAnyHostilesOrEnemiesSensed`
* `PerceptionEvent_CharacterSeenUsingOwnedInteractable`
* `PerceptionEvent_CharacterHeardUsingOwnedInteractable`
* `OnSensedPlayerAnyAwareness`
* `PerceptionEvent_CharacterHeardTrespassingInArea`
* `PerceptionEvent_CharacterSeenInArea`
* `PerceptionEvent_AssessHostilesAndEnemiesAround`
* `PerceptionEvent_SensedWatchHostile`
* `PerceptionEvent_SensedWarning`
* `PerceptionEvent_SensedCombat`
* `OnSeenSomeoneSucceedPickpocketOther`
* `PerceptionEvent_Execution`
* `PerceptionEvent_JustSensedOtherStartCastingSpell_LowThreat`
* `OnLostPlayerSight_ClearLastSeenFlag`
* `OnGainedPlayerSight_TrackLastSeen`
* `SeenFighting_Creature`
* `OnCreatureKilledWithoutPlayerInvolvement`
* `WasPlayerInvolvedInKillingCharacter`
* `AmICurrentlyInvolvedWithPlayer`
* `BP_HandleKilledCharacter`
* `BP_SetupPerceptions`
* `FindBestRangedWeapon`
* `FindBestMeleeWeapon`
* `RateRangedWeaponStrength`
* `RateMeleeWeaponStrength`
* `GetCrimeProcessingSubsystem`

## Subclasses (6)

`GameplayAbility_CharacterAI_Human`, `GameplayAbility_CharacterAI_Orc`, `GameplayAbility_CharacterAI_TestOrc`, `GameplayAbility_CharacterAI_TestOrcSimple`, `GameplayAbility_CharacterAI_TestOrcSimple_Taunts`, `GameplayAbility_CreatureAI`
