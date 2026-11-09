# GameplayAbility_CharacterAI

`class` in `/Script/G1R`, 20 own properties, 64 own functions.

Inheritance: `Object` → `GameplayAbility` → `GameplayAbilityBase` → `ScriptGameplayAbility` → `GameplayAbility_AI` → `GameplayAbility_CharacterAI`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 1328 | 8 | ClassProperty | `InitialDailyRoutineClass` | `ObjectProperty(Class)` |
| 1336 | 8 | ClassProperty | `ConversationAIStateClass` | `ObjectProperty(Class)` |
| 1344 | 8 | ClassProperty | `SelfConversationAIStateClass` | `ObjectProperty(Class)` |
| 1352 | 8 | ClassProperty | `AfterDefeatedAIStateClass` | `ObjectProperty(Class)` |
| 1360 | 8 | ClassProperty | `DefeatedAIStateClass` | `ObjectProperty(Class)` |
| 1368 | 8 | ClassProperty | `ControlledAIStateClass` | `ObjectProperty(Class)` |
| 1376 | 8 | ClassProperty | `FoundSomeoneInMyBedAIStateClass` | `ObjectProperty(Class)` |
| 1384 | 8 | ClassProperty | `InterruptedSomeoneWaitingAIStateClass` | `ObjectProperty(Class)` |
| 1392 | 16 | ArrayProperty | `CurrentStateStack` | `ArrayProperty(SetProperty(ObjectProperty(CharacterAIState)))` |
| 1408 | 80 | SetProperty | `ActiveAITasks` | `SetProperty(ObjectProperty(CharacterAIState))` |
| 1488 | 8 | ObjectProperty | `ScheduledNextState` | `ObjectProperty(CharacterAIState)` |
| 1512 | 8 | ClassProperty | `HighPriorityAssessmentModuleClass` | `ObjectProperty(Class)` |
| 1520 | 8 | ClassProperty | `AssessmentModuleClass` | `ObjectProperty(Class)` |
| 1528 | 80 | MapProperty | `JoinedGroups` | `MapProperty(ArrayProperty(EnumProperty),ObjectProperty(AIState_DailyRoutine))` |
| 1608 | 16 | ArrayProperty | `ActionsToBindAsFunctions` | `ArrayProperty(EnumProperty)` |
| 1624 | 1 | EnumProperty | `DesiredWalkSpeed` |  |
| 1632 | 8 | ObjectProperty | `DailyRoutineInstance` | `ObjectProperty(AIState_DailyRoutine)` |
| 1640 | 80 | MapProperty | `SpawnedStorageValueSets` | `MapProperty(MapProperty(MapProperty(BoolProperty,StructProperty(GameplayEventData)),MapProperty(BoolProperty,StructProperty(GameplayEventData))),MapProperty(Ma` |
| 1720 | 80 | MapProperty | `PermanentStorageValueSets` | `MapProperty(MapProperty(BoolProperty,StructProperty(GameplayEventData)),MapProperty(BoolProperty,StructProperty(GameplayEventData)))` |
| 1800 | 80 | MapProperty | `AIValueSetRemap` | `MapProperty(BoolProperty,StructProperty(GameplayEventData))` |

## Functions

* `SwitchToDailyRoutineIfNothingElseToDo`
* `SwitchToDailyRoutine`
* `SwitchToConversationState`
* `SwitchAIStateWithOthersImmediately`
* `SwitchAIStateWithOthers`
* `SwitchAIStateImmediatelyToClass`
* `SwitchAIStateImmediately`
* `SwitchAIState`
* `StopTargetingEnemy`
* `StartScheduledNextState`
* `SetTargetEnemyComponent`
* `SetTargetEnemy`
* `ResolveLocationByName`
* `RemoveFromSpawnedStorage`
* `RemoveFromPermanentStorage`
* `RateRangedWeaponStrength`
* `RateMeleeWeaponStrength`
* `ProcessAllPendingAssessments`
* `OnGracefulEndRequestFulfilled`
* `LeaveGroupsWithClass`
* `LeaveAllGroups`
* `JoinGroup`
* `IsUnconscious`
* `IsInState`
* `IsFocusedBy`
* `IsDoingDailyRoutine`
* `IsDoingConversationState`
* `IsDoingAITaskOfClass`
* `HasPendingScheduledState`
* `HasInSpawnedStorage`
* `HasInPermanentStorage`
* `HasCurrentTerritoryOfClass`
* `HandleNewAvatarGameplayReady`
* `GetTargetEnemy`
* `GetSelf`
* `GetScheduledDailyRoutineAIStateTemplate`
* `GetPersistentSelf`
* `GetGroupStatus`
* `GetDailyRoutineTemplate`
* `GetDailyRoutineIfActive`
* `GetCurrentTerritoryClass`
* `GetCurrentTerritory`
* `GetCurrentState`
* `GetCurrentRootState`
* `GetActiveTasksOfClass`
* `FindGroupInPerceivedCharacters`
* `FindGroupInCharactersAtLocation`
* `FindBestRangedWeapon`
* `FindBestMeleeWeapon`
* `FindActiveStateByClass`
* `EndAllStatesAndTasks`
* `CreateAndJoinGroup`
* `CancelStatesOfClass`
* `CancelConversationStateAndDoDailyRoutine`
* `CancelAllStatesAndTasks`
* `CancelAllExceptRootState`
* `CancelAITasksOfClass`
* `BP_SetupPerceptions`
* `BP_HandleRevivedInSimulation`
* `BP_HandleKilledCharacter`
* `BP_EvaluateAssessmentConditions`
* `AssessEventWithExtraTags`
* `AssessEventFromPerception`
* `AssessEvent`

## Subclasses (1)

`GameplayAbility_CharacterAI_Gothic`
