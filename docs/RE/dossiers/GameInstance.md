# GameInstance

`class` in `/Script/Engine`, 6 own properties, 6 own functions.

Inheritance: `Object` → `GameInstance`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 56 | 16 | ArrayProperty | `LocalPlayers` | `ArrayProperty(ObjectProperty(OnlineSession))` |
| 72 | 8 | ObjectProperty | `OnlineSession` | `ObjectProperty(OnlineSession)` |
| 80 | 16 | ArrayProperty | `ReferencedObjects` | `ArrayProperty(MulticastInlineDelegateProperty)` |
| 120 | 16 | MulticastInlineDelegateProperty | `OnPawnControllerChangedDelegates` |  |
| 160 | 16 | MulticastInlineDelegateProperty | `OnInputDeviceConnectionChange` |  |
| 176 | 16 | MulticastInlineDelegateProperty | `OnUserInputDevicePairingChange` |  |

## Functions

* `ReceiveShutdown`
* `ReceiveInit`
* `HandleTravelError`
* `HandleNetworkError`
* `DebugRemovePlayer`
* `DebugCreatePlayer`

## Subclasses (3)

`G1RGameInstance`, `LiveLinkGameInstance`, `PlatformGameInstance`
