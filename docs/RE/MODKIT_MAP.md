# Карта официального ModKit G1R — что там есть и что нам нужно

Источник: `github.com/AlkimiaInteractive/G1R-Modkit` (публичный, AngeliScript, 7 280 файлов в `Script`,
UE 5.4.3, Hazelight AngelScript). Склонирован 2026-11-08, разбор по конкретным задачам мода.

## Что подтверждено и для чего пригодится

| Находка в ModKit | Где | Зачем нам |
|---|---|---|
| `UStory::HandleChapterChanged` — конвейер смены главы из 4 шагов | `Script/Story/Support/DialogImport.as:117-123` | см. `CHAPTER_CHANGE.md` |
| `OnChapterChanged` (делегат), слушателей в скриптах нет | там же `:55`, `:123` | знать, что трансляция — только для BP |
| Ассортимент торговцев по главам: `StoryG1R_EnteredChapter_N` | `Script/Items/GenericItems/TradersGeneric.as:91+` | смена главы меняет торговлю → задевает нашу синхронизацию складов |
| Всего 918 упоминаний событий глав (ch2 261, ch3 240, ch4 193, ch5 171, ch6 53) | весь `Script` | понимать масштаб последствий |
| `HasStartedTrading()` = проверка памяти `Memory_Character_Can_Trade`, **не** признак открытого окна | `Script/GAS/GASCharacterStateMixins.as` | наш `trade_task_alive` не может на это опираться |
| `UCommonPlayerDefinition` и наборы `AttributeSet_*` (Health, Armor, LevelProgression, Mana, Movement, Dexterity, Strength, Oxygen, Sleep, Lockpicking, Pickpocketing) | `Script/Player/PlayerCharacter.as` | какие атрибуты существуют; мы синхронизируем 4 из 13 |
| `UPlayerConfig_G1R` и варианты Two…Five | `Script/Player/PlayerConfig.as` | несколько конфигураций — **не** доказательство второго игрока |
| `ControlCommand` — debug-поссессия NPC через `Event_Possessed_Debug_Start` | `Script/CheatMode/Commands/ControlCommand.as` | как игра передаёт управление; не заменяет второго PlayerController |
| Примеры спавна персонажей | `Examples/Example-CharacterSpawner`, `Example-NewHumanCharacter` | спавн NPC рядом с игроком |
| Script Hooking: `UCLASS(meta=(ReplaceParentClass))`, инъекция в класс | документация ModKit | как править классы без форка |
| Script Patches: Unified Diff `.patch` перед компиляцией | документация ModKit | минимальные правки базовых скриптов |
| `StoryG1R` — поля `UPROPERTY(SaveGame)`, поддерживаются только `int32` и `FInGameTime` | `Script/Story/G1R/StoryG1R.as` + документация | ограничение на свои story-переменные |
| `UStoryVariablesCommand` — чит-команда работы со story-переменными | `Script/CheatMode/Commands/StoryVariablesCommand.as` | готовый способ читать/писать переменные истории |

## Живые объекты и адреса (проверено probe на запущенной игре)

```
findall StoryG1R *            → <addr> StoryG1R_<id> (StoryG1R)     объект истории
findall WorldPointManager *   → <addr> WorldPointManager            менеджер точек мира
class StoryG1R Chapter        → GameStory::Chapter [IntProperty @80/4]
```

Функции, которые реально вызывались и вернули `call ran: 1`:

```
GameStory::IsInChapter(Number@0/4 ReturnValue@4/1(out))
GameStory::HasReachedChapter(Number@0/4 ReturnValue@4/1(out))
GameStory::GetChapterDisplayName(ChapterIndex@0/4 ReturnValue@8/16(out))
GameStory::RequestChapterHUDNotification(NewChapter@0/4)
WorldPointManager::CallGlobalEvent(EventName@0/8)
WorldPointManager::CallNewChapter(NewChapter@0/4)
```

Что **не** вызывается по имени через probe: `story::BP_HandleChapterChanged` (`function ... not found`).
Отсюда вывод: отражённые Blueprint-события этим путём не вызвать, только нативные функции.

## Плашка главы

Класс по умолчанию `ChapterNotificationWidgetClass`:
`/Game/UI/Notifications/HighNotifications/W_Notification_NewChapter_2`.
Иконки по главам: `Script/UI/HUDNotificationWidget.as`, `m_ChapterIcons` →
`/Game/UI/Textures/Notifications/T_ChapterImage_Ch1…Ch6`.

## Чего в ModKit нет

- Настройки второго LocalPlayer / split-screen — только наборы конфигураций персонажа.
- Обработчиков `OnChapterChanged` в скриптах.
- Сетевого кода: кооператив мы делаем сами, ModKit даёт точки входа (см. `docs/RE/05_COOP_BRIDGE.md`).
