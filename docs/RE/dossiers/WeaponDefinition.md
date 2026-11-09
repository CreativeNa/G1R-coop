# WeaponDefinition

`class` in `/Script/G1R`, 7 own properties, 10 own functions.

Inheritance: `Object` → `GothicBaseConfig` → `GothicObjectDefinition` → `ItemDefinition` → `WeaponDefinition`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 816 | 80 | MapProperty | `m_DamageBase` | `MapProperty(FloatProperty,StructProperty(GameplayTag))` |
| 896 | 4 | FloatProperty | `m_SuperArmorDamageBase` |  |
| 904 | 8 | ClassProperty | `m_HitEffect` | `ObjectProperty(Class)` |
| 912 | 32 | StructProperty | `m_CriticalWeakSpotsTags` | `StructProperty(GameplayTagContainer)` |
| 944 | 4 | FloatProperty | `m_CriticalMultiplier` |  |
| 952 | 8 | ClassProperty | `m_DeathEffect` | `ObjectProperty(Class)` |
| 960 | 80 | MapProperty | `m_HitCueDataByDamageType` | `MapProperty(IntProperty,StructProperty(GameplayTag))` |

## Functions

* `GetSuperArmorDamage`
* `GetHitEffect`
* `GetHitCueDataByDamageTypeAndSpecie`
* `GetDeathEffect`
* `GetDamageTypes`
* `GetDamage`
* `GetCriticalWeakSpotsTags`
* `GetCriticalMultiplier`
* `GetAllDamages`
* `AddHitCueDataForSpecie`

## Subclasses (13)

`CampFireDefinition`, `Environment_LavaDefinitionBase`, `LavaStream_FireGolem`, `PlayerArenaDetector_FireGolem`, `ProjectileDefinition`, `SleeperTempleFireDefinition`, `SpikeAreaDefinition`, `StompWeaponDefinition`, `WeaponArcheryDefinition`, `WeaponDefinitionFocusStonePuzzle`, `WeaponMeleeDefinition`, `WeaponRangedDefinition`, `WorldImpactWeapon`
