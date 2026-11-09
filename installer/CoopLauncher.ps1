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
    $s = @{ settle = 4; port = 40001; role = 'auto'; save = 1; discovery = 40002; saveport = 40003; extra_args = ''; ready = 0 }
    $f = Join-Path $root 'settings.ini'
    if (-not (Test-Path -LiteralPath $f)) { return $s }
    foreach ($line in Get-Content -LiteralPath $f) {
        if ($line -match '^\s*settle_seconds\s*=\s*(\d+)') { $s.settle = [int]$matches[1] }
        elseif ($line -match '^\s*port\s*=\s*(\d+)') { $s.port = [int]$matches[1] }
        elseif ($line -match '^\s*discovery_port\s*=\s*(\d+)') { $s.discovery = [int]$matches[1] }
        elseif ($line -match '^\s*role\s*=\s*(\w+)') { $s.role = $matches[1].ToLower() }
        elseif ($line -match '^\s*save_transfer\s*=\s*(\d)') { $s.save = [int]$matches[1] }
        elseif ($line -match '^\s*extra_args\s*=\s*(.+)$') { $s.extra_args = $matches[1].Trim() }

    }
    return $s
}

# Is somebody already hosting? The same probe the in-game "Join co-op" button sends.
function Find-Host([int]$discoveryPort, [int]$timeoutMs = 2500) {
    try {
        $udp = New-Object System.Net.Sockets.UdpClient
        $udp.Client.ReceiveTimeout = 250
        $udp.EnableBroadcast = $true
        $probe = [Text.Encoding]::ASCII.GetBytes('COOP-WHO?')
        $targets = @('255.255.255.255', 'x.x.x.x')
        try {
            foreach ($a in [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
                foreach ($u in $a.GetIPProperties().UnicastAddresses) {
                    $ip = $u.Address.IPv4ToString()
                    if ($ip -and $ip -notlike '127.*' -and $ip -notlike '169.*') {
                        $targets += (($ip -split '\.')[0..2] -join '.') + '.255'
                    }
                }
            }
        } catch { }
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
                    $udp.Close()
                    return @{ ip = $ep.Address.ToString(); port = [int]$matches[1] }
                }
            } catch { }
        }
        $udp.Close()
    } catch { Log "discovery failed: $($_.Exception.Message)" }
    return $null
}


# Windows Defender deletes inject.exe (it exists to put a DLL into a running game). Without it nothing can be
# injected, so before launching we make sure a narrow exclusion for our own folder is in place.
function Ensure-DefenderExclusionForInject {
    try {
        $have = @((Get-MpPreference -ErrorAction Stop).ExclusionPath | Where-Object { $_ })
        if ($have -contains $root) { return $true }
        $cmd = "Add-MpPreference -ExclusionPath '$root'; exit 0"
        $pr = Start-Process powershell -Verb RunAs -Wait -PassThru -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$cmd`""
        Log "defender exclusion requested for $root, exit $($pr.ExitCode)"
        return ($pr.ExitCode -eq 0)
    } catch { Log "defender exclusion failed: $($_.Exception.Message)"; return $false }
}

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
    # the diagnostic bridge: the host can fetch this PC's logs without anybody starting anything
    try {
        $dl = Join-Path $tools 'diag_link.ps1'
        if (Test-Path -LiteralPath $dl) {
            $dlArgs = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$dl`" serve -Minutes 480"
            $dlProc = Start-Process powershell -ArgumentList $dlArgs -WindowStyle Hidden -PassThru
            Log "diag link serving on TCP 40004, pid $($dlProc.Id)"
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
        $readyText  = (T 'ready')  -replace "'", "''"
        $joinedText = (T 'joined') -replace "'", "''"
        $closeText  = (T 'close')  -replace "'", "''"
        $logPath    = (Join-Path $app 'coopdll.log') -replace "'", "''"
        $readyScript = @"
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
`$f = New-Object Windows.Forms.Form
`$f.Text = 'Gothic 1 Remake - co-op'
`$f.Size = New-Object Drawing.Size(430, 125)
`$f.TopMost = `$true
`$f.StartPosition = 'CenterScreen'
`$l = New-Object Windows.Forms.Label
`$l.Text = '$readyText'
`$l.Font = New-Object Drawing.Font('Segoe UI', 11)
`$l.AutoSize = `$false
`$l.Size = New-Object Drawing.Size(395, 45)
`$l.Location = New-Object Drawing.Point(12, 12)
`$f.Controls.Add(`$l)
`$b = New-Object Windows.Forms.Button
`$b.Text = '$closeText'
`$b.Size = New-Object Drawing.Size(110, 28)
`$b.Location = New-Object Drawing.Point(300, 48)
`$b.Add_Click({ `$f.Close() })
`$f.Controls.Add(`$b)
`$t = New-Object Windows.Forms.Timer
`$t.Interval = 1000
`$t.Add_Tick({
    try {
        `$tail = Get-Content -LiteralPath '$logPath' -Tail 100 -ErrorAction SilentlyContinue
        if (`$tail -match 'contact 1') { `$l.Text = '$joinedText'; `$l.ForeColor = [Drawing.Color]::DarkGreen; `$t.Stop(); `$c = New-Object Windows.Forms.Timer; `$c.Interval = 5000; `$c.Add_Tick({ `$c.Stop(); `$f.Close() }); `$c.Start() }
    } catch { }
})
`$t.Start()
[void]`$f.ShowDialog()
"@
        try {
            $tmpReady = Join-Path $env:TEMP ('g1r_ready_' + $PID + '.ps1')
            Set-Content -LiteralPath $tmpReady -Value $readyScript -Encoding UTF8
            Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$tmpReady`"" -WindowStyle Hidden | Out-Null
            Log 'ready window started'
        } catch { Log "ready window failed: $($_.Exception.Message)" }
    }
} catch {
    Show-Error "Непредвиденная ошибка: $($_.Exception.Message)`nЛог: $logFile"
    exit 1
}
