# Pawn

`class` in `/Script/Engine`, 19 own properties, 33 own functions.

Inheritance: `Object` → `Actor` → `Pawn`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 664 | 1 | BoolProperty | `bCanAffectNavigationGeneration` |  |
| 664 | 1 | BoolProperty | `bIsLocalViewTarget` |  |
| 664 | 1 | BoolProperty | `bUseControllerRotationPitch` |  |
| 664 | 1 | BoolProperty | `bUseControllerRotationRoll` |  |
| 664 | 1 | BoolProperty | `bUseControllerRotationYaw` |  |
| 668 | 4 | FloatProperty | `BaseEyeHeight` |  |
| 672 | 1 | ByteProperty | `AutoPossessPlayer` |  |
| 673 | 1 | EnumProperty | `AutoPossessAI` |  |
| 674 | 1 | ByteProperty | `RemoteViewPitch` |  |
| 680 | 8 | ClassProperty | `AIControllerClass` | `ObjectProperty(Class)` |
| 688 | 8 | ObjectProperty | `PlayerState` | `ObjectProperty(PlayerState)` |
| 704 | 8 | ObjectProperty | `LastHitBy` | `ObjectProperty(Controller)` |
| 712 | 8 | ObjectProperty | `Controller` | `ObjectProperty(Controller)` |
| 720 | 8 | ObjectProperty | `PreviousController` | `ObjectProperty(Controller)` |
| 732 | 1 | MulticastSparseDelegateProperty | `ReceiveControllerChangedDelegate` |  |
| 733 | 1 | MulticastSparseDelegateProperty | `ReceiveRestartedDelegate` |  |
| 736 | 24 | StructProperty | `ControlInputVector` | `StructProperty(Vector)` |
| 760 | 24 | StructProperty | `LastControlInputVector` | `StructProperty(Vector)` |
| 784 | 8 | ClassProperty | `OverrideInputComponentClass` | `ObjectProperty(Class)` |

## Functions

* `SpawnDefaultController`
* `SetCanAffectNavigationGeneration`
* `ReceiveUnpossessed`
* `ReceiveRestarted`
* `ReceivePossessed`
* `ReceiveControllerChanged`
* `PawnMakeNoise`
* `OnRep_PlayerState`
* `OnRep_Controller`
* `IsPlayerControlled`
* `IsPawnControlled`
* `IsMoveInputIgnored`
* `IsLocallyViewed`
* `IsLocallyControlled`
* `IsControlled`
* `IsBotControlled`
* `GetPlatformUserId`
* `GetPendingMovementInputVector`
* `GetOverrideInputComponentClass`
* `GetNavAgentLocation`
* `GetMovementComponent`
* `GetMovementBaseActor`
* `GetLocalViewingPlayerController`
* `GetLastMovementInputVector`
* `GetControlRotation`
* `GetController`
* `GetBaseAimRotation`
* `DetachFromControllerPendingDestroy`
* `ConsumeMovementInputVector`
* `AddMovementInput`
* `AddControllerYawInput`
* `AddControllerRollInput`
* `AddControllerPitchInput`

## Subclasses (4)

`AngelscriptGASPawn`, `Character`, `DefaultPawn`, `PhotoModePawn`
