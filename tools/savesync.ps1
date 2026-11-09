# Copies the host's save games to the guest over a plain TCP connection (no game, no injection involved). Run it BEFORE both players load the game.
#   host PC:   .\tools\savesync.ps1 serve                       (leave it running; it serves for -Minutes minutes; press the game's save (F5) first)
#   guest PC:  .\tools\savesync.ps1 fetch -Peer <host IP>        (backs up the guest's own saves, then replaces them with the host's)
# Port: TCP 40003 by default (-Port). Same network rules as the game traffic: a VPN (Radmin, ZeroTier) or a forwarded port. Windows Firewall may ask: allow it
# for private networks (this script changes no firewall or security setting).
# -Token <word>: the guest must send the same word (keeps strangers out when the port is reachable from the internet).
# -SaveDir: the save folder (default %LOCALAPPDATA%\G1R\Saved\SaveGames). The guest's old saves are copied to "<SaveDir>_backup_<time>" first.
param(
    [Parameter(Mandatory = $true, Position = 0)][ValidateSet("serve", "fetch")][string]$Mode,
    [string]$Peer = "127.0.0.1",
    [int]$Port = 40003,
    [string]$SaveDir = (Join-Path $env:LOCALAPPDATA "G1R\Saved\SaveGames"),
    [string]$Token = "",
    [int]$Minutes = 240
)
$ErrorActionPreference = "Stop"

function Send-Line($stream, [string]$text) { $b = [Text.Encoding]::ASCII.GetBytes($text + "`n"); $stream.Write($b, 0, $b.Length) }
function Read-Line($stream) {
    $sb = New-Object Text.StringBuilder
    while ($true) { $v = $stream.ReadByte(); if ($v -lt 0) { throw "connection closed" }; if ($v -eq 10) { break }; if ($v -ne 13) { [void]$sb.Append([char]$v) }; if ($sb.Length -gt 400) { throw "bad header" } }
    return $sb.ToString()
}
function Read-Exact($stream, [long]$count) {
    $buf = New-Object byte[] $count; $got = 0
    while ($got -lt $count) { $n = $stream.Read($buf, $got, [int][Math]::Min(1048576, $count - $got)); if ($n -le 0) { throw "connection closed in the middle of a file" }; $got += $n }
    return , $buf
}

if ($Mode -eq "serve") {
    if (-not (Test-Path $SaveDir)) { throw "no save folder: $SaveDir" }
    $listener = New-Object Net.Sockets.TcpListener([Net.IPAddress]::Any, $Port)
    $listener.Start()
    "serving $SaveDir on TCP $Port for $Minutes minutes (Ctrl+C to stop)"
    $end = (Get-Date).AddMinutes($Minutes)
    while ((Get-Date) -lt $end) {
        if (-not $listener.Pending()) { Start-Sleep -Milliseconds 300; continue }
        $client = $listener.AcceptTcpClient(); $stream = $client.GetStream(); $stream.ReadTimeout = 15000; $stream.WriteTimeout = 60000
        try {
            $hello = Read-Line $stream
            if ($hello -ne ("HELLO " + $Token)) { Send-Line $stream "ERR token"; "refused a client (wrong token)"; continue }
            $files = @(Get-ChildItem $SaveDir -Filter *.sav -File | Where-Object { $_.Name -match "^(G1R-\d+|PersistentDataList|Profile_\d+_Screenshots)\.sav$" })          # never the guest's own settings (EnhancedInputUserSettings = key bindings)
            $blobs = @(); foreach ($f in $files) { $fs = [IO.File]::Open($f.FullName, "Open", "Read", "ReadWrite"); try { $ms = New-Object IO.MemoryStream; $fs.CopyTo($ms); $blobs += , $ms.ToArray() } finally { $fs.Dispose() } }
            Send-Line $stream ("SAVESYNC1 " + $files.Count)
            for ($i = 0; $i -lt $files.Count; $i++) { Send-Line $stream ($files[$i].Name + "|" + $blobs[$i].Length + "|" + $files[$i].LastWriteTimeUtc.Ticks) }
            for ($i = 0; $i -lt $files.Count; $i++) { $stream.Write($blobs[$i], 0, $blobs[$i].Length) }
            $stream.Flush()
            "sent $($files.Count) files, $([math]::Round(($blobs | ForEach-Object { $_.Length } | Measure-Object -Sum).Sum / 1MB, 2)) MB, newest: $(($files | Sort-Object LastWriteTime -Descending | Select-Object -First 1).Name)"
        } catch { "client error: $($_.Exception.Message)" } finally { $client.Close() }
    }
    $listener.Stop(); return
}

# ---- fetch ----
$client = New-Object Net.Sockets.TcpClient
$iar = $client.BeginConnect($Peer, $Port, $null, $null)
if (-not $iar.AsyncWaitHandle.WaitOne(8000)) { throw "cannot reach ${Peer}:$Port (is the host running 'savesync.ps1 serve', is the port open?)" }
$client.EndConnect($iar)
$stream = $client.GetStream(); $stream.ReadTimeout = 60000
Send-Line $stream ("HELLO " + $Token)
$head = Read-Line $stream
if ($head -notmatch "^SAVESYNC1 (\d+)$") { throw "the host answered: $head" }
$count = [int]$Matches[1]
$meta = @(); for ($i = 0; $i -lt $count; $i++) { $p = (Read-Line $stream).Split("|"); $meta += [pscustomobject]@{ Name = $p[0]; Size = [long]$p[1]; Ticks = [long]$p[2] } }
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("savesync_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory $tmp | Out-Null
foreach ($m in $meta) {
    if ($m.Name -notmatch "^(G1R-\d+|PersistentDataList|Profile_\d+_Screenshots)\.sav$") { throw "refusing an unexpected file name: $($m.Name)" }
    [IO.File]::WriteAllBytes((Join-Path $tmp $m.Name), (Read-Exact $stream $m.Size))
}
$client.Close()
"received $count files into a temporary folder; replacing the saves in $SaveDir"
if (Test-Path $SaveDir) { $bk = $SaveDir + "_backup_" + (Get-Date -Format "yyyyMMdd_HHmmss"); Copy-Item $SaveDir $bk -Recurse; "your old saves are in $bk" } else { New-Item -ItemType Directory -Force $SaveDir | Out-Null }
foreach ($m in $meta) {
    $dst = Join-Path $SaveDir $m.Name
    Copy-Item (Join-Path $tmp $m.Name) $dst -Force
    (Get-Item $dst).LastWriteTimeUtc = [DateTime]::new($m.Ticks, [DateTimeKind]::Utc)           # "Continue" loads the newest file: keep the host's order
}
Remove-Item $tmp -Recurse -Force
$newest = $meta | Where-Object { $_.Name -match "^G1R-" } | Sort-Object Ticks -Descending | Select-Object -First 1
"done: $count files, newest save slot $($newest.Name). Load this save on both PCs."
