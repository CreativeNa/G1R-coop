# Character

`class` in `/Script/Engine`, 40 own properties, 48 own functions.

Inheritance: `Object` → `Actor` → `Pawn` → `Character`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 792 | 8 | ObjectProperty | `Mesh` | `ObjectProperty(SkeletalMeshComponent)` |
| 800 | 8 | ObjectProperty | `CharacterMovement` | `ObjectProperty(CharacterMovementComponent)` |
| 808 | 8 | ObjectProperty | `CapsuleComponent` | `ObjectProperty(CapsuleComponent)` |
| 816 | 80 | StructProperty | `BasedMovement` | `StructProperty(BasedMovementInfo)` |
| 896 | 80 | StructProperty | `ReplicatedBasedMovement` | `StructProperty(BasedMovementInfo)` |
| 976 | 4 | FloatProperty | `AnimRootMotionTranslationScale` |  |
| 984 | 24 | StructProperty | `BaseTranslationOffset` | `StructProperty(Vector)` |
| 1008 | 32 | StructProperty | `BaseRotationOffset` | `StructProperty(Quat)` |
| 1040 | 4 | FloatProperty | `ReplicatedServerLastTransformUpdateTimeStamp` |  |
| 1044 | 4 | FloatProperty | `ReplayLastTransformUpdateTimeStamp` |  |
| 1048 | 1 | ByteProperty | `ReplicatedMovementMode` |  |
| 1056 | 24 | StructProperty | `ReplicatedGravityDirection` | `StructProperty(Vector_NetQuantizeNormal)` |
| 1080 | 1 | BoolProperty | `bInBaseReplication` |  |
| 1112 | 4 | FloatProperty | `CrouchedEyeHeight` |  |
| 1116 | 1 | BoolProperty | `bClientResimulateRootMotion` |  |
| 1116 | 1 | BoolProperty | `bClientResimulateRootMotionSources` |  |
| 1116 | 1 | BoolProperty | `bClientUpdating` |  |
| 1116 | 1 | BoolProperty | `bClientWasFalling` |  |
| 1116 | 1 | BoolProperty | `bIsCrouched` |  |
| 1116 | 1 | BoolProperty | `bPressedJump` |  |
| 1116 | 1 | BoolProperty | `bProxyIsJumpForceApplied` |  |
| 1116 | 1 | BoolProperty | `bSimGravityDisabled` |  |
| 1117 | 1 | BoolProperty | `bClientCheckEncroachmentOnNetUpdate` |  |
| 1117 | 1 | BoolProperty | `bServerMoveIgnoreRootMotion` |  |
| 1117 | 1 | BoolProperty | `bWasJumping` |  |
| 1120 | 4 | FloatProperty | `JumpKeyHoldTime` |  |
| 1124 | 4 | FloatProperty | `JumpForceTimeRemaining` |  |
| 1128 | 4 | FloatProperty | `ProxyJumpForceStartedTime` |  |
| 1132 | 4 | FloatProperty | `JumpMaxHoldTime` |  |
| 1136 | 4 | IntProperty | `JumpMaxCount` |  |
| 1140 | 4 | IntProperty | `JumpCurrentCount` |  |
| 1144 | 4 | IntProperty | `JumpCurrentCountPreJump` |  |
| 1152 | 16 | MulticastInlineDelegateProperty | `OnReachedJumpApex` |  |
| 1168 | 16 | MulticastInlineDelegateProperty | `LandedDelegate` |  |
| 1184 | 16 | MulticastInlineDelegateProperty | `MovementModeChangedDelegate` |  |
| 1200 | 16 | MulticastInlineDelegateProperty | `OnCharacterMovementUpdated` |  |
| 1216 | 72 | StructProperty | `SavedRootMotion` | `StructProperty(RootMotionSourceGroup)` |
| 1296 | 112 | StructProperty | `ClientRootMotionParams` | `StructProperty(RootMotionMovementParams)` |
| 1408 | 16 | ArrayProperty | `RootMotionRepMoves` | `ArrayProperty(StructProperty(RepRootMotionMontage))` |
| 1424 | 216 | StructProperty | `RepRootMotion` | `StructProperty(RepRootMotionMontage)` |

## Functions

* `UnCrouch`
* `StopJumping`
* `StopAnimMontage`
* `ServerMovePacked`
* `ServerMoveOld`
* `ServerMoveNoBase`
* `ServerMoveDualNoBase`
* `ServerMoveDualHybridRootMotion`
* `ServerMoveDual`
* `ServerMove`
* `RootMotionDebugClientPrintOnScreen`
* `PlayAnimMontage`
* `OnWalkingOffLedge`
* `OnRep_RootMotion`
* `OnRep_ReplicatedBasedMovement`
* `OnRep_ReplayLastTransformUpdateTimeStamp`
* `OnRep_IsCrouched`
* `OnLaunched`
* `OnLanded`
* `OnJumped`
* `LaunchCharacter`
* `K2_UpdateCustomMovement`
* `K2_OnStartCrouch`
* `K2_OnMovementModeChanged`
* `K2_OnEndCrouch`
* `Jump`
* `IsPlayingRootMotion`
* `IsPlayingNetworkedRootMotionMontage`
* `IsJumpProvidingForce`
* `HasAnyRootMotion`
* `GetCurrentMontage`
* `GetBaseTranslationOffset`
* `GetBaseRotationOffsetRotator`
* `GetAnimRootMotionTranslationScale`
* `Crouch`
* `ClientVeryShortAdjustPosition`
* `ClientMoveResponsePacked`
* `ClientCheatWalk`
* `ClientCheatGhost`
* `ClientCheatFly`
* `ClientAdjustRootMotionSourcePosition`
* `ClientAdjustRootMotionPosition`
* `ClientAdjustPosition`
* `ClientAckGoodMove`
* `CanJumpInternal`
* `CanJump`
* `CanCrouch`
* `CacheInitialMeshOffset`

## Subclasses (7)

`AngelscriptGASCharacter`, `ArchVisCharacter`, `CinematicCharacter`, `ClientAuthoritativeCharacter`, `EQSTestingPawn`, `PaperCharacter`, `SoulHarvestCharacter_Visual`
