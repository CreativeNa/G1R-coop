# World

`class` in `/Script/Engine`, 37 own properties, 3 own functions.

Inheritance: `Object` → `World`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 48 | 8 | ObjectProperty | `PersistentLevel` | `ObjectProperty(Level)` |
| 56 | 8 | ObjectProperty | `NetDriver` | `ObjectProperty(NetDriver)` |
| 64 | 8 | ObjectProperty | `LineBatcher` | `ObjectProperty(LineBatchComponent)` |
| 72 | 8 | ObjectProperty | `PersistentLineBatcher` | `ObjectProperty(LineBatchComponent)` |
| 80 | 8 | ObjectProperty | `ForegroundLineBatcher` | `ObjectProperty(LineBatchComponent)` |
| 88 | 8 | ObjectProperty | `NetworkManager` | `ObjectProperty(GameNetworkManager)` |
| 96 | 8 | ObjectProperty | `PhysicsCollisionHandler` | `ObjectProperty(PhysicsCollisionHandler)` |
| 104 | 16 | ArrayProperty | `ExtraReferencedObjects` | `ArrayProperty(ArrayProperty(ArrayProperty(StructProperty(StreamingLevelsToConsider))))` |
| 120 | 16 | ArrayProperty | `PerModuleDataObjects` | `ArrayProperty(ArrayProperty(StructProperty(StreamingLevelsToConsider)))` |
| 136 | 16 | ArrayProperty | `StreamingLevels` | `ArrayProperty(StructProperty(StreamingLevelsToConsider))` |
| 152 | 40 | StructProperty | `StreamingLevelsToConsider` | `StructProperty(StreamingLevelsToConsider)` |
| 192 | 8 | ObjectProperty | `ServerStreamingLevelsVisibility` | `ObjectProperty(ServerStreamingLevelsVisibility)` |
| 200 | 16 | StrProperty | `StreamingLevelsPrefix` |  |
| 224 | 8 | ObjectProperty | `CurrentLevelPendingVisibility` | `ObjectProperty(Level)` |
| 232 | 8 | ObjectProperty | `CurrentLevelPendingInvisibility` | `ObjectProperty(Level)` |
| 240 | 8 | ObjectProperty | `DemoNetDriver` | `ObjectProperty(DemoNetDriver)` |
| 248 | 8 | ObjectProperty | `MyParticleEventManager` | `ObjectProperty(ParticleEventManager)` |
| 256 | 8 | ObjectProperty | `DefaultPhysicsVolume` | `ObjectProperty(PhysicsVolume)` |
| 318 | 1 | BoolProperty | `bAreConstraintsDirty` |  |
| 336 | 8 | ObjectProperty | `NavigationSystem` | `ObjectProperty(NavigationSystemBase)` |
| 344 | 8 | ObjectProperty | `AuthorityGameMode` | `ObjectProperty(GameModeBase)` |
| 352 | 8 | ObjectProperty | `GameState` | `ObjectProperty(GameStateBase)` |
| 360 | 8 | ObjectProperty | `AISystem` | `ObjectProperty(AISystemBase)` |
| 368 | 8 | ObjectProperty | `AvoidanceManager` | `ObjectProperty(AvoidanceManager)` |
| 376 | 16 | ArrayProperty | `Levels` | `ArrayProperty(ArrayProperty(ObjectProperty(GameInstance)))` |
| 392 | 16 | ArrayProperty | `LevelCollections` | `ArrayProperty(ObjectProperty(GameInstance))` |
| 472 | 8 | ObjectProperty | `OwningGameInstance` | `ObjectProperty(GameInstance)` |
| 480 | 16 | ArrayProperty | `ParameterCollectionInstances` | `ArrayProperty(ObjectProperty(Canvas))` |
| 496 | 8 | ObjectProperty | `CanvasForRenderingToTarget` | `ObjectProperty(Canvas)` |
| 504 | 8 | ObjectProperty | `CanvasForDrawMaterialToRenderTarget` | `ObjectProperty(Canvas)` |
| 624 | 8 | ObjectProperty | `PhysicsField` | `ObjectProperty(PhysicsFieldComponent)` |
| 632 | 80 | SetProperty | `ComponentsThatNeedPreEndOfFrameSync` | `SetProperty(ArrayProperty(ArrayProperty(ObjectProperty(WorldComposition))))` |
| 712 | 16 | ArrayProperty | `ComponentsThatNeedEndOfFrameUpdate` | `ArrayProperty(ArrayProperty(ObjectProperty(WorldComposition)))` |
| 728 | 16 | ArrayProperty | `ComponentsThatNeedEndOfFrameUpdate_OnGameThread` | `ArrayProperty(ObjectProperty(WorldComposition))` |
| 1832 | 8 | ObjectProperty | `WorldComposition` | `ObjectProperty(WorldComposition)` |
| 1840 | 8 | ObjectProperty | `ContentBundleManager` | `ObjectProperty(ContentBundleManager)` |
| 2016 | 88 | StructProperty | `PSCPool` | `StructProperty(WorldPSCPool)` |

## Functions

* `K2_GetWorldSettings`
* `HandleTimelineScrubbed`
* `GetDataLayerManager`
