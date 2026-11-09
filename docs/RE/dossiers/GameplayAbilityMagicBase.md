# GameplayAbilityMagicBase

`class` in `/Script/G1R`, 11 own properties, 72 own functions.

Inheritance: `Object` → `GameplayAbility` → `GameplayAbilityBase` → `ScriptGameplayAbility` → `GameplayAbilityMagicBase`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 1328 | 88 | StructProperty | `m_SpellContext` | `StructProperty(SpellContext)` |
| 1436 | 1 | BoolProperty | `m_AbilityHasBlockMovement` |  |
| 1440 | 8 | WeakObjectProperty | `m_DataModule_Locomotion` | `ObjectProperty(DataModule_Locomotion)` |
| 1448 | 8 | WeakObjectProperty | `m_DataModule_Animation` | `ObjectProperty(DataModule_Animation)` |
| 1456 | 16 | ArrayProperty | `m_Targets` | `ArrayProperty(ObjectProperty(GothicMovementComponent))` |
| 1472 | 8 | WeakObjectProperty | `m_MoveComp` | `ObjectProperty(GothicMovementComponent)` |
| 1496 | 8 | WeakObjectProperty | `m_MagicComponent` | `ObjectProperty(GothicMagicComponent)` |
| 1504 | 4 | FloatProperty | `m_IgnoreReleaseInput` |  |
| 1512 | 8 | ClassProperty | `m_GE_Mana` | `ObjectProperty(Class)` |
| 1528 | 4 | FloatProperty | `m_EndAbilityTimeoutDelay` |  |
| 1544 | 8 | StructProperty | `m_ActivateSpellCameraAbilityTag` | `StructProperty(GameplayTag)` |

## Functions

* `WasTargetObtainedByTargetDatamodule`
* `ShouldForceIgnoreInput_Scriptable`
* `ReleaseTarget`
* `RedirectToTarget_Internal`
* `RedirectToTarget`
* `QuickApplyGEToTarget_Scriptable`
* `QuickApplyGEToTarget`
* `PlayLaunchSpellMontage`
* `PlayCastMontage`
* `PlayCancelCastMontage`
* `OnTargetValidated_Scriptable`
* `OnShouldFinishSpellAfterActivation_Scriptable`
* `OnOutMana_Scriptable`
* `OnActivateAbilityBeforeAssetPreload_Scriptable`
* `NeedUseMana`
* `IsTargetValid_Script`
* `IsTargetValid`
* `IsSpellTargetTypeFocused`
* `IsSpellTargetTypeDynamic`
* `IsSpellManaUsageTargetLevel`
* `IsSpellManaUsageRechargeable`
* `IsSpellManaUsageNormalContinuous`
* `IsSpellManaUsageContinuous`
* `IsSpellAbilityActive`
* `IsOwnerActorAuthoritative`
* `IsOverridingGetStateLockMovementOnSpell_Scriptable`
* `IsOverridingGetStateLockMovementOnCast_Scriptable`
* `IsLastSpellLevel`
* `IsInputPressed`
* `IsFinishCastAbilityByAnimNotifyOnLaunchSpell`
* `IsCastAbilityActive`
* `IncrementCurrentSpellLevel`
* `HasOverrideManaCostValue_Scriptable`
* `HasMoreLaunches`
* `HasInfiniteLaunches`
* `HasEndLaunchAnimation`
* `GetTraceRangeFromConfig_Scriptable`
* `GetTraceRadiusFromConfig_Scriptable`
* `GetTargetOrOwner`
* `GetTargetEventData_Scriptable`
* `GetTarget`
* `GetSpellManaCostPerSecond`
* `GetSpellLevels`
* `GetSpellContextRef`
* `GetSpellConfigurationContainer`
* `GetSpellAreaRange`
* `GetSpellAreaAngle`
* `GetOverrideManaCostValue_Scriptable`
* `GetOverrideGetStateLockMovementOnSpell_Scriptable`
* `GetOverrideGetStateLockMovementOnCast_Scriptable`
* `GetLevelSpawnActorClassServer`
* `GetLevelCastingTime`
* `GetFocusedTarget_Scriptable`
* `GetFilterClassFromConfig_Scriptable`
* `GetCustomTarget_Scriptable`
* `GetCurrentSpellLevel`
* `GetCurrentMontageRemainingTime_Scriptable`
* `GetConsumeManaGE_Scriptable`
* `GetCastManaCost`
* `GetCancelSpellAfterFirstCharge`
* `FindTargetsInArea_Server`
* `DecrementCurrentSpellLevel`
* `DeactivateTarget_Internal`
* `DeactivateTarget`
* `ClientRedirectToTarget`
* `ClientOutOfMana`
* `ClientDeactivateTarget`
* `ClientActivateTarget`
* `CheckNumLaunches`
* `ApplyManaEffect`
* `ActivateTarget_Interal`
* `ActivateTarget`

## Subclasses (3)

`GameplayAbilityCastSpell`, `GameplayAbilitySpellBasic`, `GameplayAbilityUnTransform`
