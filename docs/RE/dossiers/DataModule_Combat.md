# DataModule_Combat

`class` in `/Script/G1R`, 13 own properties, 38 own functions.

Inheritance: `Object` → `DataModule` → `DataModule_Combat`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 40 | 1 | EnumProperty | `m_CurrentRangedState` |  |
| 128 | 1 | EnumProperty | `m_Stance` |  |
| 130 | 1 | EnumProperty | `m_DesiredStance` |  |
| 131 | 1 | EnumProperty | `m_AttackState` |  |
| 136 | 8 | StructProperty | `m_BlockState` | `StructProperty(GameplayTag)` |
| 192 | 8 | StructProperty | `m_CurrentAttackDirection` | `StructProperty(GameplayTag)` |
| 208 | 8 | StructProperty | `m_DefeatingAttackDirection` | `StructProperty(GameplayTag)` |
| 216 | 8 | StructProperty | `m_CurrentParryDirection` | `StructProperty(GameplayTag)` |
| 224 | 8 | StructProperty | `m_CurrentPose` | `StructProperty(GameplayTag)` |
| 232 | 8 | ObjectProperty | `m_LastAttackerCharacter` | `ObjectProperty(GothicCharacter)` |
| 240 | 8 | ObjectProperty | `m_CurrentCombo` | `ObjectProperty(ComboAttackConfig)` |
| 260 | 8 | StructProperty | `m_LastWeaponDamaged` | `StructProperty(GameplayTag)` |
| 369 | 1 | ByteProperty | `m_AttackCount` |  |

## Functions

* `SetLastAttackerCharacter`
* `Server_SetStance`
* `Server_SetDesiredStance`
* `Server_SetDefeatingAttackDirection`
* `Server_SetCurrentParryDirection`
* `Server_SetCurrentAttackDirection`
* `Server_SetBlockState`
* `Server_SetAttackState`
* `SeLastTauntTags`
* `ResetAttackCount`
* `OnRepStanceChanged`
* `OnRepBlockState`
* `OnRepAttackState`
* `OnRepAttackDirection`
* `IncreaseAttackCount`
* `GetStance`
* `GetNextAttacksRangeInPlace`
* `GetNextAttacksRange`
* `GetNextAttackConfig`
* `GetMagnetDamagePivotPoint`
* `GetLastTauntTags`
* `GetLastDamagePoint_World`
* `GetLastAttackerCharacter`
* `GetHigherAttackRange`
* `GetEquipedWeaponDefinition`
* `GetDefeatingAttackDirection`
* `GetCurrentParryDirection`
* `GetCurrentCombo`
* `GetCurrentAttackHandle`
* `GetCurrentAttackDirection`
* `GetCurrentAttack`
* `GetBlockState`
* `GetAttackTargetHurtComponent`
* `GetAttackTarget`
* `GetAttackRangeInPlace`
* `GetAttackRange`
* `GetAttackCount`
* `CheckIfNextAttackConfig`
