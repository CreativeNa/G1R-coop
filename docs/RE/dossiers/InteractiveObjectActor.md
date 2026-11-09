# InteractiveObjectActor

`class` in `/Script/G1R`, 28 own properties, 17 own functions.

Inheritance: `Object` → `Actor` → `InteractiveObjectActor`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 704 | 16 | StructProperty | `m_PersistentId` | `StructProperty(Guid)` |
| 720 | 8 | ClassProperty | `m_ItemDefinition` | `ObjectProperty(Class)` |
| 728 | 1 | BoolProperty | `m_MustAlwaysTick` |  |
| 732 | 1 | BoolProperty | `bCreateDefaultAnchorComponent` |  |
| 732 | 1 | BoolProperty | `bCreateDefaultCameraComponent` |  |
| 732 | 1 | BoolProperty | `bCreateDefaultSkeletalMeshComponent` |  |
| 732 | 1 | BoolProperty | `bCreateDefaultStaticMeshComponent` |  |
| 732 | 1 | BoolProperty | `bCreateDefaultUINamePositionComponent` |  |
| 736 | 8 | ObjectProperty | `m_InteractiveObjectDefinition` | `ObjectProperty(InteractiveObjectDefinition)` |
| 744 | 8 | ObjectProperty | `m_SceneComponent` | `ObjectProperty(SceneComponent)` |
| 752 | 8 | ObjectProperty | `m_SkeletalMeshComponent` | `ObjectProperty(SkeletalMeshComponent)` |
| 760 | 8 | ObjectProperty | `m_MeshComponent` | `ObjectProperty(StaticMeshComponent)` |
| 768 | 8 | ObjectProperty | `m_InteractiveComponent` | `ObjectProperty(InteractiveComponent)` |
| 776 | 8 | ObjectProperty | `CameraComponent` | `ObjectProperty(CameraComponent)` |
| 784 | 8 | ObjectProperty | `m_BaseAnchorComponent` | `ObjectProperty(InteractiveObjectAnchorComponent)` |
| 792 | 8 | ObjectProperty | `m_DataModuleComponent` | `ObjectProperty(DataModuleComponent)` |
| 800 | 88 | StructProperty | `m_FreepointUsageRestriction` | `StructProperty(FreepointUsageRestriction_DEPRECATED)` |
| 888 | 1 | BoolProperty | `m_UseActionTagsForInteractObject` |  |
| 912 | 16 | StrProperty | `m_FreepointName` |  |
| 928 | 32 | StructProperty | `m_AdditionalPossibleActions` | `StructProperty(GameplayTagContainer)` |
| 960 | 1256 | StructProperty | `m_InteractionSpotRequirements` | `StructProperty(InteractionSpotRequirementsPack)` |
| 2216 | 1 | BoolProperty | `m_InheritOwnershipFromArea` |  |
| 2217 | 1 | BoolProperty | `m_OverrideOwnership` |  |
| 2224 | 56 | StructProperty | `m_Ownership` | `StructProperty(OwnershipSettings)` |
| 2280 | 1 | BoolProperty | `m_bHasMigratedDataFromFreepointConfig` |  |
| 2284 | 4 | IntProperty | `m_HasMigratedDataFromFreepointConfig2` |  |
| 2296 | 40 | StructProperty | `m_FreepointActionTags` | `StructProperty(FreepointActionTags_DEPRECATED)` |
| 2336 | 8 | ObjectProperty | `UINamePosition` | `ObjectProperty(SphereComponent)` |

## Functions

* `SetIsBeingUsed`
* `Server_PlayInteractMontage`
* `Multicast_StopInteractMontage`
* `Multicast_SetNextSectionOfInteractMontage`
* `Multicast_SetDataInt`
* `Multicast_ReplaceNextSectionOfInteractMontage`
* `Multicast_PlayInteractMontage`
* `Multicast_JumpSectionInteractMontage`
* `GetPersistentId`
* `GetInteractiveObjectDefinition`
* `GetInteractiveComponent`
* `GetFireComponent`
* `GetAnimInstance`
* `FindCharacter`
* `BP_PlayActionOnPicked`
* `BP_PlayActionConsume`
* `BP_PlayAction`

## Subclasses (39)

`AmbientWoodCuttingLogs_C`, `AnimatedInteractiveObjectActor`, `BarrierCinematic`, `BloodPuzzleFinal_AS`, `ClimbableWall`, `DoorLockWatcher_AS`, `HeartsStationActor`, `IBP_GrindingMachine_C`, `IBP_GrindingMill_Bucket_C`, `IBP_GrindingMill_C`, `IBP_GrindingOven_Belows_C`, `IBP_GrindingOven_C`, `IO_Prison_Door_C`, `InteractiveGasObjectActor`, `Interactive_Bed_C`, `Interactive_Bed_Guard_C`, `Interactive_Cauldron_C`, `Interactive_Chair_ArtisanWoodBench_C`, `Interactive_Chair_Stool2_C`, `Interactive_Chair_Stool_C`, `Interactive_Chair_WoodenBox_C`, `Interactive_Chest_C`, `Interactive_Lactern_C`, `Interactive_Lever_OrcLever_C`, `Interactive_LootBodyDigger_C`, `Interactive_MiningSpotVariableWall_C`, `Interactive_MiningSpotVariable_C`, `Interactive_Pan_C`, `Interactive_WhetStone_C`, `Interactive_WorkBench_C`, `ItemVisualWorld`, `KalomDeath_AS`, `LadderObject`, `OldMineExplosionCinematicActor`, `OrcSpores_AS`, `StatuesPreset`, `SunkenDoor_01_As`, `TrollCanyon_Door_C`, `YberionAshes_AS`
