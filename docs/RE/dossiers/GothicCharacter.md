# GothicCharacter

`class` in `/Script/G1R`, 38 own properties, 91 own functions.

Inheritance: `Object` → `Actor` → `Pawn` → `Character` → `ClientAuthoritativeCharacter` → `GothicCharacter`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 1736 | 16 | MulticastInlineDelegateProperty | `OnStanceChangedDelegate` |  |
| 1792 | 16 | MulticastInlineDelegateProperty | `OnGameplayIsReadyDynamicDelegate` |  |
| 1856 | 80 | StructProperty | `m_BonesSettings` | `StructProperty(BonesSettings)` |
| 1936 | 8 | ObjectProperty | `CurrentDebugWidgetComp` | `ObjectProperty(WidgetComponent)` |
| 1944 | 8 | ObjectProperty | `m_HealthBarComponent` | `ObjectProperty(NPCHealthBarComponent)` |
| 1952 | 8 | ObjectProperty | `m_HUDDisplayCombatMarkerPositionComponent` | `ObjectProperty(HUDDisplayCombatMarkerPositionComponent)` |
| 1960 | 8 | ObjectProperty | `m_RagdollComponent` | `ObjectProperty(RagdollComponent)` |
| 1968 | 8 | ObjectProperty | `m_CarryComponent` | `ObjectProperty(CarryComponent)` |
| 1976 | 8 | ObjectProperty | `m_MagicComponent` | `ObjectProperty(GothicMagicComponent)` |
| 1984 | 8 | ObjectProperty | `m_TimeDilationComponent` | `ObjectProperty(GothicTimeDilationComponent)` |
| 1992 | 8 | ObjectProperty | `m_GothicWaterVolumeSensor` | `ObjectProperty(GothicWaterVolumeSensor)` |
| 2000 | 8 | ObjectProperty | `m_WalkSpeedModifierComponent` | `ObjectProperty(WalkSpeedModifierComponent)` |
| 2008 | 8 | ObjectProperty | `m_PerceptionComponent` | `ObjectProperty(CharacterPerceptionComponent)` |
| 2016 | 8 | ObjectProperty | `m_SubCapsuleManagerComponent` | `ObjectProperty(SubCapsuleManagerComponent)` |
| 2024 | 8 | ObjectProperty | `m_FXComponent` | `ObjectProperty(GothicFXComponent)` |
| 2032 | 8 | ObjectProperty | `m_CharacterVisualsComponent` | `ObjectProperty(CharacterVisualsComponent)` |
| 2040 | 8 | ObjectProperty | `m_CharacterTrinketsComponent` | `ObjectProperty(CharacterTrinketsComponent)` |
| 2048 | 8 | ObjectProperty | `m_QuiverComponent` | `ObjectProperty(QuiverComponent)` |
| 2056 | 8 | ObjectProperty | `m_BloodComponent` | `ObjectProperty(GothicBloodComponent)` |
| 2064 | 8 | ObjectProperty | `m_MaterialsComponent` | `ObjectProperty(GothicMaterialsComponent)` |
| 2072 | 8 | ObjectProperty | `m_FocalPointComponent` | `ObjectProperty(FocalPointComponent)` |
| 2080 | 8 | ObjectProperty | `m_WeatherComponent` | `ObjectProperty(GothicWeatherComponent)` |
| 2088 | 8 | ObjectProperty | `m_DirtComponent` | `ObjectProperty(GothicDirtComponent)` |
| 2096 | 8 | ObjectProperty | `m_FootstepsDataComponent` | `ObjectProperty(GothicFootstepsDataComponent)` |
| 2104 | 8 | ObjectProperty | `m_DataModule_Locomotion` | `ObjectProperty(DataModule_Locomotion)` |
| 2112 | 8 | ObjectProperty | `m_DataModule_BaseStats` | `ObjectProperty(DataModule_BaseStats)` |
| 2120 | 8 | ObjectProperty | `m_DataModule_Targeting` | `ObjectProperty(DataModule_Targeting)` |
| 2128 | 8 | ObjectProperty | `m_MutilatedSkeletalMeshActor` | `ObjectProperty(GothicMutilatedSkeletalMeshActor)` |
| 2136 | 8 | ObjectProperty | `m_AnimComponent` | `ObjectProperty(GothicAnimationComponent)` |
| 2216 | 8 | ObjectProperty | `m_GothicCinematicActorComponent` | `ObjectProperty(GothicCinematicActorComponent)` |
| 2224 | 8 | ObjectProperty | `m_SyncCharacterComponent` | `ObjectProperty(MPSyncCharacterComponent)` |
| 2328 | 16 | ArrayProperty | `m_CollisionComponents` | `ArrayProperty(ObjectProperty(GothicCharacterState))` |
| 2360 | 8 | ObjectProperty | `m_CharacterState` | `ObjectProperty(GothicCharacterState)` |
| 2440 | 8 | ObjectProperty | `m_CameraBoom` | `ObjectProperty(GothicCameraSpringArmComponent)` |
| 2448 | 8 | ObjectProperty | `m_FollowCamera` | `ObjectProperty(CameraComponent)` |
| 2456 | 8 | NameProperty | `m_EyesLocationSocketName` |  |
| 2464 | 8 | NameProperty | `m_HeadBone` |  |
| 2488 | 8 | ObjectProperty | `m_InteractiveComponent` | `ObjectProperty(InteractiveComponent)` |

## Functions

* `StopAutoHideHealthBar`
* `ShowCharacter`
* `ShouldBlockInvisibleWall`
* `SetVisibilityCharacterAndEverythingItCarries`
* `SetDelayedCustomTimerDilatation`
* `SetCustomTimeDilation`
* `SetCustomAnimGlobalRateScale`
* `SetAsHiddenSpectatorCharacter`
* `ServerNotifyInventoryQuickItemsMayHaveBeenModified`
* `ServerDoPossess`
* `Server_StopMontage`
* `Server_SetAnimRootMotionTranslationScale`
* `Server_PlayMontage`
* `Server_PlayDynamicMontage`
* `Server_JumpToSectionMontage`
* `Server_InitializeSkills`
* `Server_InitializeSavedData`
* `Server_InitializeAbilities`
* `Server_ApplyTagsAndEffectsSavedData`
* `SendGlobalEvent`
* `ResetTimeDilatation`
* `RecreatePhysicsAndClothState`
* `OnResetStates`
* `OnOverlapBeginServer`
* `OnComponentCollisionSettingsChanged`
* `MulticastPlayUnTransformMontage`
* `MulticastNotifyInventoryQuickItemsMayHaveBeenModified`
* `Multicast_StopMontage`
* `Multicast_SetEnableCollisions`
* `Multicast_SetCustomTimerDilatation`
* `Multicast_SendGlobalEvent`
* `Multicast_PlayMontage`
* `Multicast_PlayDynamicMontage`
* `Multicast_JumpToSectionMontage`
* `MakeRideable`
* `IsPlayerCharacterOrPlayerControlled`
* `IsPlayerCharacter`
* `IsOnNavMesh`
* `IsNPCCharacter`
* `IsDefeated`
* `IsDead`
* `HasGameplayTag`
* `HasAnyGameplayTags`
* `HasAllGameplayTags`
* `HasAbility`
* `GetWeatherComponent`
* `GetWalkSpeedModifierComponent`
* `GetVisualDebuffConfig`
* `GetSubCapsuleManagerComponent`
* `GetRiderComponent`
* `GetRelationship`
* `GetQuiverComponent`
* `GetPerception`
* `GetNavAgentPropertiesRef`
* `GetMountComponent`
* `GetMagicComponent`
* `GetMagicCircleIndexFrom`
* `GetInventory`
* `GetHealthBarComponent`
* `GetGothicMovementComponent`
* `GetGothicMaterialsComponent`
* `GetGothicBloodComponent`
* `GetFXComponent`
* `GetFocalPointComponent`
* `GetFeetLocation`
* `GetEyesToCenterOffsetXY`
* `GetEyesSocketName`
* `GetEyesLocation`
* `GetEyesHeightFromFeet`
* `GetEyesHeight`
* `GetDistanceToHitCollision`
* `GetDataModule_Targeting`
* `GetCollisionComponents`
* `GetCharacterVisualsComponent`
* `GetCharacterUniqueName`
* `GetCharacterMagicCircleTag`
* `GetCharacterMagicCircleLevelFromAttr`
* `GetCharacterGlobalId`
* `GetCharacterDisplayName`
* `GetCharacterDefinition`
* `GetCarryComponent`
* `GetAnimationComponent`
* `GetAbilitySystemComponent`
* `ClientTeleportTo`
* `ClientSetSpellToCamera`
* `Client_AttachToComponent`
* `CanCastSpell`
* `BP_OnOverlapWater`
* `BP_IsGameplayReady`
* `BP_GetCharacterState`
* `ActiveFreezeFrame`

## Subclasses (3)

`AIAgentCharacter`, `CharacterCanTransformInto`, `GothicPlayerCharacter`
