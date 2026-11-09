# DataModule_Targeting

`class` in `/Script/G1R`, 5 own properties, 5 own functions.

Inheritance: `Object` → `DataModule` → `DataModule_Targeting`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 40 | 8 | WeakObjectProperty | `m_Target` | `ObjectProperty(Actor)` |
| 48 | 1 | BoolProperty | `m_IsCameraRelevant` |  |
| 52 | 8 | WeakObjectProperty | `m_TargetComp` | `ObjectProperty(SceneComponent)` |
| 64 | 16 | ArrayProperty | `m_TargetedBy` | `ArrayProperty(ObjectProperty(Class))` |
| 80 | 8 | ClassProperty | `m_TargetConfigClass` | `ObjectProperty(Class)` |

## Functions

* `OnRep_TargetComp`
* `GetTargetedByCount`
* `GetTargetedBy`
* `GetTargetComp`
* `GetTarget`
