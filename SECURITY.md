# Security / Безопасность

## English

**Versions 0.5.3, 0.5.4.5 and everything older are affected by a serious vulnerability. Update to 0.5.4.6 or newer.**

What was wrong: the launcher started a diagnostic service on TCP port 40004 on every launch, without a password. Anyone who could reach that port
(a member of your Radmin VPN network, someone on your local network, or anyone on the internet if the port was forwarded) could send a file that
the mod then loaded into the game, i.e. run code on your PC. The same service also returned the computer name, the Windows user name, the mod logs
and settings to anyone who asked. In addition, the mod's core DLL contained the developer's Windows user name inside a file path.

What changed in 0.5.4.6:

- the diagnostic service is **off by default**; a developer can switch it on in `settings.ini` (`diag_bridge = 1`, `diag_token = <16+ characters>`);
  it refuses to start without a token, rejects every request without the token and no longer reports the computer or user name;
- the core DLL no longer contains any path of the developer's PC.

If you cannot update right away: close the game, delete `%LOCALAPPDATA%\G1RCoop\tools\diag_link.ps1`, and block inbound TCP 40004 in the Windows firewall.

What the mod still opens (by design): UDP 40001 (game traffic) and UDP 40002 (finding the host); TCP 40003 on the host, which hands the host's
save files to the joining guest (read-only, fixed file names, up to 4 hours after the game starts). Play only over a network you trust (Radmin VPN
with people you know).

**Reporting a vulnerability:** use the **Security → Report a vulnerability** button of this repository (private report). Please do not publish
exploit details in a public issue.

## Русский

**Версии 0.5.3, 0.5.4.5 и все более старые содержат серьёзную уязвимость. Обновитесь до 0.5.4.6 или новее.**

Что было не так: лаунчер при каждом запуске поднимал диагностическую службу на TCP-порту 40004 без пароля. Любой, кто мог достучаться до порта
(участник вашей сети Radmin VPN, сосед по локальной сети, а при пробросе порта и любой пользователь интернета), мог прислать файл, который мод
загружал в игру, то есть выполнить код на вашем ПК. Эта же служба отдавала имя компьютера, имя пользователя Windows, журналы и настройки
мода любому, кто спросит. Кроме того, в ядре мода (DLL) был зашит путь с именем пользователя Windows разработчика.

Что изменено в 0.5.4.6:

- диагностическая служба **выключена по умолчанию**; разработчик включает её в `settings.ini` (`diag_bridge = 1`, `diag_token = <16+ символов>`);
  без токена она не запускается, отклоняет любой запрос без токена и больше не сообщает имя компьютера и пользователя;
- в ядре больше нет ни одного пути с ПК разработчика.

Если обновиться сразу нельзя: закройте игру, удалите `%LOCALAPPDATA%\G1RCoop\tools\diag_link.ps1` и закройте входящий TCP 40004 в брандмауэре Windows.

Что мод открывает по-прежнему (так задумано): UDP 40001 (игровой обмен) и UDP 40002 (поиск хоста); TCP 40003 на хосте — он отдаёт сохранения
подключающемуся гостю (только чтение, фиксированные имена файлов, до 4 часов после запуска игры). Играйте только в сети, которой доверяете
(Radmin VPN с людьми, которых знаете).

**Сообщить об уязвимости:** кнопка **Security → Report a vulnerability** в этом репозитории (закрытое сообщение). Не публикуйте подробности
эксплуатации в открытых issue.
