# QuestSubsystem

`class` in `/Script/G1R`, 9 own properties, 6 own functions.

Inheritance: `Object` → `Subsystem` → `GameStateSubsystem` → `TickableGameStateSubsystem` → `QuestSubsystem`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 64 | 80 | MapProperty | `AllQuests` | `MapProperty(ArrayProperty(ArrayProperty(ArrayProperty(ByteProperty))),ArrayProperty(ArrayProperty(ArrayProperty(ByteProperty))))` |
| 144 | 16 | ArrayProperty | `AllQuestInstances` | `ArrayProperty(ArrayProperty(ArrayProperty(ArrayProperty(ByteProperty))))` |
| 160 | 16 | ArrayProperty | `TickingQuestsWhenInStateNone` | `ArrayProperty(ArrayProperty(ArrayProperty(MulticastInlineDelegateProperty)))` |
| 176 | 16 | ArrayProperty | `TickingQuestsWhenInStateRunning` | `ArrayProperty(ArrayProperty(MulticastInlineDelegateProperty))` |
| 192 | 16 | ArrayProperty | `TickingQuestsWhenInStateAvailable` | `ArrayProperty(MulticastInlineDelegateProperty)` |
| 232 | 16 | MulticastInlineDelegateProperty | `OnQuestStarted` |  |
| 272 | 16 | MulticastInlineDelegateProperty | `OnQuestFailed` |  |
| 312 | 16 | MulticastInlineDelegateProperty | `OnQuestSucceeded` |  |
| 352 | 16 | MulticastInlineDelegateProperty | `OnQuestAvailable` |  |

## Functions

* `OnRep_AllQuestInstances`
* `GetQuestByClass`
* `GetParentQuest`
* `GetChildQuests`
* `GetAllQuestsInState`
* `GetAllQuests`
