# Actor

`class` in `/Script/Engine`, 81 own properties, 140 own functions.

Inheritance: `Object` → `Actor`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 40 | 48 | StructProperty | `PrimaryActorTick` | `StructProperty(ActorTickFunction)` |
| 88 | 1 | BoolProperty | `bAlwaysRelevant` |  |
| 88 | 1 | BoolProperty | `bCallPreReplication` |  |
| 88 | 1 | BoolProperty | `bCallPreReplicationForReplay` |  |
| 88 | 1 | BoolProperty | `bHidden` |  |
| 88 | 1 | BoolProperty | `bNetTemporary` |  |
| 88 | 1 | BoolProperty | `bOnlyRelevantToOwner` |  |
| 88 | 1 | BoolProperty | `bReplicateMovement` |  |
| 89 | 1 | BoolProperty | `bExchangedRoles` |  |
| 89 | 1 | BoolProperty | `bForceNetAddressable` |  |
| 89 | 1 | BoolProperty | `bNetLoadOnClient` |  |
| 89 | 1 | BoolProperty | `bNetUseOwnerRelevancy` |  |
| 89 | 1 | BoolProperty | `bRelevantForLevelBounds` |  |
| 89 | 1 | BoolProperty | `bRelevantForNetworkReplays` |  |
| 89 | 1 | BoolProperty | `bReplayRewindable` |  |
| 89 | 1 | BoolProperty | `bTearOff` |  |
| 90 | 1 | BoolProperty | `bAllowTickBeforeBeginPlay` |  |
| 90 | 1 | BoolProperty | `bAutoDestroyWhenFinished` |  |
| 90 | 1 | BoolProperty | `bBlockInput` |  |
| 90 | 1 | BoolProperty | `bCanBeDamaged` |  |
| 90 | 1 | BoolProperty | `bCollideWhenPlacing` |  |
| 90 | 1 | BoolProperty | `bFindCameraComponentWhenViewTarget` |  |
| 90 | 1 | BoolProperty | `bGenerateOverlapEventsDuringLevelStreaming` |  |
| 90 | 1 | BoolProperty | `bNeverApplyTickOptimizations` |  |
| 91 | 1 | BoolProperty | `bActorSeamlessTraveled` |  |
| 91 | 1 | BoolProperty | `bAllowReceiveTickEventOnDedicatedServer` |  |
| 91 | 1 | BoolProperty | `bCanBeInCluster` |  |
| 91 | 1 | BoolProperty | `bEnableAutoLODGeneration` |  |
| 91 | 1 | BoolProperty | `bIgnoresOriginShifting` |  |
| 91 | 1 | BoolProperty | `bIsEditorOnlyActor` |  |
| 91 | 1 | BoolProperty | `bReplicates` |  |
| 92 | 1 | BoolProperty | `bReplicateUsingRegisteredSubObjectList` |  |
| 93 | 1 | BoolProperty | `bActorEnableCollision` |  |
| 93 | 1 | BoolProperty | `bActorIsBeingDestroyed` |  |
| 93 | 1 | BoolProperty | `bAsyncPhysicsTickEnabled` |  |
| 94 | 1 | EnumProperty | `UpdateOverlapsMethodDuringLevelStreaming` |  |
| 95 | 1 | EnumProperty | `DefaultUpdateOverlapsMethodDuringLevelStreaming` |  |
| 96 | 1 | ByteProperty | `RemoteRole` |  |
| 100 | 4 | FloatProperty | `InitialLifeSpan` |  |
| 104 | 4 | FloatProperty | `CustomTimeDilation` |  |
| 108 | 4 | IntProperty | `RayTracingGroupId` |  |
| 112 | 96 | StructProperty | `AttachmentReplication` | `StructProperty(RepAttachment)` |
| 208 | 112 | StructProperty | `ReplicatedMovement` | `StructProperty(RepMovement)` |
| 320 | 8 | ObjectProperty | `Owner` | `ObjectProperty(Actor)` |
| 328 | 8 | NameProperty | `NetDriverName` |  |
| 336 | 1 | ByteProperty | `Role` |  |
| 337 | 1 | ByteProperty | `NetDormancy` |  |
| 338 | 1 | EnumProperty | `SpawnCollisionHandlingMethod` |  |
| 339 | 1 | ByteProperty | `AutoReceiveInput` |  |
| 340 | 4 | IntProperty | `InputPriority` |  |
| 352 | 8 | ObjectProperty | `InputComponent` | `ObjectProperty(InputComponent)` |
| 360 | 4 | FloatProperty | `NetCullDistanceSquared` |  |
| 364 | 4 | IntProperty | `NetTag` |  |
| 368 | 4 | FloatProperty | `NetUpdateFrequency` |  |
| 372 | 4 | FloatProperty | `MinNetUpdateFrequency` |  |
| 376 | 4 | FloatProperty | `NetPriority` |  |
| 380 | 1 | EnumProperty | `PhysicsReplicationMode` |  |
| 392 | 8 | ObjectProperty | `Instigator` | `ObjectProperty(Pawn)` |
| 400 | 16 | ArrayProperty | `Children` | `ArrayProperty(ObjectProperty(SceneComponent))` |
| 416 | 8 | ObjectProperty | `RootComponent` | `ObjectProperty(SceneComponent)` |
| 432 | 16 | ArrayProperty | `Layers` | `ArrayProperty(ObjectProperty(ChildActorComponent))` |
| 448 | 8 | WeakObjectProperty | `ParentComponent` | `ObjectProperty(ChildActorComponent)` |
| 456 | 16 | ArrayProperty | `Tags` | `ArrayProperty(MulticastSparseDelegateProperty)` |
| 472 | 1 | MulticastSparseDelegateProperty | `OnTakeAnyDamage` |  |
| 473 | 1 | MulticastSparseDelegateProperty | `OnTakePointDamage` |  |
| 474 | 1 | MulticastSparseDelegateProperty | `OnTakeRadialDamage` |  |
| 475 | 1 | MulticastSparseDelegateProperty | `OnActorBeginOverlap` |  |
| 476 | 1 | MulticastSparseDelegateProperty | `OnActorEndOverlap` |  |
| 477 | 1 | MulticastSparseDelegateProperty | `OnBeginCursorOver` |  |
| 478 | 1 | MulticastSparseDelegateProperty | `OnEndCursorOver` |  |
| 479 | 1 | MulticastSparseDelegateProperty | `OnClicked` |  |
| 480 | 1 | MulticastSparseDelegateProperty | `OnReleased` |  |
| 481 | 1 | MulticastSparseDelegateProperty | `OnInputTouchBegin` |  |
| 482 | 1 | MulticastSparseDelegateProperty | `OnInputTouchEnd` |  |
| 483 | 1 | MulticastSparseDelegateProperty | `OnInputTouchEnter` |  |
| 484 | 1 | MulticastSparseDelegateProperty | `OnInputTouchLeave` |  |
| 485 | 1 | MulticastSparseDelegateProperty | `OnActorHit` |  |
| 486 | 1 | MulticastSparseDelegateProperty | `OnDestroyed` |  |
| 487 | 1 | MulticastSparseDelegateProperty | `OnEndPlay` |  |
| 616 | 16 | ArrayProperty | `InstanceComponents` | `ArrayProperty(ArrayProperty(ObjectProperty(ActorComponent)))` |
| 632 | 16 | ArrayProperty | `BlueprintCreatedComponents` | `ArrayProperty(ObjectProperty(ActorComponent))` |

## Functions

* `WasRecentlyRendered`
* `UserConstructionScript`
* `TearOff`
* `SetTickGroup`
* `SetTickableWhenPaused`
* `SetReplicates`
* `SetReplicateMovement`
* `SetRayTracingGroupId`
* `SetPhysicsReplicationMode`
* `SetOwner`
* `SetNetDormancy`
* `SetLifeSpan`
* `SetAutoDestroyWhenFinished`
* `SetActorTickInterval`
* `SetActorTickEnabled`
* `SetActorScale3D`
* `SetActorRelativeScale3D`
* `SetActorHiddenInGame`
* `SetActorEnableCollision`
* `RemoveTickPrerequisiteComponent`
* `RemoveTickPrerequisiteActor`
* `ReceiveTick`
* `ReceiveRadialDamage`
* `ReceivePointDamage`
* `ReceiveHit`
* `ReceiveEndPlay`
* `ReceiveDestroyed`
* `ReceiveBeginPlay`
* `ReceiveAsyncPhysicsTick`
* `ReceiveAnyDamage`
* `ReceiveActorOnReleased`
* `ReceiveActorOnInputTouchLeave`
* `ReceiveActorOnInputTouchEnter`
* `ReceiveActorOnInputTouchEnd`
* `ReceiveActorOnInputTouchBegin`
* `ReceiveActorOnClicked`
* `ReceiveActorEndOverlap`
* `ReceiveActorEndCursorOver`
* `ReceiveActorBeginOverlap`
* `ReceiveActorBeginCursorOver`
* `PrestreamTextures`
* `OnRep_ReplicateMovement`
* `OnRep_ReplicatedMovement`
* `OnRep_Owner`
* `OnRep_Instigator`
* `OnRep_AttachmentReplication`
* `MakeNoise`
* `K2_TeleportTo`
* `K2_SetActorTransform`
* `K2_SetActorRotation`
* `K2_SetActorRelativeTransform`
* `K2_SetActorRelativeRotation`
* `K2_SetActorRelativeLocation`
* `K2_SetActorLocationAndRotation`
* `K2_SetActorLocation`
* `K2_OnReset`
* `K2_OnEndViewTarget`
* `K2_OnBecomeViewTarget`
* `K2_GetRootComponent`
* `K2_GetComponentsByClass`
* `K2_GetActorRotation`
* `K2_GetActorLocation`
* `K2_DetachFromActor`
* `K2_DestroyActor`
* `K2_AttachToComponent`
* `K2_AttachToActor`
* `K2_AttachRootComponentToActor`
* `K2_AttachRootComponentTo`
* `K2_AddActorWorldTransformKeepScale`
* `K2_AddActorWorldTransform`
* `K2_AddActorWorldRotation`
* `K2_AddActorWorldOffset`
* `K2_AddActorLocalTransform`
* `K2_AddActorLocalRotation`
* `K2_AddActorLocalOffset`
* `IsOverlappingActor`
* `IsChildActor`
* `IsActorTickEnabled`
* `IsActorBeingDestroyed`
* `HasAuthority`
* `GetVerticalDistanceTo`
* `GetVelocity`
* `GetTransform`
* `GetTickableWhenPaused`
* `GetSquaredHorizontalDistanceTo`
* `GetSquaredDistanceTo`
* `GetResimulationThreshold`
* `GetRemoteRole`
* `GetRayTracingGroupId`
* `GetPhysicsReplicationMode`
* `GetParentComponent`
* `GetParentActor`
* `GetOwner`
* `GetOverlappingComponents`
* `GetOverlappingActors`
* `GetLocalRole`
* `GetLifeSpan`
* `GetLevelTransform`
* `GetLevel`
* `GetInstigatorController`
* `GetInstigator`
* `GetInputVectorAxisValue`
* `GetInputAxisValue`
* `GetInputAxisKeyValue`
* `GetHorizontalDotProductTo`
* `GetHorizontalDistanceTo`
* `GetGameTimeSinceCreation`
* `GetDotProductTo`
* `GetDistanceTo`
* `GetComponentsByTag`
* `GetComponentsByInterface`
* `GetComponentByClass`
* `GetAttachParentSocketName`
* `GetAttachParentActor`
* `GetAttachedActors`
* `GetAllChildActors`
* `GetActorUpVector`
* `GetActorTimeDilation`
* `GetActorTickInterval`
* `GetActorScale3D`
* `GetActorRightVector`
* `GetActorRelativeScale3D`
* `GetActorForwardVector`
* `GetActorEyesViewPoint`
* `GetActorEnableCollision`
* `GetActorBounds`
* `ForceNetUpdate`
* `FlushNetDormancy`
* `FinishAddComponent`
* `FindComponentByTag`
* `EnableInput`
* `DisableInput`
* `DetachRootComponentFromParent`
* `CreateInputComponent`
* `CanTriggerResimulation`
* `AddTickPrerequisiteComponent`
* `AddTickPrerequisiteActor`
* `AddComponentByClass`
* `AddComponent`
* `ActorHasTag`

## Subclasses (270)

`AITestSpawner`, `ActorMapBoundingBox`, `AdditionalConversationLight`, `AlkimiaLightweightDecorationActor`, `AmbientItemSpawner`, `AmbientLifeWarningFlock`, `AmbientSound`, `AngelscriptGASActor`, `AvoidCharacterFallOnSpawnActor`, `BFGInstancedSkeletalMeshManager`, `BFGRunningSushiSpawner`, `BFGSimpleCrowdProxyCharacter`, `BFGSimpleCrowdSpawner`, `BP_ARM_Stairs_01_C`, `BP_Banner_C`, `BP_BarrierCloseDistanceManager_C`, `BP_CharacterMinWetnessTrigger_C`, `BP_EasyFog_2_C`, `BP_FluxInteractionCapture_C`, `BP_FluxModifierContainerActor_C`, `BP_FluxNiagaraActor_C`, `BP_FluxOceanWave_C`, `BP_FluxSurfaceCutMask_C`, `BP_FluxSurface_C`, `BP_FluxWorldBrush_C`, `BP_FluxWorldPainter_C`, `BP_FocusStoneOrb_C`, `BP_Fog_Override_Zone_C`, `BP_Fog_SwampCamp_C`, `BP_Grass_Cutter_C`, `BP_Insect_Accumulated_C`, `BP_Insect_Area_Bound_02_C`, `BP_Insect_Controller_C`, `BP_Insect_Flying_02_C`, `BP_Insect_IdleFly_C`, `BP_ItFo_Plants_Mushroom_01_Empty_World_C`, `BP_ItFo_Plants_Ravenherb_01_Empty_World_C`, `BP_ItFo_Plants_Seraphis_01_Empty_World_C`, `BP_ItFo_Plants_Stoneroot_01_Empty_World_C`, `BP_ItFo_Plants_TrollBane_Empty_World_C`, `BP_LavaSpline_C`, `BP_Light_Caustics_Interior_C`, `BP_MFWall_Stair_C_V2_C`, `BP_MFWall_Staris_E_C`, `BP_NavLink_Climb_C`, `BP_OC_StairsFallenTower_01_C`, `BP_OM_Symbols_C`, `BP_Orc_Stairs_01_C`, `BP_Orc_Stairs_PitBase_01_C`, `BP_Orc_Stairs_Tower3_02_C`, `BP_Orc_Stairs_Tower3_03_C`, `BP_Orc_Stairs_Tower3_04_C`, `BP_Rain_Spline_C`, `BP_RectLight_Independent_C`, `BP_SK_Sawmill_C`, `BP_SafeAreaFromBarrier_C`, `BP_StairsGomez_01_C`, `BP_TrollCanyon_Stairs_Entrance_01_C`, `BP_UltraVolumetrics_C`, `BP_Waterfall_C`

… and 210 more
