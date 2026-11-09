# GameplayAbilityCastSpell

`class` in `/Script/G1R`, 7 own properties, 36 own functions.

Inheritance: `Object` → `GameplayAbility` → `GameplayAbilityBase` → `ScriptGameplayAbility` → `GameplayAbilityMagicBase` → `GameplayAbilityCastSpell`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 1552 | 1 | BoolProperty | `m_HasCreatedSpellAbilityServer` |  |
| 1556 | 8 | NameProperty | `m_PreviousMontageName` |  |
| 1568 | 8 | ObjectProperty | `m_AbilitySystemComponent` | `ObjectProperty(GothicAbilitySystemComponent)` |
| 1576 | 8 | StructProperty | `m_TriggerBeginOnSpellTag` | `StructProperty(GameplayTag)` |
| 1584 | 8 | ClassProperty | `m_SpellConfigurationContainerClass` | `ObjectProperty(Class)` |
| 1592 | 8 | ObjectProperty | `m_SpellConfigurationContainer` | `ObjectProperty(SpellConfigurationContainer)` |
| 1600 | 8 | ClassProperty | `m_ExecutionValidator` | `ObjectProperty(Class)` |

## Functions

* `ServerClearMontageTaskDelegates`
* `PlayNextCastLevel_Scriptable`
* `PlayLaunchSpell_Scriptable`
* `OnUpdateAbility_Scriptable`
* `OnPlayFailCastMontage_Scriptable`
* `OnPlayCancelCastMontage_Scriptable`
* `OnManaConsumedOnServer`
* `OnInputReleased_Scriptable`
* `OnFailCastSpellMontageInterrupted`
* `OnFailCastSpellMontageCompleted`
* `OnFailCastSpellMontageCancelled`
* `OnEndCastSpellServer_Scriptable`
* `OnDisableCancel`
* `OnCastSpellMontageInterrupted`
* `OnCastSpellMontageCompleted`
* `OnCastSpellMontageCancelled`
* `OnCastEndSpellMontageInterrupted`
* `OnCastEndSpellMontageCancelled`
* `OnCanActivateAbilityServer_Scriptable`
* `OnActivateCastSpellServer_Scriptable`
* `NeedItemInHand_Scriptable`
* `LaunchSpellAbilityServer_Scriptable`
* `IsCastingToCancelPreviousSpell_Scriptable`
* `HasCreatedSpellAbilityServer`
* `GetCastSectionDuration`
* `GetCastDuration_Scriptable`
* `FinishCastAfterLaunchSpell`
* `ExecuteValidator`
* `DoActivateAbility`
* `ConsumeManaServer`
* `ClientSpellLaunched`
* `ClientPlayLaunch`
* `ClientPlayFailCastMontage`
* `ClientPlayCancelCastMontage`
* `ClientClearMontageTaskDelegates`
* `CanLaunchSpellAbilityServer_Scriptable`

## Subclasses (3)

`GA_CastSpell_Default`, `GameplayAbilityCastRechargeableSpell`, `GameplayAbilityCastTransform`
