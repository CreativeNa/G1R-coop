# GothicTriggerVolume

`class` in `/Script/G1R`, 7 own properties, 12 own functions.

Inheritance: `Object` → `Actor` → `Brush` → `Volume` → `TriggerVolume` → `GothicTriggerVolume`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 712 | 8 | NameProperty | `m_EventName` |  |
| 720 | 8 | ClassProperty | `m_VolumeDefinition` | `ObjectProperty(Class)` |
| 728 | 8 | ObjectProperty | `m_Subsystem` | `ObjectProperty(MusicManager)` |
| 737 | 1 | BoolProperty | `m_MustTick` |  |
| 738 | 1 | BoolProperty | `m_IsInside` |  |
| 744 | 8 | ObjectProperty | `m_Player` | `ObjectProperty(GothicCharacter)` |
| 752 | 16 | ArrayProperty | `m_Characters` | `ArrayProperty(ByteProperty)` |

## Functions

* `Tick`
* `Server_DamageAndEvent`
* `SaveData`
* `OnOverlapEnd`
* `OnOverlapBegin`
* `Multicast_DamageAndEvent`
* `IsDoorOpen`
* `GetDataGlobalData`
* `GetData`
* `DamageAndEvent`
* `BP_IsPlayer`
* `BP_HasCharacter`
