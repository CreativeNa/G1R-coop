🇬🇧 **English** — below.  🇷🇺 **[Русская версия](#ru)** — ниже.

# Gothic 1 Remake Co-op

Unofficial two-player co-op for **Gothic 1 Remake**. Early beta.
Not affiliated with the game's publisher or developers. Free.

**How to play:** [docs/HOW_TO_PLAY.md](docs/HOW_TO_PLAY.md) — a one-screen guide.

## Requirements

- Gothic 1 Remake, **build 1.2 or newer**. Older builds are not supported: the mod may not work
- Windows 10/11
- Radmin VPN (recommended) or one local network
- **A legitimate copy of the game is required.** The mod contains no game files and bypasses no protection.
  Pirated copies are not supported: the mod may behave unpredictably and no help is provided for them.
  The mod itself is distributed under the licence in [LICENSE](LICENSE) — free, no warranty.

## Installation

1. Unpack `Gothic1Coop-Setup-0.5.3.zip`
2. Run `Setup.cmd` → "Install"
3. Start the game with the **"Gothic 1 Remake Co-op"** shortcut on the desktop

The mod lives in `%LOCALAPPDATA%\G1RCoop`; nothing is written into the game folder.
To remove it, use the **Uninstall** shortcut in the Start menu.

## Co-op in two lines

1. **Host** starts the **"Gothic 1 Remake Co-op"** shortcut first (it launches the game): start a new game,
   skip the Diego dialogue, save (**F5**) — or load an existing save.
2. **Guest** waits until the host is in the game, and only then starts the same shortcut.
   If it does not connect by itself → the **"Join co-op"** button in the main menu.

## Antivirus

The mod injects into the game process, so Defender may flag `inject.exe`. This is a **false positive**.
Do not disable anything: instructions and file hashes are in [docs/ANTIVIRUS.md](docs/ANTIVIRUS.md).

## Found a bug

In the mod folder (`%LOCALAPPDATA%\G1RCoop`) run **"Собрать отчёт.bat"** (collect report) — it asks for a
one-line description and puts a `report_*.zip` archive next to it. Send it to the developer. Addresses,
computer name and user name are replaced automatically.

## Documentation

| Document | Contents |
|---|---|
| [HOW_TO_PLAY.md](docs/HOW_TO_PLAY.md) | how to install and play |
| [TWO_PC_TEST.md](docs/TWO_PC_TEST.md) | network, test order, what to send back |
| [TWO_PC_CHECKLIST.md](docs/TWO_PC_CHECKLIST.md) | step-by-step checklist for the night of testing |
| [ANTIVIRUS.md](docs/ANTIVIRUS.md) | false positives, exclusions, hashes |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | common errors |
| [BUGS.md](docs/BUGS.md) | known issues |
| [releases/0.5.3.md](docs/releases/0.5.3.md) | notes for the current build |
| [RELEASE_INTEGRITY.md](docs/RELEASE_INTEGRITY.md) | how to verify the build and hashes |

## Status

Beta. Working: connection, movement, items, chests, death, F9, time of day, quests, trading, sleeping.
The chapter is not synchronised; known visual defects are listed in `BUGS.md`.

---

<a id="ru"></a>

# Gothic 1 Remake Co-op — Русская версия

Неофициальный кооператив на двоих для **Gothic 1 Remake**. Ранняя бета.
Не связан с издателем и разработчиками игры. Бесплатно.

**Как играть:** [docs/HOW_TO_PLAY.md](docs/HOW_TO_PLAY.md) — короткая инструкция на один экран.

## Что нужно

- Gothic 1 Remake, **build 1.2 и выше**. Более старые сборки не поддерживаются: мод может не заработать
- Windows 10/11
- Radmin VPN (рекомендуется) или одна локальная сеть
- **Лицензионная копия игры — обязательно.** Мод не содержит файлов игры и не обходит защиту.
  С пиратскими копиями он не поддерживается: работать может как угодно, помощи по таким сборкам нет.
  Сам мод распространяется по лицензии из файла [LICENSE](LICENSE) — бесплатно, без гарантий.

## Установка

1. Распаковать архив `Gothic1Coop-Setup-0.5.3.zip`
2. Запустить `Setup.cmd` → «Установить»
3. Запускать игру ярлыком **«Gothic 1 Remake Co-op»** с рабочего стола

Мод живёт в `%LOCALAPPDATA%\G1RCoop`, в папку игры ничего не пишется.
Удаление — ярлык **Uninstall** в меню «Пуск».

## Кооп в двух строках

1. **Хост** — первым запускает ярлык **«Gothic 1 Remake Co-op»** (он и запускает игру): начать новую игру,
   пропустить диалог с Диего, сохраниться (**F5**) — или загрузить уже существующее сохранение.
2. **Гость** — дождаться, пока хост окажется в игре, и только потом нажать тот же ярлык.
   Не подключился сам → в главном меню кнопка **«Присоединиться»**.

## Антивирус

Мод внедряется в процесс игры, поэтому Defender может ругаться на `inject.exe`. Это **ложное срабатывание**.
Ничего не отключайте: инструкция и хеши файлов — в [docs/ANTIVIRUS.md](docs/ANTIVIRUS.md).

## Нашли баг

В папке мода (`%LOCALAPPDATA%\G1RCoop`) запустите **«Собрать отчёт.bat»** — он спросит одну строку описания
и положит рядом архив `report_*.zip`. Пришлите его разработчику. Адреса, имя ПК и пользователя заменяются
автоматически.

## Документация

| Документ | О чём |
|---|---|
| [HOW_TO_PLAY.md](docs/HOW_TO_PLAY.md) | как установить и играть |
| [TWO_PC_TEST.md](docs/TWO_PC_TEST.md) | сеть, порядок проверок, что прислать |
| [TWO_PC_CHECKLIST.md](docs/TWO_PC_CHECKLIST.md) | чек-лист на вечер теста |
| [ANTIVIRUS.md](docs/ANTIVIRUS.md) | ложные срабатывания, исключения, хеши |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | типичные ошибки |
| [BUGS.md](docs/BUGS.md) | известные проблемы |
| [releases/0.5.3.md](docs/releases/0.5.3.md) | заметки к текущей сборке |
| [RELEASE_INTEGRITY.md](docs/RELEASE_INTEGRITY.md) | как проверить сборку и хеши |

## Состояние

Бета. Работает связь, движение, предметы, сундуки, смерть, F9, время суток, задания, торговля, сон.
Не синхронизируется глава; есть известные визуальные дефекты (см. `BUGS.md`).
