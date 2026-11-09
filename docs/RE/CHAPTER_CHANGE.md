# Смена главы в Gothic 1 Remake — всё, что выяснено

Проверено live на запущенной игре (probe) и по исходникам официального ModKit
(`github.com/AlkimiaInteractive/G1R-Modkit`, 7 280 скриптов) 2026-11-08.

## 1. Где живёт глава

```
GameStory::Chapter            IntProperty @80/4      — рабочее значение
GameStory::ChapterFormatText  TextProperty @64/16
GameStory::ChapterNotificationWidgetClass  SoftClassProperty @168/40
story::OnChapterChanged       MulticastInlineDelegateProperty @216/16
```

Читается и **пишется** напрямую:

```
get 0x<story> Chapter          → Chapter [IntProperty @80/4] = 1
set 0x<story> Chapter 2        → Chapter written: 1
get 0x<story> Chapter          → = 2
```

После записи игра сразу считает себя в новой главе — проверено вызовами:

```
call <story> GameStory IsInChapter        Number=i:2  → 1 (true)
call <story> GameStory HasReachedChapter  Number=i:3  → 0 (false)
```

Значение держится (перепроверено через 10 секунд — не пересчитывается каждый кадр).

## 2. API запросов

```
GameStory::IsInChapter(Number@0/4 ReturnValue@4/1(out))
GameStory::HasReachedChapter(Number@0/4 ReturnValue@4/1(out))
GameStory::GetChapterDisplayName(ChapterIndex@0/4 ReturnValue@8/16(out))
GameStory::RequestChapterHUDNotification(NewChapter@0/4)
```

## 3. Что делает игра при настоящей смене главы

`UStory::HandleChapterChanged(int32 NewChapter)` в `Script/Story/Support/DialogImport.as` (BlueprintOverride, а в
отражении виден как `story::BP_HandleChapterChanged`):

```cpp
UWorldPointManager::Get().CallGlobalEvent(FName(f"{Class.Name}_EnteredChapter_{NewChapter}"));
UWorldPointManager::Get().CallNewChapter(NewChapter);
RequestChapterHUDNotification(NewChapter);
OnChapterChanged.Broadcast(this, NewChapter);
```

Четыре шага, и все четыре, кроме последнего, **воспроизводятся извне**:

```
call <manager> WorldPointManager CallGlobalEvent EventName=n:StoryG1R_EnteredChapter_2
call <manager> WorldPointManager CallNewChapter   NewChapter=i:2
call <story>   GameStory         RequestChapterHUDNotification NewChapter=i:2
```

`<manager>` — живой объект `WorldPointManager` (у него есть `CallGlobalEvent(EventName@0/8)` и
`CallNewChapter(NewChapter@0/4)`). Все три вызова вернули `call ran: 1`, игра осталась жива.

**Не воспроизводится** только `OnChapterChanged.Broadcast` — это делегат уровня скрипта; слушателей в ModKit нет
(объявлен в `DialogImport.as:55`, транслируется в `:123`).

## 4. Что за этим стоит в контенте

События `StoryG1R_EnteredChapter_N` — основной рычаг главы в скриптах. Упоминаний в ModKit:

| Глава | Упоминаний |
|---|---|
| 2 | 261 |
| 3 | 240 |
| 4 | 193 |
| 5 | 171 |
| 6 | 53 |

Пример из `Script/Items/GenericItems/TradersGeneric.as`: ассортимент торговцев **добавляется по главам** —
`AddTraderItemAllDifficulties(UItMi_Orenugget::StaticClass(), 13, "StoryG1R_EnteredChapter_2")`,
отмычки и факелы — тоже со 2-й главы. То есть смена главы меняет и торговлю, что напрямую задевает наш мод
(синхронизацию складов).

Скрипты читают главу через свойство: например `Ownership_OCCastle_Quest.as:52` — `return Story.Chapter == 5;`.

## 5. Плашка главы

`RequestChapterHUDNotification(N)` показывает уведомление. Класс виджета по умолчанию:
`/Game/UI/Notifications/HighNotifications/W_Notification_NewChapter_2`.
Иконки по главам — в `Script/UI/HUDNotificationWidget.as`
(`m_ChapterIcons` → `/Game/UI/Textures/Notifications/T_ChapterImage_Ch1…`).

Проверено: вызов на главу 2 дал в логе `S cine: RequestChapterHUDNotification 2 (params seen)`.

## 6. Сохранение и загрузка — глава в сейве

**Публичное поле `m_ChapterID` в сейве НЕ является источником живой главы.** Проверено экспериментом:

1. в файле `G1R-009.sav` подменили `m_ChapterID` на 2 (ровно один байт, 0x72D, 1 → 2);
2. загрузили этот сейв в игру;
3. живая глава осталась **1**, файл при этом сохранил значение 2 (игра его не перезаписала).

Файл разобран (см. `tools/g1r_save_reader.py`, `g1r_save_info.py`): `GSAV` + 13 байт преамбулы → карта
`CustomPayload` (MapProperty) → записи `/Script/G1R.SaveDataPayload` → два дерева свойств (18 и 17 тегов) →
сжатый блок `Oodle`. Глава восстанавливается из данных истории, а они внутри сжатого блока; `OodleLZ_Decompress`
влинкован в `G1R-Win64-Shipping.exe` статически, отдельной `oo2core*.dll` на машине нет.

## 7. Практический вывод для мода

- Держать главу в синхроне между копиями можно **без сейвов**: читать `Chapter` и писать его второй стороне
  тем же способом, каким мод уже пишет `AttributeSet_Strength`.
- Плашку можно показать вызовом `RequestChapterHUDNotification`, что мод уже умеет.
- Полную смену главы (с событиями контента и торговлей) можно повторить тремя вызовами из раздела 3, если понадобится
  тест «перешли в главу N» без прохождения.
- Правка сейва для смены главы **не работает** — этот путь закрыт до распаковки Oodle.
