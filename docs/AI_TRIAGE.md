# Разбор отчёта без владельца (runbook для ИИ)

Цель: получить `report_*.zip` от тестера и выдать диагноз + правку **без участия владельца**.
Всё, что нужно, лежит в архиве; никаких вопросов тестеру, кроме самого архива.

## 1. Что делать по шагам

```powershell
# 1. распаковать
$d = "$env:TEMP\rep"; Expand-Archive <report.zip> -DestinationPath $d -Force

# 2. машинный разбор (быстро)
Get-Content "$d\report.json" | ConvertFrom-Json | Format-List

# 3. вердикт
.\tools\triage_report.ps1 -Report <report.zip>

# 4. смотреть только релевантное
Get-Content "$d\launcher.log" | Select-String 'role:|found|savesync|inject|ERROR'
Get-Content "$d\coopdll.log" | Select-String 'EXCEPTION|AV at|contact|role changed' | Select-Object -Last 40
```

## 2. Таблица диагнозов

| Признак в отчёте | Диагноз | Что менять |
|---|---|---|
| `report.json.gameBuild != 175124992` | сборка игры другая | ничего: объяснить, что 1.2+; предложить обновить игру |
| `launcher.log`: `no host answered` + роль guest | гость стартовал раньше хоста / нет Radmin | поведение лаунчера (ожидание дольше) или гайд |
| `launcher.log`: `LoadLibrary returned 0x0` | мод не внедрился | проверить `inject.exe` (антивирус), `install.log` |
| `savesync fetch returned` | сохранения не передались | `tools/savesync.ps1`, порт 40003, брандмауэр |
| `report.json.contactLines == 0`, роль host | гость не дошёл | сеть: порты 40001/40002, Radmin, IP |
| `coopdll.log`: `EXCEPTION`/`AV at` | краш мода | искать последнюю строку перед падением, это место правки |
| `install.log`: файлов меньше 10 | установка неполная | переустановка; проверить манифест |

## 3. Границы: что ИИ делает сам, а что нет

**Делает сам:**
- читает отчёт, ставит диагноз, пишет патч в `native/` или `installer/`;
- пересобирает (`build.bat`, `build_module.bat`), проверяет `verify_hashes.ps1`;
- правит документацию;
- отвечает тестеру готовым текстом.

**Не делает без владельца:**
- не публикует релизы, не меняет видимость репозитория;
- не отправляет образцы в Microsoft/VirusTotal;
- не меняет настройки антивируса и защиты;
- не запускает игру серийно (один запуск — только с разрешения).

## 4. Как проверять правку без второго ПК

```powershell
cd native; .\build.bat; .\build_module.bat          # компиляция
cd ..; .\tools\make_installer_package.ps1 -Version 0.5.3
.\tools\verify_hashes.ps1 -Package dist\Gothic1Coop-Setup-0.5.3   # манифест
.\tools\test_install_cycle.ps1 -AllowSideEffects -Payload dist\Gothic1Coop-Setup-0.5.3\payload
$env:G1RCOOP_SELFTEST='1'; powershell -File "$env:LOCALAPPDATA\G1RCoop\CoopLauncher.ps1"
```

Этого достаточно, чтобы не сломать установку и лаунчер. Сетевую часть подтверждает только парная сессия — так и пишем тестеру.

## 5. Формат ответа тестеру

```
Спасибо, отчёт разобрал.

Причина: <одна строка из таблицы>.
Что сделать: <1–2 шага>.
Если не поможет — пришлите новый отчёт с обоих ПК.
```

## 6. Что просить, если отчёта нет

Минимум: `report_*.zip` с **обоих** ПК. Если его нет вообще — папку `%LOCALAPPDATA%\G1RCoop\logs`.
Ничего больше не требуется: конфигурация, версии и хеши уже внутри.
