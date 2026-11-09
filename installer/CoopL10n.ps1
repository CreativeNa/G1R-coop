# Локализация сообщений лаунчера на все языки, которые есть в игре.
# Язык берётся из GameUserSettings.ini (m_DisplayLanguage), поэтому лаунчер говорит на языке игры.
# Чтобы добавить язык, достаточно добавить блок в $script:T - остальной файл язык не упоминает.
# The dialogs below need WinForms; load it here so this file works on its own, before any launcher code runs.
Add-Type -AssemblyName System.Windows.Forms

$script:T = @{}

$script:T['russian'] = @{
    title  = 'Gothic 1 Remake — кооператив'
    host   = "Вы — ХОСТ.{0}Игра запускается. Друг может подключаться, когда его лаунчер увидит этот ПК в сети."
    guest  = "Вы — ГОСТЬ.{0}Хост: {1}.{0}Сейчас заберу сохранения хоста и запущу игру."
    nohost = "Хост в сети не найден.{0}Если хостом будет этот ПК — нажмите «Да».{0}Если хостом должен быть друг — нажмите «Нет» и запустите после него."
    abort  = 'Запуск отменён: этот ПК не будет хостом.'
    saves  = "Не удалось получить сохранения хоста.{0}Играем с сохранениями этого ПК — миры могут различаться."
    fw     = "Похоже, брандмауэр Windows блокирует мод.{0}Разрешите Gothic 1 Remake в сетях «частная» и запустите снова."
    ready  = 'ГОТОВО: ждём друга…'
    joined = 'Друг подключился.'
    close  = 'Закрыть'
}

$script:T['english'] = @{
    title  = 'Gothic 1 Remake - co-op'
    host   = "You are the HOST.{0}The game starts now. Your friend can join once their launcher sees this PC."
    guest  = "You are the GUEST.{0}Host: {1}.{0}Fetching the host's saves, then starting the game."
    nohost = "No host found on the network.{0}Press Yes if THIS PC should host.{0}If your friend must host, press No and start after them."
    abort  = 'Launch cancelled: this PC will not host.'
    saves  = "Could not fetch the host's saves.{0}Starting with this PC's saves - the worlds may differ."
    fw     = "Windows Firewall seems to block the mod.{0}Allow Gothic 1 Remake on private networks and start again."
    ready  = 'READY: waiting for your friend...'
    joined = 'Your friend is connected.'
    close  = 'Close'
}

$script:T['german'] = @{
    title  = 'Gothic 1 Remake - Koop'
    host   = "Du bist der HOST.{0}Das Spiel startet. Dein Freund kann beitreten, sobald sein Launcher diesen PC sieht."
    guest  = "Du bist der GAST.{0}Host: {1}.{0}Spielstände werden geholt, dann startet das Spiel."
    nohost = "Kein Host im Netzwerk gefunden.{0}Ja, wenn DIESER PC hosten soll.{0}Nein, wenn dein Freund hostet - dann starte danach."
    abort  = 'Start abgebrochen: dieser PC hostet nicht.'
    saves  = "Spielstände des Hosts konnten nicht geholt werden.{0}Start mit den lokalen Spielständen - die Welten können abweichen."
    fw     = "Die Windows-Firewall blockiert den Mod offenbar.{0}Erlaube Gothic 1 Remake in privaten Netzen und starte erneut."
    ready  = 'BEREIT: warte auf deinen Freund...'
    joined = 'Dein Freund ist verbunden.'
    close  = 'Schließen'
}

$script:T['polish'] = @{
    title  = 'Gothic 1 Remake - kooperacja'
    host   = "Jesteś HOSTEM.{0}Gra się uruchamia. Znajomy dołączy, gdy jego launcher zobaczy ten komputer."
    guest  = "Jesteś GOŚCIEM.{0}Host: {1}.{0}Pobieram zapisy hosta i uruchamiam grę."
    nohost = "Nie znaleziono hosta w sieci.{0}Tak, jeśli TEN komputer ma być hostem.{0}Nie, jeśli hostem jest znajomy - uruchom później."
    abort  = 'Anulowano: ten komputer nie będzie hostem.'
    saves  = "Nie udało się pobrać zapisów hosta.{0}Gramy na zapisach tego komputera - światy mogą się różnić."
    fw     = "Zapora Windows blokuje mod.{0}Zezwól grze w sieciach prywatnych i uruchom ponownie."
    ready  = 'GOTOWE: czekam na znajomego...'
    joined = 'Znajomy połączony.'
    close  = 'Zamknij'
}

$script:T['french'] = @{
    title  = 'Gothic 1 Remake - coop'
    host   = "Vous êtes l'HÔTE.{0}Le jeu démarre. Votre ami pourra rejoindre quand son lanceur verra ce PC."
    guest  = "Vous êtes l'INVITÉ.{0}Hôte : {1}.{0}Je récupère ses sauvegardes, puis je lance le jeu."
    nohost = "Aucun hôte trouvé sur le réseau.{0}Oui si CE PC doit être l'hôte.{0}Non si votre ami héberge - lancez après lui."
    abort  = "Lancement annulé : ce PC ne sera pas l'hôte."
    saves  = "Impossible de récupérer les sauvegardes de l'hôte.{0}Démarrage avec celles de ce PC - les mondes peuvent différer."
    fw     = "Le pare-feu Windows bloque le mod.{0}Autorisez Gothic 1 Remake sur les réseaux privés et relancez."
    ready  = 'PRÊT : en attente de votre ami...'
    joined = 'Votre ami est connecté.'
    close  = 'Fermer'
}

$script:T['italian'] = @{
    title  = 'Gothic 1 Remake - coop'
    host   = "Sei l'HOST.{0}Il gioco parte. Il tuo amico potrà entrare quando il suo launcher vedrà questo PC."
    guest  = "Sei l'OSPITE.{0}Host: {1}.{0}Scarico i salvataggi dell'host e avvio il gioco."
    nohost = "Nessun host trovato in rete.{0}Sì se questo PC deve ospitare.{0}No se ospita il tuo amico - avvia dopo di lui."
    abort  = 'Avvio annullato: questo PC non ospiterà.'
    saves  = "Impossibile scaricare i salvataggi dell'host.{0}Avvio con quelli di questo PC - i mondi possono differire."
    fw     = "Il firewall di Windows blocca il mod.{0}Consenti Gothic 1 Remake sulle reti private e riavvia."
    ready  = 'PRONTO: attendo il tuo amico...'
    joined = 'Il tuo amico è connesso.'
    close  = 'Chiudi'
}

$script:T['spanish'] = @{
    title  = 'Gothic 1 Remake - coop'
    host   = "Eres el ANFITRIÓN.{0}El juego arranca. Tu amigo podrá entrar cuando su lanzador vea este PC."
    guest  = "Eres el INVITADO.{0}Anfitrión: {1}.{0}Descargo sus partidas y arranco el juego."
    nohost = "No se encontró anfitrión en la red.{0}Sí si este PC debe ser el anfitrión.{0}No si lo es tu amigo - inicia después."
    abort  = 'Inicio cancelado: este PC no será el anfitrión.'
    saves  = "No se pudieron descargar las partidas del anfitrión.{0}Jugamos con las de este PC - los mundos pueden diferir."
    fw     = "El firewall de Windows bloquea el mod.{0}Permite Gothic 1 Remake en redes privadas y reinicia."
    ready  = 'LISTO: esperando a tu amigo...'
    joined = 'Tu amigo está conectado.'
    close  = 'Cerrar'
}

$script:T['czech'] = @{
    title  = 'Gothic 1 Remake - coop'
    host   = "Jsi HOST.{0}Hra se spouští. Přítel se připojí, až jeho launcher uvidí tento PC."
    guest  = "Jsi GUEST (host).{0}Host: {1}.{0}Stahuji uložené pozice hosta a spouštím hru."
    nohost = "V síti nebyl nalezen host.{0}Ano, pokud má hostovat tento PC.{0}Ne, pokud hostuje přítel - spusť po něm."
    abort  = 'Spuštění zrušeno: tento PC nebude host.'
    saves  = "Uložené pozice hosta se nepodařilo stáhnout.{0}Hraje se s pozicemi tohoto PC - světy se mohou lišit."
    fw     = "Windows Firewall blokuje mod.{0}Povol Gothic 1 Remake v privátních sítích a spusť znovu."
    ready  = 'PŘIPRAVENO: čekám na přítele...'
    joined = 'Přítel je připojen.'
    close  = 'Zavřít'
}

$script:T['hungarian'] = @{
    title  = 'Gothic 1 Remake - koop'
    host   = "Te vagy a HOST.{0}A játék indul. A barátod akkor csatlakozhat, amikor a launcherе meglátja ezt a PC-t."
    guest  = "Te vagy a VENDÉG.{0}Host: {1}.{0}Letöltöm a host mentéseit, és indítom a játékot."
    nohost = "Nem található host a hálózaton.{0}Igen, ha ez a PC legyen a host.{0}Nem, ha a barátod hostol - utána indítsd."
    abort  = 'Indítás megszakítva: ez a PC nem lesz host.'
    saves  = "A host mentéseit nem sikerült letölteni.{0}Indulás a helyi mentésekkel - a világok eltérhetnek."
    fw     = "Úgy tűnik, a Windows tűzfal blokkolja a modot.{0}Engedélyezd a Gothic 1 Remake-et privát hálózaton és indítsd újra."
    ready  = 'KÉSZ: várom a barátod...'
    joined = 'A barátod csatlakozott.'
    close  = 'Bezárás'
}

$script:T['chinese'] = @{
    title  = 'Gothic 1 Remake - 合作'
    host   = "你是主机。{0}游戏正在启动。朋友的启动器发现此电脑后即可加入。"
    guest  = "你是客机。{0}主机：{1}。{0}正在获取主机的存档，然后启动游戏。"
    nohost = "网络中未找到主机。{0}如果由本机作主机，选«是»。{0}如果由朋友作主机，选«否»并在其后启动。"
    abort  = '已取消：本机不作主机。'
    saves  = "无法获取主机存档。{0}将使用本机存档游戏 - 世界可能不一致。"
    fw     = "Windows 防火墙似乎阻止了模组。{0}请在«专用网络»中允许 Gothic 1 Remake 并重新启动。"
    ready  = '就绪：等待朋友...'
    joined = '朋友已连接。'
    close  = '关闭'
}

function Get-GameLanguage {
    $ini = Join-Path $env:LOCALAPPDATA 'G1R\Saved\Config\Windows\GameUserSettings.ini'
    try {
        $m = Select-String -LiteralPath $ini -Pattern '^m_DisplayLanguage=(\S+)' -ErrorAction Stop | Select-Object -First 1
        if ($m) { return $m.Matches[0].Groups[1].Value.ToLower() }
    } catch { }
    return 'english'
}

$script:LangCode = Get-GameLanguage
$script:L = if ($script:T.ContainsKey($script:LangCode)) { $script:T[$script:LangCode] } else { $script:T['english'] }

# T 'key' [arg1] [arg2]: {0} and {1} are newlines or the host address, depending on the message
function T([string]$key, [string]$a1 = '', [string]$a2 = '') {
    return ([string]$script:L[$key]) -f $a1, $a2
}
function Show-Info([string]$text) { [void][System.Windows.Forms.MessageBox]::Show($text, $script:L['title'], 'OK', 'Information') }
function Show-Question([string]$text) {
    $r = [System.Windows.Forms.MessageBox]::Show($text, $script:L['title'], 'YesNo', 'Question')
    return ($r -eq 'Yes')
}
