# ConversationTopic

`class` in `/Script/G1R`, 20 own properties, 32 own functions.

Inheritance: `Object` → `ConversationTopic`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 40 | 8 | NameProperty | `ForCharacter` |  |
| 48 | 8 | NameProperty | `WithCharacter` |  |
| 56 | 16 | ArrayProperty | `RequiredNearbyCharacters` | `ArrayProperty(ArrayProperty(FloatProperty))` |
| 72 | 16 | ArrayProperty | `ExtraCharactersToInvite` | `ArrayProperty(FloatProperty)` |
| 88 | 4 | FloatProperty | `RequiredOtherCharactersMaxDistance` |  |
| 96 | 16 | TextProperty | `Caption` |  |
| 112 | 1 | BoolProperty | `bStartedWithInitialForcedLine` |  |
| 116 | 4 | IntProperty | `PriorityRank` |  |
| 120 | 48 | StructProperty | `Rules` | `StructProperty(TopicRules)` |
| 168 | 16 | TextProperty | `InitialForcedLine` |  |
| 184 | 1 | EnumProperty | `ForcedSenseType` |  |
| 185 | 1 | BoolProperty | `bIsSubTopic` |  |
| 186 | 1 | BoolProperty | `bIsFollowupTopic` |  |
| 187 | 1 | BoolProperty | `bIsFallbackTopic` |  |
| 188 | 1 | BoolProperty | `bIsAmbientTopic` |  |
| 189 | 1 | BoolProperty | `bSayHeyYou` |  |
| 192 | 80 | SetProperty | `JustOne` | `SetProperty(StructProperty(GameplayTagContainer))` |
| 272 | 32 | StructProperty | `PropertyTags` | `StructProperty(GameplayTagContainer)` |
| 304 | 8 | Int64Property | `DebugId` |  |
| 312 | 20 | StructProperty | `ForceSettings` | `StructProperty(ConversationTopicForceSettings)` |

## Functions

* `WasInitialForcedLinePlayed`
* `SetPermanent`
* `ReturnToLastSelection`
* `RequestStopConversationCamera`
* `RequestStartConversationCamera`
* `RequestCameraToLookAtInteractionSpot`
* `RequestCameraToLookAtCharacter`
* `RequestCameraSnapToInteractionSpot`
* `RequestCameraSnapToCharacter`
* `RequestCameraReverseShot`
* `IsStoryDebuggerAttached`
* `IsForced`
* `IsEnd`
* `InviteParticipatingCharactersIntoConversation`
* `HasIsVisibleImplementation`
* `HasActImplementation`
* `GetSelf`
* `GetOwner`
* `GetOther`
* `GetKnowledge`
* `GetCurrentConversationGroup`
* `GetCharacter`
* `FindTopicClassByName`
* `FindTopicClassByDebugId`
* `EndConversation`
* `DC`
* `DB`
* `BP_IsVisible`
* `AreParticipatingCharactersNearby`
* `AreParticipatingCharactersInSameConversation`
* `AreParticipatingCharactersAbleToEnterConversation`
* `Act`

## Subclasses (1)

`G1RDialogTopic`
