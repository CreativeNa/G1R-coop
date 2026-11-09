# Diagnostic bridge between the two PCs: the guest serves its mod logs, the host fetches them, so the person
# running the host can read both sides without copying text by hand.
#
#   guest PC:  .\tools\diag_link.ps1 serve                 (leave it running while you play)
#   host PC:   .\tools\diag_link.ps1 fetch -Peer 26.x.x.x  (writes native\build\guest_report_<time>.json)
#
# Read-only: it sends the tail of the logs and a few state files, nothing is written on the guest. TCP 40004 by
# default; -Token <word> on both sides keeps a reachable port from answering strangers.
param(
    [Parameter(Mandatory = $true, Position = 0)][ValidateSet('serve', 'fetch', 'upload')][string]$Mode,
    [string]$Peer = '127.0.0.1',
    [int]$Port = 40004,
    [string]$Token = '',
    [int]$Minutes = 240,
    [int]$LogLines = 2000,
    [string]$File = ''
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

function Collect-State([int]$lines) {
    $app = Join-Path $env:LOCALAPPDATA 'G1RCoop\app'
    $logs = Join-Path $env:LOCALAPPDATA 'G1RCoop\logs'
    $state = [ordered]@{
        time        = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        host        = $env:COMPUTERNAME
        user        = $env:USERNAME
        processes   = @()
        coopdll_log = ''
        launcher    = ''
        install     = ''
        settings    = ''
        connect     = ''
        modules     = @()
        game        = ''
    }
    foreach ($p in Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue) {
        $state.processes += [ordered]@{ pid = $p.Id; title = $p.MainWindowTitle; started = $p.StartTime.ToString('HH:mm:ss'); memory_mb = [math]::Round($p.WorkingSet64 / 1MB) }
    }
    $gl = Join-Path $root 'native\build\game.txt'
    if (Test-Path $gl) { $state.game = (Get-Content $gl -Raw).Trim() }
    $gameTxt = Join-Path $env:LOCALAPPDATA 'G1RCoop\game.txt'
    if (Test-Path $gameTxt) { $state.game = (Get-Content $gameTxt -Raw).Trim() }
    $coreLog = Join-Path $app 'coopdll.log'
    if (Test-Path $coreLog) { $state.coopdll_log = (Get-Content $coreLog -Tail $lines -ErrorAction SilentlyContinue) -join "`n" }
    $l = Join-Path $logs 'launcher.log'
    if (Test-Path $l) { $state.launcher = (Get-Content $l -Tail 60 -ErrorAction SilentlyContinue) -join "`n" }
    $i = Join-Path $logs 'install.log'
    if (Test-Path $i) { $state.install = (Get-Content $i -Tail 40 -ErrorAction SilentlyContinue) -join "`n" }
    $sm = Join-Path $env:LOCALAPPDATA 'G1RCoop\settings.ini'
    if (Test-Path $sm) { $state.settings = [string](Get-Content -LiteralPath $sm -Raw) }
    $cn = Join-Path $app 'connect.txt'
    if (Test-Path $cn) { $state.connect = ([string](Get-Content -LiteralPath $cn -Raw)).Trim() }
    $md = Join-Path $app 'modules'
    if (Test-Path $md) {
        foreach ($f in Get-ChildItem $md -Filter *.dll | Where-Object { $_.Name -notmatch '_\d+_\d+' }) {
            $sha = try { (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash.Substring(0, 16) } catch { '' }
                $state.modules += [ordered]@{ name = $f.Name; time = $f.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'); size = $f.Length; sha = $sha }
        }
    }
    return $state
}

if ($Mode -eq 'upload') {
    # Push one freshly built module to the guest. Everything is raw bytes: a StreamReader here buffered part of the file
    # and swallowed its first bytes, which left both sides waiting (that was the hang).
    if (-not $File -or -not (Test-Path -LiteralPath $File)) { "upload: -File <module.dll> is required"; exit 1 }
    $name = Split-Path $File -Leaf
    $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $File))
    $client = New-Object System.Net.Sockets.TcpClient
    $client.ReceiveTimeout = 20000
    $client.Connect($Peer, $Port)
    $stream = $client.GetStream()
    $hdr = [System.Text.Encoding]::ASCII.GetBytes("PUT $Token|$name|$($bytes.Length)`n")
    $stream.Write($hdr, 0, $hdr.Length)
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Flush()
    $buf = New-Object byte[] 256
    $got = 0
    try { $got = $stream.Read($buf, 0, $buf.Length) } catch { $got = 0 }
    $answer = if ($got -gt 0) { [System.Text.Encoding]::ASCII.GetString($buf, 0, $got).Trim() } else { '(no answer)' }
    $client.Close()
    "upload ${name} -> ${Peer}:$Port : $answer"
    if ($answer -like 'OK*') { exit 0 } else { exit 1 }
}

if ($Mode -eq 'serve') {
    $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $Port)
    $listener.Start()
    "diag_link: serving on TCP $Port for $Minutes min - leave this window open"
    "this PC: " + (($root) -replace '\\', '\')
    $deadline = (Get-Date).AddMinutes($Minutes)
    while ((Get-Date) -lt $deadline) {
        if (-not $listener.Pending()) { Start-Sleep -Milliseconds 300; continue }
        $client = $listener.AcceptTcpClient()
        try {
            $stream = $client.GetStream()
            $client.ReceiveTimeout = 20000
            # read one line manually: a StreamReader would buffer part of an uploaded file
            $sb = New-Object System.Text.StringBuilder
            while ($true) {
                $bb = $stream.ReadByte()
                if ($bb -lt 0 -or $bb -eq 10) { break }
                if ($bb -ne 13) { [void]$sb.Append([char]$bb) }
                if ($sb.Length -gt 512) { break }
            }
            $request = $sb.ToString()
            if ($request -like 'PUT *') {
                # payload: "PUT <token>|<module.dll>|<size>\n" followed by exactly <size> raw bytes
                $parts = $request.Substring(4).Split('|')
                $tok = ''; $name = ''; $size = 0
                if ($parts.Count -ge 3) { $tok = $parts[0]; $name = $parts[1]; [void][int]::TryParse($parts[2], [ref]$size) }
                elseif ($parts.Count -eq 2) { $name = $parts[0]; [void][int]::TryParse($parts[1], [ref]$size) }
                if ($Token -and $tok -ne $Token) {
                    $b0 = [System.Text.Encoding]::ASCII.GetBytes("NO bad token`n"); $stream.Write($b0,0,$b0.Length); $stream.Flush()
                    "  refused upload: bad token"; $client.Close(); continue
                }
                $allowed = @('anim.dll','equip.dll','menu.dll','npc.dll','pose.dll','probe.dll','story.dll')
                if ($allowed -notcontains $name -or $size -le 0 -or $size -gt 4MB) {
                    $b1 = [System.Text.Encoding]::ASCII.GetBytes("NO bad module or size`n"); $stream.Write($b1,0,$b1.Length); $stream.Flush()
                    "  refused upload: '$name' size $size"; $client.Close(); continue
                }
                $buf = New-Object byte[] $size
                $read = 0
                while ($read -lt $size) {
                    $n = $stream.Read($buf, $read, $size - $read)
                    if ($n -le 0) { break }
                    $read += $n
                }
                if ($read -eq $size) {
                    $modDir = Join-Path (Join-Path (Join-Path $env:LOCALAPPDATA 'G1RCoop') 'app') 'modules'
                    New-Item -ItemType Directory -Force $modDir | Out-Null
                    [System.IO.File]::WriteAllBytes((Join-Path $modDir $name), $buf)
                    $ok = [System.Text.Encoding]::ASCII.GetBytes("OK $name $size`n"); $stream.Write($ok,0,$ok.Length); $stream.Flush()
                    "  installed $name ($size bytes) from $($client.Client.RemoteEndPoint)"
                } else {
                    $no = [System.Text.Encoding]::ASCII.GetBytes("NO short read $read/$size`n"); $stream.Write($no,0,$no.Length); $stream.Flush()
                    "  short read for ${name}: $read/$size"
                }
                $client.Close(); continue
            }
            if ($Token -and $request -ne "DIAG $Token") { "  refused: bad token"; $client.Close(); continue }
            $json = (Collect-State $LogLines) | ConvertTo-Json -Depth 5 -Compress
            $writer = New-Object System.IO.StreamWriter($stream)
            $writer.WriteLine("OK")
            $writer.WriteLine($json)
            $writer.Flush()
            "  served a report to $($client.Client.RemoteEndPoint)"
        } catch {
            "  error while serving: $($_.Exception.Message)"
        } finally {
            $client.Close()
        }
    }
    $listener.Stop()
    "diag_link: stopped"
    exit 0
}

# ---- fetch
$client = New-Object System.Net.Sockets.TcpClient
try {
    $ok = $client.ConnectAsync($Peer, $Port).Wait(4000)
    if (-not $ok -or -not $client.Connected) { throw "no answer from ${Peer}:$Port" }
} catch {
    "cannot reach ${Peer}:$Port - " + $_.Exception.Message
    "on the GUEST: the diag link must be running (start the game through the shortcut, it starts by itself), and"
    "the firewall must allow TCP $Port on that PC:  .\tools\firewall_coop.ps1 -Action add"
    exit 1
}
$stream = $client.GetStream()
$client.ReceiveTimeout = 15000
$writer = New-Object System.IO.StreamWriter($stream)
$writer.AutoFlush = $true
$writer.WriteLine($(if ($Token) { "DIAG $Token" } else { "DIAG" }))
$writer.Flush()
$reader = New-Object System.IO.StreamReader($stream)
$line = $reader.ReadLine()
if ($line -ne 'OK') { "the guest refused: $line"; $client.Close(); exit 1 }
$json = $reader.ReadLine()
$client.Close()
$outDir = Join-Path $root 'native\build'
New-Item -ItemType Directory -Force $outDir | Out-Null
$file = Join-Path $outDir ("guest_report_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.json')
$json | Set-Content -LiteralPath $file -Encoding utf8
$state = $json | ConvertFrom-Json
"guest report saved: $file"
"host    : $($state.host) / $($state.user)"
"time    : $($state.time)"
"process : " + ((@($state.processes) | ForEach-Object { "pid $($_.pid) [$($_.title)] $($_.memory_mb) MB" }) -join '; ')
"connect : " + ($(if ($state.connect) { ([string]$state.connect).Trim() } else { '-' }))
"modules : " + ((@($state.modules) | ForEach-Object { "$($_.name) $($_.time)" }) -join ', ')
"core log lines: " + (($state.coopdll_log -split "`n").Count)
