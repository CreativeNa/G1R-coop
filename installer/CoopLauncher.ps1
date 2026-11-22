<#
    CoopLauncher: starts Gothic 1 Remake, decides whether this PC is the host or the guest, exchanges the save game
    and injects the co-op core. This is what the desktop shortcut runs. Nothing is written into the game folder.

    The decision is automatic:
      * ask the network whether somebody is already hosting (same UDP 40002 probe the in-game button uses);
      * if a host answered  -> we are the guest: fetch his save games, then connect to him;
      * if nobody answered  -> we are the host: serve our save games and start hosting.
    settings.ini can force it: role = auto | host | guest, and save_transfer = 1 | 0.
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSCommandPath
$app = Join-Path $root 'app'
$tools = Join-Path $root 'tools'
$logs = Join-Path $root 'logs'
New-Item -ItemType Directory -Force $logs | Out-Null
$logFile = Join-Path $logs 'launcher.log'
function Log([string]$t) { Add-Content -LiteralPath $logFile -Value ("[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $t) -Encoding utf8 }

# localized dialogs: the language is the game's own (see CoopL10n.ps1)
. (Join-Path $PSScriptRoot 'CoopL10n.ps1')
if (-not (Get-Command T -ErrorAction SilentlyContinue)) { throw 'CoopL10n.ps1 is missing next to the launcher' }

# Self-test: the installer and the test scripts verify the launcher without opening a window or starting the game.
if ($env:G1RCOOP_SELFTEST -eq '1') {
    Log ("selftest: lang=" + $script:LangCode + ", T=" + (T 'ready'))
    Write-Output ("selftest ok: " + $script:LangCode + " | " + (T 'ready'))
    exit 0
}

function Show-Error([string]$text) {
    Log "ERROR $text"
    Add-Type -AssemblyName System.Windows.Forms

    $title = if ($script:L) { $script:L['title'] } else { 'Gothic 1 Remake' }
    [void][System.Windows.Forms.MessageBox]::Show($text, $title, 'OK', 'Error')
}

function Read-Settings {
    $s = @{ settle = 4; port = 40001; role = 'auto'; save = 1; discovery = 40002; saveport = 40003; extra_args = ''; ready = 0; diag_bridge = 0; diag_token = '' }
    $f = Join-Path $root 'settings.ini'
    if (-not (Test-Path -LiteralPath $f)) { return $s }
    foreach ($line in Get-Content -LiteralPath $f) {
        if ($line -match '^\s*settle_seconds\s*=\s*(\d+)') { $s.settle = [int]$matches[1] }
        elseif ($line -match '^\s*port\s*=\s*(\d+)') { $s.port = [int]$matches[1] }
        elseif ($line -match '^\s*discovery_port\s*=\s*(\d+)') { $s.discovery = [int]$matches[1] }
        elseif ($line -match '^\s*role\s*=\s*(\w+)') { $s.role = $matches[1].ToLower() }
        elseif ($line -match '^\s*save_transfer\s*=\s*(\d)') { $s.save = [int]$matches[1] }
        elseif ($line -match '^\s*extra_args\s*=\s*(.+)$') { $s.extra_args = $matches[1].Trim() }
        elseif ($line -match '^\s*diag_bridge\s*=\s*(\d)') { $s.diag_bridge = [int]$matches[1] }
        elseif ($line -match '^\s*diag_token\s*=\s*(\S+)') { $s.diag_token = $matches[1] }

    }
    return $s
}

# Is somebody already hosting? The same probe the in-game "Join co-op" button sends.
# Only a private VPN room or a home network is a place to play in: loopback, 10/8, 172.16/12, 192.168/16, 169.254/16, Radmin 26/8, Hamachi 25/8,
# Tailscale/CGNAT 100.64/10. network_any.txt in the app folder switches the check off.
function Test-AllowedAddress([System.Net.IPAddress]$ip) {
    if (Test-Path -LiteralPath (Join-Path $app 'network_any.txt')) { return $true }
    if ($ip.IsIPv4MappedToIPv6) { $ip = $ip.MapToIPv4() }
    if ([System.Net.IPAddress]::IsLoopback($ip)) { return $true }
    if ($ip.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork) { return $false }
    $b = $ip.GetAddressBytes(); $a1 = [int]$b[0]; $c1 = [int]$b[1]
    return ($a1 -eq 10) -or ($a1 -eq 172 -and $c1 -ge 16 -and $c1 -le 31) -or ($a1 -eq 192 -and $c1 -eq 168) -or ($a1 -eq 169 -and $c1 -eq 254) -or ($a1 -eq 26) -or ($a1 -eq 25) -or ($a1 -eq 100 -and $c1 -ge 64 -and $c1 -le 127)
}

function Find-Host([int]$discoveryPort, [int]$timeoutMs = 2500) {
    try {
        $udp = New-Object System.Net.Sockets.UdpClient
        $udp.Client.ReceiveTimeout = 250
        $udp.EnableBroadcast = $true
        $probe = [Text.Encoding]::ASCII.GetBytes('COOP-WHO?')
        $targets = @('255.255.255.255')
        try {
            foreach ($a in [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
                foreach ($u in $a.GetIPProperties().UnicastAddresses) {
                    if ($u.Address.AddressFamily -ne [System.Net.Sockets.AddressFamily]::InterNetwork -or -not $u.IPv4Mask) { continue }
                    $ipb = $u.Address.GetAddressBytes(); $mb = $u.IPv4Mask.GetAddressBytes()
                    if ($ipb[0] -eq 127 -or ($ipb[0] -eq 169 -and $ipb[1] -eq 254)) { continue }
                    $bc = for ($i = 0; $i -lt 4; $i++) { $ipb[$i] -bor (255 -bxor $mb[$i]) }          # the directed broadcast of that network (Radmin is a /8)
                    $targets += ($bc -join '.')
                }
            }        } catch { }
        $deadline = (Get-Date).AddMilliseconds($timeoutMs)
        $sent = $false
        while ((Get-Date) -lt $deadline) {
            if (-not $sent) {
                foreach ($t in ($targets | Select-Object -Unique)) {
                    try { [void]$udp.Send($probe, $probe.Length, $t, $discoveryPort) } catch { }
                }
                $sent = $true
            }
            try {
                $ep = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
                $data = $udp.Receive([ref]$ep)
                $text = [Text.Encoding]::ASCII.GetString($data)
                if ($text -match '^COOP-HOST\s+\d+\s+(\d+)') {
                    if (-not (Test-AllowedAddress $ep.Address)) { Log "discovery: ignored an answer from $($ep.Address) (address range not allowed)"; continue }
                    $udp.Close()
                    return @{ ip = $ep.Address.ToString(); port = [int]$matches[1] }
                }
            } catch { }
        }
        $udp.Close()
    } catch { Log "discovery failed: $($_.Exception.Message)" }
    return $null
}


# (the launcher never touches Windows Defender: the installer asks once, see Setup.ps1 and docs\ANTIVIRUS.md)

try {

# Returns $true when the game executable has an inbound allow rule (or when the rules cannot be read at all).
function Test-ModFirewall([string]$gameExe) {
    try {
        $rules = Get-NetFirewallRule -Direction Inbound -ErrorAction Stop |
                 Where-Object { $_.Action -eq 'Allow' -and $_.Enabled -eq 'True' } |
                 ForEach-Object { $_ | Get-NetFirewallApplicationFilter -ErrorAction SilentlyContinue } |
                 Where-Object { $_.Program -and $_.Program -ieq $gameExe }
        return [bool]$rules
    } catch { return $true }
}

    Log 'launcher start'
    $cfg = Read-Settings
    . (Join-Path $root 'FindGame.ps1')

    $exe = $null
    $gameTxt = Join-Path $root 'game.txt'
    if (Test-Path -LiteralPath $gameTxt) { $exe = (Get-Content -LiteralPath $gameTxt -Raw).Trim() }
    if (-not $exe -or -not (Test-Path -LiteralPath $exe)) {
        $exe = Find-GothicExe
        if (-not $exe) { Show-Error "Gothic 1 Remake не найдена. Запустите Setup и укажите папку игры (в ней есть папка G1R)."; exit 1 }
        Set-Content -LiteralPath $gameTxt -Value $exe -Encoding utf8
    }

    $core = Get-ChildItem -LiteralPath $app -Filter 'coopdll_*.dll' | Sort-Object Name -Descending | Select-Object -First 1
    if (-not $core) { Show-Error "Файлы мода не найдены в $app. Запустите установщик ещё раз (ремонт)."; exit 1 }
    $inject = Join-Path $app 'inject.exe'
    # the launcher never touches Windows Defender: the installer asks once, and ANTIVIRUS.md explains the manual route
    if (-not (Test-Path -LiteralPath $inject)) {
        Show-Error "inject.exe отсутствует в $app — его удалил Windows Defender, хотя исключение добавлено.`nОткройте «Безопасность Windows → Защита от вирусов → Журнал защиты», восстановите файл и запустите снова.`nИли переустановите мод: Setup.cmd."
        exit 1
    }

    if (Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue) {
        Show-Error "Игра уже запущена. Закройте её и запустите кооператив этим ярлыком."
        exit 1
    }

    # ---- who are we?
    $role = $cfg.role
    $hostInfo = $null
    if ($role -eq 'auto') {
        $hostInfo = Find-Host $cfg.discovery
        $role = if ($hostInfo) { 'guest' } else { 'host' }
    } elseif ($role -eq 'guest') {
        # this PC is always the guest: wait for the host instead of silently becoming one, because two hosts
        # never connect to each other and the player would just sit in an empty session
        for ($try = 1; $try -le 10 -and -not $hostInfo; $try++) {
            $hostInfo = Find-Host $cfg.discovery -timeoutMs 900
            if (-not $hostInfo) { Start-Sleep -Milliseconds 400 }
        }
        if (-not $hostInfo) {
            Show-Error "Хост не найден в сети. Запустите игру на компьютере хоста (ярлыком) и повторите этот запуск.`nЭта копия настроена как гость (role = guest в settings.ini)."
            exit 1
        }
    }
    Log "role: $role" + $(if ($hostInfo) { " (host $($hostInfo.ip):$($hostInfo.port))" } else { '' })

    # ---- firewall: a blocked mod looks exactly like "the friend never appears"
    if (-not (Test-ModFirewall $exe)) { Log "firewall: no inbound allow rule for $exe"; Show-Info (T 'fw' ([Environment]::NewLine) '') }

    # ---- role: no dialog, only the log (docs/HOW_TO_PLAY.md explains the flow)


    # no dialog here: the role and the address are written to the log, the guide explains the flow

    # ---- the save game has to be the same on both PCs
    $savesync = Join-Path $tools 'savesync.ps1'
    if ($cfg.save -eq 1 -and (Test-Path -LiteralPath $savesync)) {
        if ($role -eq 'guest' -and $hostInfo) {
            Log "fetching the save games from $($hostInfo.ip)"
            # A failed fetch must not stop the launch: the player can start with the saves already on this PC and the
            # host can send them on the next run. Aborting here left the guest with a dialog and no game at all.
            try {
                $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $savesync fetch -Peer $hostInfo.ip -Port $cfg.saveport 2>&1
                Log ("savesync fetch: " + (($out | Out-String).Trim() -replace '\s+', ' '))
                if ($LASTEXITCODE -ne 0) {
                    Log "savesync fetch returned $LASTEXITCODE - starting with the local saves"
                    Show-Info (T 'saves' ([Environment]::NewLine) '')
                }
            } catch {
                Log "savesync fetch failed ($($_.Exception.Message)) - starting with the local saves"
                Show-Info (T 'saves' ([Environment]::NewLine) '')
            }
        } elseif ($role -eq 'host') {
            Log "serving the save games on TCP $($cfg.saveport) for the guest"
            $serveArgs = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$savesync`" serve -Port $($cfg.saveport) -Minutes 240"
            $serve = Start-Process powershell -ArgumentList $serveArgs -WindowStyle Hidden -PassThru
            $serve.Id | Set-Content -LiteralPath (Join-Path $root 'savesync.pid') -Encoding ascii
        }
    } else { Log 'save transfer is off or savesync.ps1 is missing' }

    # ---- the main menu must stay on screen: that is where the Co-op buttons are
    $staleAutoload = Join-Path $app 'autoload.txt'
    if (Test-Path -LiteralPath $staleAutoload) { Remove-Item -LiteralPath $staleAutoload -Force -ErrorAction SilentlyContinue; Log 'removed an old autoload.txt so the menu stays open' }

    # ---- the connection the core picks up at load (no button needed)
    if ($role -eq 'guest' -and -not $hostInfo) { Show-Error 'Хост не найден. Эта копия настроена как гость — запустите хост первым.'; exit 1 }
    $connect = if ($role -eq 'guest' -and $hostInfo) { "join $($hostInfo.ip) $($hostInfo.port)" } else { "host $($cfg.port)" }
    Set-Content -LiteralPath (Join-Path $app 'connect.txt') -Value $connect -Encoding ascii
    Log "connect.txt: $connect"

    # autoload was removed on purpose: the mod must always stop in the main menu, because that is where the Co-op button is.
    Remove-Item -LiteralPath (Join-Path $app 'autoload.txt') -Force -ErrorAction SilentlyContinue

    # ---- the black box starts with the game and stops by itself afterwards
    try {
        $bb = Join-Path $tools 'blackbox.ps1'
        if (Test-Path -LiteralPath $bb) {
            $bbArgs = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$bb`" " +
                      "-Interval 10 -NoProbe -ExitWhenNoGame -QuietPass " +
                      "-LogPath `"$(Join-Path $app 'coopdll.log')`" -OutDir `"$logs`""
            $bbProc = Start-Process powershell -ArgumentList $bbArgs -WindowStyle Hidden -PassThru
            Log "black box started, pid $($bbProc.Id)"
        }
    } catch { Log "black box failed to start: $($_.Exception.Message)" }

    # -no-intro-cinematic and -nosplash skip the publisher logos, the intro movie and the splash screen, so the main
    # menu (and the co-op buttons) is there as soon as the engine has loaded.
    $seat = if ($role -eq 'guest') { 1 } else { 0 }
    $gameArgs = "-no-intro-cinematic -nosplash -CoopSeat=$seat"
    if ($cfg.extra_args) { $gameArgs = "$gameArgs $($cfg.extra_args)" }
    # the diagnostic bridge is OFF by default. It opens TCP 40004 (logs out, module files in), so it is only for a developer who sets
    # settings.ini: diag_bridge = 1 and diag_token = <a secret of 16+ characters>; without a token it never starts (the same token is needed to talk to it)
    try {
        $dl = Join-Path $tools 'diag_link.ps1'
        if ([int]$cfg.diag_bridge -ne 1) { Log 'diag link is off (settings.ini diag_bridge = 0)' }
        elseif (-not $cfg.diag_token -or $cfg.diag_token.Length -lt 16) { Log 'diag link NOT started: diag_token in settings.ini must be at least 16 characters' }
        elseif (Test-Path -LiteralPath $dl) {
            $dlArgs = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$dl`" serve -Minutes 480 -Token `"$($cfg.diag_token)`""
            $dlProc = Start-Process powershell -ArgumentList $dlArgs -WindowStyle Hidden -PassThru
            Log "diag link serving on TCP 40004 with a token, pid $($dlProc.Id)"
        } else { Log 'diag link is not installed' }
    } catch { Log "diag link failed to start: $($_.Exception.Message)" }

    Log "starting $exe ($gameArgs)"
    $p = Start-Process -FilePath $exe -ArgumentList $gameArgs -WorkingDirectory (Split-Path -Parent $exe) -PassThru
    Log "pid $($p.Id), waiting $($cfg.settle) s before injecting"
    Start-Sleep -Seconds $cfg.settle
    if (-not (Get-Process -Id $p.Id -ErrorAction SilentlyContinue)) { Show-Error "Игра закрылась до подключения мода. Запустите её один раз из Steam и проверьте, что она работает."; exit 1 }

    Log "injecting $($core.Name) into $($p.Id)"
    $out = & $inject $p.Id $core.FullName 2>&1
    Log "inject output: $out"
    if ($LASTEXITCODE -ne 0) { Show-Error "Мод не смог подключиться к игре (inject exit $LASTEXITCODE). Лог: $logFile"; exit 1 }
    Log "done ($role)"

    # ---- ready window for the host: the player should not have to read the window title to know the friend may join
    if ($role -eq 'host' -and $cfg.ready -ne 0) {
        try {
            $env:G1R_READY_TEXT = (T 'ready'); $env:G1R_JOINED_TEXT = (T 'joined'); $env:G1R_CLOSE_TEXT = (T 'close'); $env:G1R_LOG_PATH = (Join-Path $app 'coopdll.log')
            $rw = Join-Path $root 'ReadyWindow.ps1'
            if (Test-Path -LiteralPath $rw) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$rw`"" -WindowStyle Hidden | Out-Null; Log 'ready window started' } else { Log 'ready window script is not installed' }
        } catch { Log "ready window failed: $($_.Exception.Message)" }
    }
} catch {
    Show-Error "Непредвиденная ошибка: $($_.Exception.Message)`nЛог: $logFile"
    exit 1
}
