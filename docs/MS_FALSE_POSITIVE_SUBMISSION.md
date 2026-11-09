# Заготовка обращения в Microsoft Security Intelligence: ложное срабатывание

**Не отправлено.** Это текст для ручной отправки на https://www.microsoft.com/en-us/wdsi/filesubmission
(раздел «Submit a file for malware analysis», тип — **Incorrectly detected as malware / false positive**).

Личных данных в тексте нет: только имена файлов, размеры, хеши и описание функциональности.

## Что выбрать в форме

- **Submission type:** `Software developer` → `Incorrectly detected as malware`
- **Detection name:** `Behavior:Win32/DefenseEvasion.A!ml` (историческое), при повторных срабатываниях — то имя,
  что покажет Defender
- **Detection product version:** Microsoft Defender Antivirus, сигнатуры указать текущие на момент отправки
  (у нас на 2026-11-09: 1.463.210.0)
- **Files:** приложить `inject.exe` (при повторном срабатывании на ядро/модули — приложить и их)

## Текст обращения (английский, для формы)

```
False positive report: open-source co-op mod launcher for Gothic 1 Remake

Our project is a free, non-commercial co-op modification for Gothic 1 Remake (Unreal Engine 5.4). It consists of a
launcher/injector executable, a native DLL core loaded into the game process, and seven game modules.

The injector performs a standard LoadLibrary-based injection into the game process only:
it opens the game process, allocates memory, writes the path of our own DLL and creates a remote thread that calls
LoadLibraryA. It does not download code, does not modify other processes, does not persist on the system, and does not
communicate with the internet except a direct UDP connection between the two players' computers on the user's LAN/VPN.

Files and SHA-256:
5840D11DDE3ED27F44E533803D951D0E41C5B03E011BB37DA930CF3EB876FFB9  inject.exe 0.5.1 (140288 bytes)
3206AF763FE4CB674BE15E5AC3E4F7DEAF027282DE62C8B3D2A5682AE2575D66  inject.exe 0.5.3 (142848 bytes, version resource + manifest)
52818EE94E2A77895036C494262B16B30998F69BC886B5D648AE3A593F6063DE  core DLL      (286208 bytes)
0C1D763EB2AA5CCE0EEADE299CAEF675B1D5066801CAE58884CDC6C9F8D1CABC  story module  (337408 bytes)
2C30BEF45F70AA876CD292C6C4AAA43E683D6716A41D53B73A0F1E7C7B99D28  npc module    (246272 bytes)
CE6BE122D035E7BCC9926522B2F81F84172B54EF6234C49453FD1ABEE57F4D51  anim module   (150016 bytes)
1C4BF15D417C96934C848C3EC5198A9F17175A307023F02D5123CDA23FBFDA81  equip module  (153600 bytes)
7161A479E9CB7DE7EA62AA12C56BCD3D7674C8A81EB509B4B8B1318D2AFA17EF  menu module   (192000 bytes)
E04EC1A6F6AA3CEC417511C4D18B876526F2CBE12E202679A9CEACF0882CA891  pose module   (194048 bytes)
6F51745473EA01514FA9FF5328B14DA03DCE699FBCC3D4041D90F1E11E537224  probe module  (265728 bytes)

Detections seen in the Defender history (dated): Behavior:Win32/DefenseEvasion.A!ml for inject.exe,
Trojan:Win32/Bearfoos.B!ml for an older build of the core DLL, Trojan:Win32/Wacatac.C!ml for a release archive.
None of them reproduces in our latest package with current signatures; the executable is byte-identical to the one
that was flagged, so we believe the behavioural verdict is a false positive.

Additional context: the executable currently carries no version resource; we are adding a manifest and version
information, and we removed the unnecessary IsDebuggerPresent call to stop looking like an evasion tool. We are not
packing or obfuscating the binaries.
```

## Что приложить

1. `inject.exe` из актуального пакета (`dist\Gothic1Coop-Setup-<версия>\payload\inject.exe`).
2. Если срабатывание было на ядро или модуль — соответствующий `.dll`.
3. Скриншот журнала Defender с именем угрозы и путём файла.

## Перед отправкой проверить

- [ ] пакет актуальной сборки (не старый), хеш совпадает с таблицей;
- [ ] в тексте нет имён ПК, пользователей, IP-адресов и путей с именем пользователя;
- [ ] указана версия сигнатур на момент отправки;
- [ ] после отправки записать номер обращения в `docs/TESTLOG.md`.

Отправлять вручную и только после решения владельца проекта: автоматическая отправка образцов у нас включена
(`SubmitSamplesConsent = 1`), но это не то же самое, что обращение о ложном срабатывании.
