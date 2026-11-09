# AbilitySystemComponent

`class` in `/Script/GameplayAbilities`, 27 own properties, 92 own functions.

Inheritance: `Object` → `ActorComponent` → `GameplayTasksComponent` → `AbilitySystemComponent`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 296 | 16 | ArrayProperty | `DefaultStartingData` | `ArrayProperty(NameProperty)` |
| 312 | 8 | NameProperty | `AffectedAnimInstanceTag` |  |
| 744 | 4 | FloatProperty | `OutgoingDuration` |  |
| 748 | 4 | FloatProperty | `IncomingDuration` |  |
| 784 | 16 | ArrayProperty | `ClientDebugStrings` | `ArrayProperty(ArrayProperty(BoolProperty))` |
| 800 | 16 | ArrayProperty | `ServerDebugStrings` | `ArrayProperty(BoolProperty)` |
| 904 | 1 | BoolProperty | `UserAbilityActivationInhibited` |  |
| 905 | 1 | BoolProperty | `ReplicationProxyEnabled` |  |
| 906 | 1 | BoolProperty | `bSuppressGrantAbility` |  |
| 907 | 1 | BoolProperty | `bSuppressGameplayCues` |  |
| 912 | 16 | ArrayProperty | `SpawnedTargetActors` | `ArrayProperty(ObjectProperty(Actor))` |
| 968 | 8 | ObjectProperty | `OwnerActor` | `ObjectProperty(Actor)` |
| 976 | 8 | ObjectProperty | `AvatarActor` | `ObjectProperty(Actor)` |
| 1000 | 288 | StructProperty | `ActivatableAbilities` | `StructProperty(GameplayAbilitySpecContainer)` |
| 1336 | 16 | ArrayProperty | `AllReplicatedInstancedAbilities` | `ArrayProperty(StructProperty(GameplayAbilityRepAnimMontage))` |
| 1896 | 64 | StructProperty | `RepAnimMontageInfo` | `StructProperty(GameplayAbilityRepAnimMontage)` |
| 1960 | 1 | BoolProperty | `bCachedIsNetSimulated` |  |
| 1961 | 1 | BoolProperty | `bPendingMontageRep` |  |
| 1968 | 40 | StructProperty | `LocalAnimMontageInfo` | `StructProperty(GameplayAbilityLocalAnimMontage)` |
| 2168 | 768 | StructProperty | `ActiveGameplayEffects` | `StructProperty(ActiveGameplayEffectsContainer)` |
| 2936 | 296 | StructProperty | `ActiveGameplayCues` | `StructProperty(ActiveGameplayCueContainer)` |
| 3232 | 296 | StructProperty | `MinimalReplicationGameplayCues` | `StructProperty(ActiveGameplayCueContainer)` |
| 3824 | 16 | ArrayProperty | `BlockedAbilityBindings` | `ArrayProperty(StructProperty(MinimalReplicationTagCountMap))` |
| 4136 | 104 | StructProperty | `MinimalReplicationTags` | `StructProperty(MinimalReplicationTagCountMap)` |
| 4240 | 16 | ArrayProperty | `SpawnedAttributes` | `ArrayProperty(StructProperty(MinimalReplicationTagCountMap))` |
| 4272 | 104 | StructProperty | `ReplicatedLooseTags` | `StructProperty(MinimalReplicationTagCountMap)` |
| 4384 | 280 | StructProperty | `ReplicatedPredictionKeyMap` | `StructProperty(ReplicatedPredictionKeyMap)` |

## Functions

* `UpdateActiveGameplayEffectSetByCallerMagnitudes`
* `UpdateActiveGameplayEffectSetByCallerMagnitude`
* `TryActivateAbilityByClass`
* `TryActivateAbility`
* `TryActivateAbilitiesByTag`
* `TargetConfirm`
* `TargetCancel`
* `SetUserAbilityActivationInhibited`
* `SetActiveGameplayEffectLevelUsingQuery`
* `SetActiveGameplayEffectLevel`
* `ServerTryActivateAbilityWithEventData`
* `ServerTryActivateAbility`
* `ServerSetReplicatedTargetDataCancelled`
* `ServerSetReplicatedTargetData`
* `ServerSetReplicatedEventWithPayload`
* `ServerSetReplicatedEvent`
* `ServerSetInputReleased`
* `ServerSetInputPressed`
* `ServerPrintDebug_RequestWithStrings`
* `ServerPrintDebug_Request`
* `ServerEndAbility`
* `ServerCurrentMontageSetPlayRate`
* `ServerCurrentMontageSetNextSectionName`
* `ServerCurrentMontageJumpToSectionName`
* `ServerCancelAbility`
* `ServerAbilityRPCBatch`
* `RemoveActiveGameplayEffectBySourceEffect`
* `RemoveActiveGameplayEffect`
* `RemoveActiveEffectsWithTags`
* `RemoveActiveEffectsWithSourceTags`
* `RemoveActiveEffectsWithGrantedTags`
* `RemoveActiveEffectsWithAppliedTags`
* `ReleaseInputID`
* `PressInputID`
* `OnSpawnedAttributesEndPlayed`
* `OnRep_SpawnedAttributes`
* `OnRep_ServerDebugString`
* `OnRep_ReplicatedAnimMontage`
* `OnRep_OwningActor`
* `OnRep_ClientDebugString`
* `OnRep_ActivateAbilities`
* `OnOwnerActorDestroyed`
* `OnAvatarActorDestroyed`
* `NetMulticast_InvokeGameplayCuesExecuted_WithParams`
* `NetMulticast_InvokeGameplayCuesExecuted`
* `NetMulticast_InvokeGameplayCuesAddedAndWhileActive_WithParams`
* `NetMulticast_InvokeGameplayCueExecuted_WithParams`
* `NetMulticast_InvokeGameplayCueExecuted_FromSpec`
* `NetMulticast_InvokeGameplayCueExecuted`
* `NetMulticast_InvokeGameplayCueAddedAndWhileActive_WithParams`
* `NetMulticast_InvokeGameplayCueAddedAndWhileActive_FromSpec`
* `NetMulticast_InvokeGameplayCueAdded_WithParams`
* `NetMulticast_InvokeGameplayCueAdded`
* `MakeOutgoingSpec`
* `MakeEffectContext`
* `K2_InitStats`
* `K2_GiveAbilityAndActivateOnce`
* `K2_GiveAbility`
* `IsGameplayCueActive`
* `InputConfirm`
* `InputCancel`
* `GetUserAbilityActivationInhibited`
* `GetGameplayTagCount`
* `GetGameplayEffectMagnitude`
* `GetGameplayEffectCount_IfLoaded`
* `GetGameplayEffectCount`
* `GetGameplayAttributeValue`
* `GetAttributeSet`
* `GetAllAttributes`
* `GetAllAbilities`
* `GetActiveEffectsWithAllTags`
* `GetActiveEffects`
* `FindAllAbilitiesWithTags`
* `FindAllAbilitiesWithInputID`
* `FindAllAbilitiesMatchingQuery`
* `ClientTryActivateAbility`
* `ClientSetReplicatedEvent`
* `ClientPrintDebug_Response`
* `ClientEndAbility`
* `ClientCancelAbility`
* `ClientActivateAbilitySucceedWithEventData`
* `ClientActivateAbilitySucceed`
* `ClientActivateAbilityFailed`
* `ClearAllAbilitiesWithInputID`
* `ClearAllAbilities`
* `ClearAbility`
* `BP_ApplyGameplayEffectToTarget`
* `BP_ApplyGameplayEffectToSelf`
* `BP_ApplyGameplayEffectSpecToTarget`
* `BP_ApplyGameplayEffectSpecToSelf`
* `AbilityConfirmOrCancel__DelegateSignature`
* `AbilityAbilityKey__DelegateSignature`

## Subclasses (1)

`AngelscriptAbilitySystemComponent`
