# GameStory

`class` in `/Script/G1R`, 6 own properties, 14 own functions.

Inheritance: `Object` → `Subsystem` → `GameStateSubsystem` → `TickableGameStateSubsystem` → `GameStory`

## Properties

| offset | size | type | name | points at |
|---|---|---|---|---|
| 64 | 16 | TextProperty | `ChapterFormatText` |  |
| 80 | 4 | IntProperty | `Chapter` |  |
| 88 | 80 | MapProperty | `StoryDataLayersState` | `MapProperty(ObjectProperty(Class),NameProperty)` |
| 168 | 40 | SoftClassProperty | `ChapterNotificationWidgetClass` | `ObjectProperty(Class)` |
| 208 | 1 | BoolProperty | `bShouldActivateStory` |  |
| 212 | 4 | FloatProperty | `SortOrder` |  |

## Functions

* `RequestChapterHUDNotification`
* `IsStoryActive`
* `IsInChapter`
* `HasReachedChapter`
* `GetMainStoryClass`
* `GetMainStory`
* `GetChapterDisplayName`
* `GetChapter`
* `GetAllActiveStories`
* `GetActiveStoryOfClass`
* `DeactivateStoryDataLayer`
* `ChangeChapter`
* `BP_HandleChapterChanged`
* `ActivateStoryDataLayer`

## Subclasses (1)

`story`
