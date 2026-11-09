# Throws malformed UDP packets at a running copy and checks that it survives them.
#
#   .\tools\fuzz_net.ps1                          # 200 packets at 127.0.0.1:40001, then a verdict
#   .\tools\fuzz_net.ps1 -Peer x.x.x.x -Count 500
#   .\tools\fuzz_net.ps1 -NoGameCheck             # only look at the log afterwards
#
# Packets are of the kinds a broken or hostile peer can produce: empty, one byte, a valid-looking header with a nonsense
# body, 8 KB of random bytes, and a full 60 KB datagram. The mod is allowed to log that it cannot parse them; it is not
# allowed to die or to throw.
#
# Exit code: 0 = the copy survived, 1 = it did not (or a new exception appeared), 2 = no game running.
param(
    [string]$Peer = '127.0.0.1',
    [int]$Port = 40001,
    [int]$Count = 200,
    [int]$DelayMs = 5,
    [string]$LogPath = (Join-Path $env:LOCALAPPDATA 'G1RCoop\app\coopdll.log')
)
$ErrorActionPreference = 'Continue'

$proc = Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $proc) { "no Gothic 1 Remake process is running - start the copy you want to fuzz first"; exit 2 }

$logBefore = if (Test-Path -LiteralPath $LogPath) { (Get-Item -LiteralPath $LogPath).Length } else { 0 }
$excBefore = if (Test-Path -LiteralPath $LogPath) { (Select-String -LiteralPath $LogPath -Pattern 'EXCEPTION' | Measure-Object).Count } else { 0 }

$udp = New-Object Net.Sockets.UdpClient
$rand = New-Object System.Random 12345
$sent = 0; $bytes = 0
$cases = @(
    @{ Name = 'empty'; Data = (New-Object byte[] 0) },
    @{ Name = 'one byte'; Data = [byte[]](0x50) },
    @{ Name = 'header only'; Data = [Text.Encoding]::ASCII.GetBytes('P|1|0|0|0|0') },
    @{ Name = 'valid prefix, garbage'; Data = [Text.Encoding]::ASCII.GetBytes('P|4294967295|x|y|z|0|' + ('F' * 200)) }
)
$big = New-Object byte[] 8192; $rand.NextBytes($big)
$cases += @{ Name = '8 KB random'; Data = $big }
$huge = New-Object byte[] 60000; $rand.NextBytes($huge)
$cases += @{ Name = '60 KB random'; Data = $huge }

foreach ($c in $cases) {
    try { [void]$udp.Send($c.Data, $c.Data.Length, $Peer, $Port); $sent++; $bytes += $c.Data.Length } catch { }
}
$remaining = [Math]::Max(0, $Count - $sent)
for ($i = 0; $i -lt $remaining; $i++) {
    $n = $rand.Next(1, 300)
    $b = New-Object byte[] $n; $rand.NextBytes($b)
    try { [void]$udp.Send($b, $n, $Peer, $Port); $sent++; $bytes += $n } catch { }
    if ($DelayMs -gt 0) { Start-Sleep -Milliseconds $DelayMs }
}
$udp.Close()
"sent $sent malformed packets ($([math]::Round($bytes / 1KB, 1)) KB) to ${Peer}:$Port"

Start-Sleep -Seconds 3
$alive = [bool](Get-Process -Id $proc.Id -ErrorAction SilentlyContinue)
$logAfter = if (Test-Path -LiteralPath $LogPath) { (Get-Item -LiteralPath $LogPath).Length } else { 0 }
$excAfter = if (Test-Path -LiteralPath $LogPath) { (Select-String -LiteralPath $LogPath -Pattern 'EXCEPTION' | Measure-Object).Count } else { 0 }
$newLines = 0
if (Test-Path -LiteralPath $LogPath) {
    $tail = Get-Content -LiteralPath $LogPath -Tail 400 -ErrorAction SilentlyContinue
    $newLines = @($tail | Where-Object { $_ -match 'parse|cannot|bad|junk|garbage' }).Count
}

"process alive: $alive, new EXCEPTION lines: $($excAfter - $excBefore), log grew: $([math]::Round(($logAfter - $logBefore) / 1KB, 1)) KB"
if ($newLines) { "the mod logged $newLines line(s) about unreadable input - that is the expected answer, not a failure" }

if (-not $alive -or $excAfter -gt $excBefore) {
    "FAIL the copy did not survive the fuzzing"
    exit 1
}
"PASS the copy survived $sent malformed packets"
exit 0
