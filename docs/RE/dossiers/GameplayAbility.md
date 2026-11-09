# GameplayAbility

`class` in `/Script/GameplayAbilities`, 30 own properties, 56 own functions.

Inheritance: `Object` → `GameplayAbility`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 168 | 32 | StructProperty | `AbilityTags` | `StructProperty(GameplayTagContainer)` |
| 200 | 1 | BoolProperty | `bReplicateInputDirectly` |  |
| 201 | 1 | BoolProperty | `RemoteInstanceEnded` |  |
| 206 | 1 | ByteProperty | `ReplicationPolicy` |  |
| 207 | 1 | ByteProperty | `InstancingPolicy` |  |
| 208 | 1 | BoolProperty | `bServerRespectsRemoteAbilityCancellation` |  |
| 209 | 1 | BoolProperty | `bRetriggerInstancedAbility` |  |
| 216 | 24 | StructProperty | `CurrentActivationInfo` | `StructProperty(GameplayAbilityActivationInfo)` |
| 240 | 176 | StructProperty | `CurrentEventData` | `StructProperty(GameplayEventData)` |
| 416 | 1 | ByteProperty | `NetExecutionPolicy` |  |
| 417 | 1 | ByteProperty | `NetSecurityPolicy` |  |
| 424 | 8 | ClassProperty | `CostGameplayEffectClass` | `ObjectProperty(Class)` |
| 432 | 16 | ArrayProperty | `AbilityTriggers` | `ArrayProperty(ObjectProperty(Class))` |
| 448 | 8 | ClassProperty | `CooldownGameplayEffectClass` | `ObjectProperty(Class)` |
| 456 | 32 | StructProperty | `CancelAbilitiesWithTag` | `StructProperty(GameplayTagContainer)` |
| 488 | 32 | StructProperty | `BlockAbilitiesWithTag` | `StructProperty(GameplayTagContainer)` |
| 520 | 32 | StructProperty | `ActivationOwnedTags` | `StructProperty(GameplayTagContainer)` |
| 552 | 32 | StructProperty | `ActivationRequiredTags` | `StructProperty(GameplayTagContainer)` |
| 584 | 32 | StructProperty | `ActivationBlockedTags` | `StructProperty(GameplayTagContainer)` |
| 616 | 32 | StructProperty | `SourceRequiredTags` | `StructProperty(GameplayTagContainer)` |
| 648 | 32 | StructProperty | `SourceBlockedTags` | `StructProperty(GameplayTagContainer)` |
| 680 | 32 | StructProperty | `TargetRequiredTags` | `StructProperty(GameplayTagContainer)` |
| 712 | 32 | StructProperty | `TargetBlockedTags` | `StructProperty(GameplayTagContainer)` |
| 776 | 16 | ArrayProperty | `ActiveTasks` | `ArrayProperty(ObjectProperty(AnimMontage))` |
| 808 | 8 | ObjectProperty | `CurrentMontage` | `ObjectProperty(AnimMontage)` |
| 912 | 1 | BoolProperty | `bIsActive` |  |
| 913 | 1 | BoolProperty | `bIsAbilityEnding` |  |
| 914 | 1 | BoolProperty | `bIsCancelable` |  |
| 915 | 1 | BoolProperty | `bIsBlockingOtherAbilities` |  |
| 936 | 1 | BoolProperty | `bMarkPendingKillOnAbilityEnd` |  |

## Functions

* `SetShouldBlockOtherAbilities`
* `SetCanBeCanceled`
* `SendGameplayEvent`
* `RemoveGrantedByEffect`
* `MontageStop`
* `MontageSetNextSectionName`
* `MontageJumpToSection`
* `MakeTargetLocationInfoFromOwnerSkeletalMeshComponent`
* `MakeTargetLocationInfoFromOwnerActor`
* `MakeOutgoingGameplayEffectSpec`
* `K2_ShouldAbilityRespondToEvent`
* `K2_RemoveGameplayCue`
* `K2_OnEndAbility`
* `K2_HasAuthority`
* `K2_ExecuteGameplayCueWithParams`
* `K2_ExecuteGameplayCue`
* `K2_EndAbilityLocally`
* `K2_EndAbility`
* `K2_CommitExecute`
* `K2_CommitAbilityCost`
* `K2_CommitAbilityCooldown`
* `K2_CommitAbility`
* `K2_CheckAbilityCost`
* `K2_CheckAbilityCooldown`
* `K2_CancelAbility`
* `K2_CanActivateAbility`
* `K2_ApplyGameplayEffectSpecToTarget`
* `K2_ApplyGameplayEffectSpecToOwner`
* `K2_AddGameplayCueWithParams`
* `K2_AddGameplayCue`
* `K2_ActivateAbilityFromEvent`
* `K2_ActivateAbility`
* `IsLocallyControlled`
* `InvalidateClientPredictionKey`
* `GetSourceObject_BP`
* `GetOwningComponentFromActorInfo`
* `GetOwningActorFromActorInfo`
* `GetGrantedByEffectContext`
* `GetCurrentSourceObject`
* `GetCurrentMontage`
* `GetCooldownTimeRemaining`
* `GetContextFromOwner`
* `GetAvatarActorFromActorInfo`
* `GetActorInfo`
* `GetAbilitySystemComponentFromActorInfo`
* `GetAbilityLevel_BP`
* `GetAbilityLevel`
* `EndTaskByInstanceName`
* `EndAbilityState`
* `ConfirmTaskByInstanceName`
* `CancelTaskByInstanceName`
* `BP_RemoveGameplayEffectFromOwnerWithHandle`
* `BP_RemoveGameplayEffectFromOwnerWithGrantedTags`
* `BP_RemoveGameplayEffectFromOwnerWithAssetTags`
* `BP_ApplyGameplayEffectToTarget`
* `BP_ApplyGameplayEffectToOwner`

## Subclasses (4)

`AngelscriptGASAbility`, `GameplayAbilityBase`, `GameplayAbility_CharacterJump`, `GameplayAbility_Montage`
