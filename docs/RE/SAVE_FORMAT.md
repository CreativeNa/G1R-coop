# Формат сохранений Gothic 1 Remake (.sav) — полная спецификация

Всё ниже получено разбором реальных сейвов (12 файлов, `G1R-001…011` + правленая копия) и проверено побайтово
2026-11-07/08. Инструменты: `tools/g1r_save_reader.py`, `tools/g1r_save_info.py`, `tools/g1r_save_field.py`.

## Почему готовые инструменты не работают

`uesave` и любой GVAS-редактор падают. Причина не в «сжатии» и не в версии — **другой формат тега**:

| Правило | Стандартный GVAS | G1R |
|---|---|---|
| Магия | `GVAS` | `GSAV` (байты переставлены) |
| Порядок полей тега | имя, тип, **размер, индекс** | имя, тип, **индекс, размер** |
| Байт между размером и значением | нет | **есть один** (у `bool` это само значение) |
| `ArrayProperty` | размер + счётчик | **размера нет**: сразу внутренний тип, потом int, потом количество |
| `StructProperty` | размер + имя структуры | имя структуры **вместо** размера, затем int, путь класса, int, размер |

## Общая раскладка файла

```
0x00  "GSAV"
0x04  int32  (меняется между файлами; у G1R-009 = 320115970)
0x08  int32  (меняется; 641280)
0x0C  int32  (одинаков в разных файлах; 3584)
0x0D  свойство CustomPayload : MapProperty  ← начало дерева
        записи /Script/G1R.SaveDataPayload
        дерево 1 (18 тегов) → "None"
        дерево 2 (17 тегов) → "None"
        "None"
        сжатый блок: int, "Oodle", хэш, таблица чанков
```

## Тег свойства (проверено байтами)

```
FString  имя            int32 длина (с NUL), затем байты; "None" = конец списка
FString  тип            ObjectProperty | StructProperty | IntProperty | StrProperty | BoolProperty |
                        ArrayProperty | MapProperty | ...
int32    индекс массива
int32    размер         (кроме ArrayProperty и StructProperty)
uint8    флаг           у BoolProperty это И ЕСТЬ значение; у остальных — флаг
<size>   значение
```

### ArrayProperty

```
FString  имя, FString "ArrayProperty", int32 индекс
FString  внутренний тип (напр. "ByteProperty")   ← здесь был бы размер
int32    неиспользуемый int (0 во всех виденных)
int32    количество элементов
<элементы>            ByteProperty → 1 байт, иначе 4
uint8    хвостовой байт
```

### StructProperty

```
FString  имя, FString "StructProperty", int32 индекс
FString  имя структуры ("DateTime")
int32    1
FString  путь структуры ("/Script/CoreUObject")
int32    0
int32    размер значения
<значение>
uint8    хвостовой байт
```

### MapProperty (`CustomPayload`)

```
FString  имя, FString "MapProperty", int32 индекс (2)
FString  тип ключа       "ObjectProperty"
FString  тип значения    "StructProperty"
int32    1
FString  "InstancedStruct"
int32    1
FString  "/Script/StructUtils"
int32    0
int32    0x933 (2355), int32 8, int32 0
FString  "/Script/G1R.SaveDataPayload"   (дважды)
int32    0x4AC (1196)
<дальше значения: деревья свойств>
```

## Публичные поля (дерево 2, начало 0x5DC)

| Поле | Тип | Что это |
|---|---|---|
| `m_SlotName` | Str | имя слота (`G1R-009`) |
| `m_PlayerSaveName` | Str | подпись в меню («МИР ЗАКЛЮЧЁННЫХ — ДЕНЬ 3, 16:17») |
| `m_IsPlayerSaveNameCustom` | Bool | подпись изменена вручную |
| `m_CompressedBitmap` | Array\<Byte\> | битовая карта (4 байта) |
| `m_ChapterID` | Int | глава — **но не источник живой главы** (см. CHAPTER_CHANGE.md) |
| `m_difficultyPreset` | Object | сложность |
| `m_customCombat/Resources/ProgressionSettings` | Object | пользовательские настройки |
| `m_MapName` | Str | карта (`MainMap`) |
| `m_Date` | Struct | `DateTime`, 8 байт тиков |
| `m_TimePlayed`, `m_TimeLoaded` | Double | время |
| `m_QuickSave`, `m_PermaDeath`, `m_SurvivalMode` и др. | Bool | флаги |

Дерево 1 (начало 0xE6) — служебные флаги слота: `m_QuickSave`, `m_AutoSave`, `m_SlotName`, `m_ProfileId`,
`m_PlayerSaveName`, `m_IsPlayerSaveNameCustom`, `m_CompressedBitmap`, `m_difficultyPreset`,
`m_custom*Settings`, `m_PermaDeath`, `m_PermaDeathGameOver`, `m_SurvivalMode` → `None` (0x589).

## Сжатый блок

После двух `None` (0x9C4 и 0x9CD):

```
0x9D6  int32 0x044FB34C (72 332 108)
0x9DA  int32 0
0x9DE  FString "Oodle"
0x9E8  uint32 0x9E2A83C1 (хэш)
0x9EC  uint32 0x22222222
0x9F0  дальше таблица чисел: 0x12E80C02 (317 197 314), повтор 0x044FB34C, 0x77B (1915), 0x570 (1392) …
```

**Распаковать отдельным скриптом нельзя:** `OodleLZ_Decompress` влинкован в `G1R-Win64-Shipping.exe`
статически (14 вхождений строк в exe), отдельной `oo2core*.dll` ни в игре, ни на диске нет. Проверена и
zlib-гипотеза: ни один поток не распаковывается (41 кандидат).

## Что можно и чего нельзя

| Действие | Статус |
|---|---|
| Прочитать публичные поля (слот, глава, карта, даты, сложность) | **можно**, 12/12 файлов |
| Изменить int-поле (глава) | **можно**, ровно 1 байт (`0x72D` для G1R-009), размер файла не меняется |
| Дочитать историю/NPC | нельзя без Oodle внутри процесса игры |

## Инструменты

```powershell
python tools\g1r_save_info.py <save>          # структура файла
python tools\g1r_save_info.py <save> --tags   # все теги с размерами
python tools\g1r_save_field.py <save> --get m_ChapterID
python tools\g1r_save_field.py <save> --set m_ChapterID 2 --out new.sav
```

`--set` никогда не пишет в исходный файл. Настоящие сейвы при разборе не изменялись — работа шла на копиях.
