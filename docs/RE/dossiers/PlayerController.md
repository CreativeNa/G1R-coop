# PlayerController

`class` in `/Script/Engine`, 56 own properties, 162 own functions.

Inheritance: `Object` → `Actor` → `Controller` → `PlayerController`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 816 | 8 | ObjectProperty | `Player` | `ObjectProperty(Player)` |
| 824 | 8 | ObjectProperty | `AcknowledgedPawn` | `ObjectProperty(Pawn)` |
| 832 | 8 | ObjectProperty | `MyHUD` | `ObjectProperty(HUD)` |
| 840 | 8 | ObjectProperty | `PlayerCameraManager` | `ObjectProperty(PlayerCameraManager)` |
| 848 | 8 | ClassProperty | `PlayerCameraManagerClass` | `ObjectProperty(Class)` |
| 856 | 1 | BoolProperty | `bAutoManageActiveCameraTarget` |  |
| 864 | 24 | StructProperty | `TargetViewRotation` | `StructProperty(Rotator)` |
| 912 | 4 | FloatProperty | `SmoothTargetViewRotationSpeed` |  |
| 920 | 16 | ArrayProperty | `HiddenActors` | `ArrayProperty(ArrayProperty(FloatProperty))` |
| 936 | 16 | ArrayProperty | `HiddenPrimitiveComponents` | `ArrayProperty(FloatProperty)` |
| 956 | 4 | FloatProperty | `LastSpectatorStateSynchTime` |  |
| 960 | 24 | StructProperty | `LastSpectatorSyncLocation` | `StructProperty(Vector)` |
| 984 | 24 | StructProperty | `LastSpectatorSyncRotation` | `StructProperty(Rotator)` |
| 1008 | 4 | IntProperty | `ClientCap` |  |
| 1016 | 8 | ObjectProperty | `CheatManager` | `ObjectProperty(CheatManager)` |
| 1024 | 8 | ClassProperty | `CheatClass` | `ObjectProperty(Class)` |
| 1032 | 8 | ObjectProperty | `PlayerInput` | `ObjectProperty(PlayerInput)` |
| 1040 | 16 | ArrayProperty | `ActiveForceFeedbackEffects` | `ArrayProperty(ObjectProperty(Class))` |
| 1056 | 8 | ClassProperty | `AsyncPhysicsDataClass` | `ObjectProperty(Class)` |
| 1064 | 8 | ObjectProperty | `AsyncPhysicsDataComponent_DEPRECARED` | `ObjectProperty(AsyncPhysicsInputComponent)` |
| 1200 | 1 | BoolProperty | `bPlayerIsWaiting` |  |
| 1204 | 1 | ByteProperty | `NetPlayerIndex` |  |
| 1296 | 8 | ObjectProperty | `PendingSwapConnection` | `ObjectProperty(NetConnection)` |
| 1304 | 8 | ObjectProperty | `NetConnection` | `ObjectProperty(NetConnection)` |
| 1336 | 4 | FloatProperty | `InputYawScale` |  |
| 1340 | 4 | FloatProperty | `InputPitchScale` |  |
| 1344 | 4 | FloatProperty | `InputRollScale` |  |
| 1348 | 1 | BoolProperty | `bEnableClickEvents` |  |
| 1348 | 1 | BoolProperty | `bEnableMotionControls` |  |
| 1348 | 1 | BoolProperty | `bEnableMouseOverEvents` |  |
| 1348 | 1 | BoolProperty | `bEnableStreamingSource` |  |
| 1348 | 1 | BoolProperty | `bEnableTouchEvents` |  |
| 1348 | 1 | BoolProperty | `bEnableTouchOverEvents` |  |
| 1348 | 1 | BoolProperty | `bForceFeedbackEnabled` |  |
| 1348 | 1 | BoolProperty | `bShowMouseCursor` |  |
| 1349 | 1 | BoolProperty | `bStreamingSourceShouldActivate` |  |
| 1349 | 1 | BoolProperty | `bStreamingSourceShouldBlockOnSlowStreaming` |  |
| 1352 | 1 | EnumProperty | `StreamingSourcePriority` |  |
| 1356 | 4 | StructProperty | `StreamingSourceDebugColor` | `StructProperty(Color)` |
| 1360 | 16 | ArrayProperty | `StreamingSourceShapes` | `ArrayProperty(FloatProperty)` |
| 1376 | 4 | FloatProperty | `ForceFeedbackScale` |  |
| 1384 | 16 | ArrayProperty | `ClickEventKeys` | `ArrayProperty(ByteProperty)` |
| 1400 | 1 | ByteProperty | `DefaultMouseCursor` |  |
| 1401 | 1 | ByteProperty | `CurrentMouseCursor` |  |
| 1402 | 1 | ByteProperty | `DefaultClickTraceChannel` |  |
| 1403 | 1 | ByteProperty | `CurrentClickTraceChannel` |  |
| 1404 | 4 | FloatProperty | `HitResultTraceDistance` |  |
| 1408 | 2 | UInt16Property | `SeamlessTravelCount` |  |
| 1410 | 2 | UInt16Property | `LastCompletedSeamlessTravelCount` |  |
| 1544 | 8 | ObjectProperty | `InactiveStateInputComponent` | `ObjectProperty(InputComponent)` |
| 1552 | 1 | BoolProperty | `bShouldPerformFullTickWhenPaused` |  |
| 1576 | 8 | ObjectProperty | `CurrentTouchInterface` | `ObjectProperty(TouchInterface)` |
| 1584 | 8 | ClassProperty | `OverridePlayerInputClass` | `ObjectProperty(Class)` |
| 1712 | 8 | ObjectProperty | `SpectatorPawn` | `ObjectProperty(SpectatorPawn)` |
| 1724 | 1 | BoolProperty | `bIsLocalPlayerController` |  |
| 1728 | 24 | StructProperty | `SpawnLocation` | `StructProperty(Vector)` |

## Functions

* `WasInputKeyJustReleased`
* `WasInputKeyJustPressed`
* `ToggleSpeaking`
* `TestServerLevelVisibilityChange`
* `SwitchLevel`
* `StreamingSourceShouldBlockOnSlowStreaming`
* `StreamingSourceShouldActivate`
* `StopHapticEffect`
* `StartFire`
* `SetVirtualJoystickVisibility`
* `SetViewTargetWithBlend`
* `SetName`
* `SetMouseLocation`
* `SetMouseCursorWidget`
* `SetMotionControlsEnabled`
* `SetHapticsByValue`
* `SetDisableHaptics`
* `SetDeprecatedInputYawScale`
* `SetDeprecatedInputRollScale`
* `SetDeprecatedInputPitchScale`
* `SetControllerLightColor`
* `SetCinematicMode`
* `SetAudioListenerOverride`
* `SetAudioListenerAttenuationOverride`
* `ServerViewSelf`
* `ServerViewPrevPlayer`
* `ServerViewNextPlayer`
* `ServerVerifyViewTarget`
* `ServerUpdateMultipleLevelsVisibility`
* `ServerUpdateLevelVisibility`
* `ServerUpdateCamera`
* `ServerUnmutePlayer`
* `ServerUnblockPlayer`
* `ServerToggleAILogging`
* `ServerShortTimeout`
* `ServerSetSpectatorWaiting`
* `ServerSetSpectatorLocation`
* `ServerSendLatestAsyncPhysicsTimestamp`
* `ServerRestartPlayer`
* `ServerRecvClientInputFrame`
* `ServerPause`
* `ServerNotifyLoadedWorld`
* `ServerMutePlayer`
* `ServerExecRPC`
* `ServerExec`
* `ServerCheckClientPossessionReliable`
* `ServerCheckClientPossession`
* `ServerChangeName`
* `ServerCamera`
* `ServerBlockPlayer`
* `ServerAcknowledgePossession`
* `SendToConsole`
* `RestartLevel`
* `ResetControllerLightColor`
* `ProjectWorldLocationToScreen`
* `PlayHapticEffect`
* `PlayDynamicForceFeedback`
* `Pause`
* `OnServerStartedVisualLogger`
* `OnRep_AsyncPhysicsDataComponent`
* `LocalTravel`
* `K2_ClientPlayForceFeedback`
* `IsStreamingSourceEnabled`
* `IsInputKeyDown`
* `GetViewportSize`
* `GetStreamingSourceShapes`
* `GetStreamingSourcePriority`
* `GetStreamingSourceLocationAndRotation`
* `GetSpectatorPawn`
* `GetPlatformUserId`
* `GetOverridePlayerInputClass`
* `GetMousePosition`
* `GetInputVectorKeyState`
* `GetInputTouchState`
* `GetInputMouseDelta`
* `GetInputMotionState`
* `GetInputKeyTimeDown`
* `GetInputAnalogStickState`
* `GetInputAnalogKeyState`
* `GetHUD`
* `GetHitResultUnderFingerForObjects`
* `GetHitResultUnderFingerByChannel`
* `GetHitResultUnderFinger`
* `GetHitResultUnderCursorForObjects`
* `GetHitResultUnderCursorByChannel`
* `GetHitResultUnderCursor`
* `GetFocalLocation`
* `GetDeprecatedInputYawScale`
* `GetDeprecatedInputRollScale`
* `GetDeprecatedInputPitchScale`
* `GetAsyncPhysicsDataToWrite`
* `GetAsyncPhysicsDataToConsume`
* `FOV`
* `EnableCheats`
* `DeprojectScreenPositionToWorld`
* `DeprojectMousePositionToWorld`
* `ConsoleKey`
* `ClientWasKicked`
* `ClientVoiceHandshakeComplete`
* `ClientUpdateMultipleLevelsStreamingStatus`
* `ClientUpdateLevelStreamingStatus`
* `ClientUnmutePlayers`
* `ClientUnmutePlayer`
* `ClientTravelInternal`
* `ClientTravel`
* `ClientTeamMessage`
* `ClientStopForceFeedback`
* `ClientStopCameraShakesFromSource`
* `ClientStopCameraShake`
* `ClientStartOnlineSession`
* `ClientStartCameraShakeFromSource`
* `ClientStartCameraShake`
* `ClientSpawnGenericCameraLensEffect`
* `ClientSpawnCameraLensEffect`
* `ClientSetViewTarget`
* `ClientSetupNetworkPhysicsTimestamp`
* `ClientSetSpectatorWaiting`
* `ClientSetHUD`
* `ClientSetForceMipLevelsToBeResident`
* `ClientSetCinematicMode`
* `ClientSetCameraMode`
* `ClientSetCameraFade`
* `ClientSetBlockOnAsyncLoading`
* `ClientReturnToMainMenuWithTextReason`
* `ClientRetryClientRestart`
* `ClientRestart`
* `ClientReset`
* `ClientRepObjRef`
* `ClientRecvServerAckFrameDebug`
* `ClientRecvServerAckFrame`
* `ClientReceiveLocalizedMessage`
* `ClientPrestreamTextures`
* `ClientPrepareMapChange`
* `ClientPlaySoundAtLocation`
* `ClientPlaySound`
* `ClientPlayForceFeedback_Internal`
* `ClientMutePlayer`
* `ClientMessage`
* `ClientIgnoreMoveInput`
* `ClientIgnoreLookInput`
* `ClientGotoState`
* `ClientGameEnded`
* `ClientForceGarbageCollection`
* `ClientFlushLevelStreaming`
* `ClientEndOnlineSession`
* `ClientEnableNetworkVoice`
* `ClientCorrectionAsyncPhysicsTimestamp`
* `ClientCommitMapChange`
* `ClientClearCameraLensEffects`
* `ClientCapBandwidth`
* `ClientCancelPendingMapChange`
* `ClientAddTextureStreamingLoc`
* `ClientAckUpdateLevelVisibility`
* `ClientAckTimeDilation`
* `ClearAudioListenerOverride`
* `ClearAudioListenerAttenuationOverride`
* `CanRestartPlayer`
* `Camera`
* `AddYawInput`
* `AddRollInput`
* `AddPitchInput`
* `ActivateTouchInterface`

## Subclasses (3)

`ClientAuthoritativePlayerController`, `DebugCameraController`, `PC_Menus_C`
