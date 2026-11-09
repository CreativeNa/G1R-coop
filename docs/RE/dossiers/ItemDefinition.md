# ItemDefinition

`class` in `/Script/G1R`, 30 own properties, 32 own functions.

Inheritance: `Object` → `GothicBaseConfig` → `GothicObjectDefinition` → `ItemDefinition`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 128 | 4 | IntProperty | `m_Value` |  |
| 132 | 4 | IntProperty | `m_MaxStack` |  |
| 136 | 4 | FloatProperty | `m_Buoyancy` |  |
| 140 | 4 | FloatProperty | `m_Weight` |  |
| 144 | 4 | FloatProperty | `m_Mass` |  |
| 152 | 40 | SoftClassProperty | `m_ItemVisual` | `ObjectProperty(Class)` |
| 192 | 40 | SoftClassProperty | `m_ItemVisualWorld` | `ObjectProperty(Class)` |
| 232 | 40 | SoftClassProperty | `m_ItemVisualWorldDrop` | `ObjectProperty(Class)` |
| 272 | 40 | SoftClassProperty | `m_ItemGeneric` | `ObjectProperty(Class)` |
| 312 | 40 | SoftClassProperty | `m_ItemEmptyVisual` | `ObjectProperty(Class)` |
| 464 | 32 | StructProperty | `m_EquipBlockingTags` | `StructProperty(GameplayTagContainer)` |
| 496 | 8 | ClassProperty | `m_OnEquipEffect` | `ObjectProperty(Class)` |
| 504 | 16 | ArrayProperty | `m_LearnRecipes` | `ArrayProperty(StructProperty(GameplayTagContainer))` |
| 520 | 32 | StructProperty | `m_RequiredTagsToLearn` | `StructProperty(GameplayTagContainer)` |
| 552 | 16 | ArrayProperty | `m_OnConsumeEffects` | `ArrayProperty(ObjectProperty(Class))` |
| 568 | 8 | ClassProperty | `m_ForcedInteraction` | `ObjectProperty(Class)` |
| 576 | 80 | MapProperty | `m_RequiredStats` | `MapProperty(EnumProperty,ArrayProperty(ArrayProperty(EnumProperty)))` |
| 656 | 1 | EnumProperty | `m_TryToStoreFirst` |  |
| 664 | 16 | ArrayProperty | `m_ActionsKeywords` | `ArrayProperty(ArrayProperty(EnumProperty))` |
| 680 | 16 | ArrayProperty | `m_ItemStatsTags` | `ArrayProperty(EnumProperty)` |
| 696 | 1 | EnumProperty | `m_HoldsterLocation` |  |
| 700 | 8 | StructProperty | `m_ParticlesWhenPickUp` | `StructProperty(GameplayTag)` |
| 708 | 8 | StructProperty | `m_EventWhenPickUp` | `StructProperty(GameplayTag)` |
| 720 | 8 | ClassProperty | `m_RequiredToPick` | `ObjectProperty(Class)` |
| 728 | 56 | StructProperty | `m_Ownership` | `StructProperty(OwnershipSettings)` |
| 784 | 8 | ClassProperty | `m_ReplaceBy` | `ObjectProperty(Class)` |
| 792 | 8 | ClassProperty | `m_ComparedTo` | `ObjectProperty(Class)` |
| 800 | 1 | BoolProperty | `m_CanBeSpawned` |  |
| 801 | 1 | BoolProperty | `m_AutoTarget` |  |
| 808 | 8 | ClassProperty | `m_TargetConfigClass` | `ObjectProperty(Class)` |

## Functions

* `SetItemType`
* `SetItemCustomAction`
* `RemoveItemSpec`
* `MatchesItemTypeExactly`
* `MatchesItemType`
* `LoadAndGetVisualWorldClass`
* `LoadAndGetVisualClass`
* `LoadAndGetVisual`
* `LoadAndGetThrowVisualWorldClass`
* `LoadAndGetEmptyVisualClass`
* `LoadAndGetEmptyVisual`
* `HasItemSpecExactly`
* `HasItemSpec`
* `HasAnyItemSpecsExactly`
* `HasAnyItemSpecs`
* `HasAllItemSpecsExactly`
* `HasAllItemSpecs`
* `GetTargetConfigClass`
* `GetItemTypeDisplayText`
* `GetItemType`
* `GetItemSpec`
* `GetAttributeListFromGEList`
* `GetAttribute`
* `GetAllMatchingSpecs`
* `CanBeEquippedBy`
* `ApplyTo`
* `AddPossibleActionAfterDrop`
* `AddOnConsume`
* `AddLearningRecipes`
* `AddItemSpec`
* `AddItemReqTag`
* `AddCollisionEffect`

## Subclasses (337)

`Apple_Test`, `ArmorDefinition`, `ArmorUpgradeDefinition`, `BaitDefinition`, `FireRainItemDefinition`, `FishingRodDefinition`, `FoodDefinition`, `IceWaterSurfaceItemDefinition`, `IntermediateObjectDefinition`, `ItAI_Box`, `ItAI_BrushWood`, `ItAI_Foodbag`, `ItAI_Orebag`, `ItAI_Plank`, `ItAt_Amulet_Brotherhood`, `ItAt_Amulet_Dexterity_01`, `ItAt_Amulet_Dexterity_02`, `ItAt_Amulet_Enlight`, `ItAt_Amulet_Fire`, `ItAt_Amulet_Innos`, `ItAt_Amulet_Life`, `ItAt_Amulet_Magic_01`, `ItAt_Amulet_Magic_02`, `ItAt_Amulet_Magicfire`, `ItAt_Amulet_Neks`, `ItAt_Amulet_Orc`, `ItAt_Amulet_OrcMummy`, `ItAt_Amulet_Power`, `ItAt_Amulet_Projectile`, `ItAt_Amulet_Protection`, `ItAt_Amulet_Ranged`, `ItAt_Amulet_Strong_01`, `ItAt_Amulet_Strong_02`, `ItAt_Amulet_Ulu_Talisman`, `ItAt_Amulet_Water`, `ItAt_Amulet_Weapon`, `ItAt_Biter_01`, `ItAt_Biter_02`, `ItAt_Biter_03`, `ItAt_Bloodfly_01`, `ItAt_Bloodfly_02`, `ItAt_Bloodfly_03`, `ItAt_Bloodhound_01`, `ItAt_Bloodhound_02`, `ItAt_Crawler_01`, `ItAt_Crawler_02`, `ItAt_Crawlerqueen`, `ItAt_Damlurker_01`, `ItAt_Firegolem_01`, `ItAt_Firegolem_02`, `ItAt_Firelizard_01`, `ItAt_Firelizard_02`, `ItAt_Firelizard_03`, `ItAt_Firelizard_04`, `ItAt_Firelizard_05`, `ItAt_Harpy_01`, `ItAt_Harpy_02`, `ItAt_Icegolem_01`, `ItAt_Icegolem_02`, `ItAt_Lizard_01`

… and 277 more
