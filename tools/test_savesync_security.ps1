# Security checks for the save transfer (tools\savesync.ps1). No game and no second PC needed.
#
#   .\tools\test_savesync_security.ps1              # all checks, about 30 s
#   .\tools\test_savesync_security.ps1 -KeepTemps   # keep the temp folders
#   .\tools\test_savesync_security.ps1 -TimeoutSec 8
#
# Checks:
#   1. a correct token transfers the saves;
#   2. a wrong token is refused;
#   3. no token against a server that has one is refused;
#   4. a hostile server sending a path-traversal name cannot make the client write outside its folder;
#   5. a hostile server announcing an absurd file size does not hang the client;
#   6. a hostile server sending a garbage timestamp does not crash the client.
#
# Servers and clients run as SEPARATE PROCESSES, not as PowerShell jobs: a job blocked in AcceptTcpClient() cannot be
# stopped reliably (Stop-Job hangs), and that is what made the first two versions of this script freeze.
#
# Exit code: 0 = all passed, 1 = something failed.
param(
    [int]$Port = 40093,
    [switch]$KeepTemps,
    [int]$TimeoutSec = 10
)
$ErrorActionPreference = 'Continue'
$here = $PSScriptRoot
$savesync = Join-Path $here 'savesync.ps1'
if (-not (Test-Path -LiteralPath $savesync)) { "savesync.ps1 not found next to this script"; exit 2 }
# Work from a copy in a space-free folder: Start-Process joins -ArgumentList with spaces and the repository path has
# spaces ("FOR GOTHIC 1 REMAKE"), which made the first runs fail with "the file does not have a .ps1 extension".
$ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

$root = Join-Path ([IO.Path]::GetTempPath()) ('savesync_sec_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force (Join-Path $root 'tools') | Out-Null
$savesyncSrc = $savesync
$savesync = Join-Path (Join-Path $root 'tools') 'savesync.ps1'
Copy-Item -LiteralPath $savesyncSrc -Destination $savesync -Force
$serve = Join-Path $root 'serve'
New-Item -ItemType Directory -Force $serve | Out-Null
$blob = New-Object byte[] 1024
for ($i = 0; $i -lt $blob.Length; $i++) { $blob[$i] = [byte]($i % 251) }
[IO.File]::WriteAllBytes((Join-Path $serve 'G1R-009.sav'), $blob)
$Token = 'coop-secret'

# a tiny hostile server: sends one payload to everyone who connects for a while, then exits by itself
$hostile = Join-Path $root 'hostile.ps1'
Set-Content -LiteralPath $hostile -Encoding UTF8 -Value @'
param([int]$Port, [string]$PayloadFile, [int]$Seconds = 20)
$payload = [IO.File]::ReadAllText($PayloadFile)
$l = New-Object Net.Sockets.TcpListener([Net.IPAddress]::Loopback, $Port)
$l.Start()
$end = (Get-Date).AddSeconds($Seconds)
while ((Get-Date) -lt $end) {
    if (-not $l.Pending()) { Start-Sleep -Milliseconds 50; continue }
    try {
        $c = $l.AcceptTcpClient(); $s = $c.GetStream()
        $b = [Text.Encoding]::ASCII.GetBytes($payload)
        $s.Write($b, 0, $b.Length); $s.Flush(); Start-Sleep -Milliseconds 150; $c.Close()
    } catch { }
}
$l.Stop()
'@

$procs = New-Object System.Collections.ArrayList
function Start-Server([string[]]$argv) {
    $p = Start-Process -FilePath $ps -ArgumentList $argv -PassThru -NoNewWindow
    [void]$procs.Add($p)
    return $p
}
function Wait-Port([int]$port, [int]$ms = 6000) {
    $deadline = (Get-Date).AddMilliseconds($ms)
    while ((Get-Date) -lt $deadline) {
        try { $c = New-Object Net.Sockets.TcpClient; $c.Connect('127.0.0.1', $port); $c.Close(); return $true } catch { Start-Sleep -Milliseconds 80 }
    }
    return $false
}
# Runs the client with a hard timeout; returns @{ TimedOut; Out }
function Invoke-Fetch([int]$port, [string]$token, [string]$dir) {
    New-Item -ItemType Directory -Force $dir | Out-Null
    $o = Join-Path $root ('out_' + [guid]::NewGuid().ToString('N').Substring(0, 6) + '.txt')
    $e = Join-Path $root ('err_' + [guid]::NewGuid().ToString('N').Substring(0, 6) + '.txt')
    $argv = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $savesync, 'fetch', '-Peer', '127.0.0.1', '-Port', "$port", '-SaveDir', $dir)
    if ($token) { $argv += @('-Token', $token) }
    $p = Start-Process -FilePath $ps -ArgumentList $argv -PassThru -NoNewWindow -RedirectStandardOutput $o -RedirectStandardError $e
    # WaitForExit returns $true/$false; Wait-Process returns nothing on success and threw on timeout, which made every
    # run look like a timeout in the previous version of this script.
    $exited = $p.WaitForExit($TimeoutSec * 1000)
    if (-not $exited) {
        try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } catch { }
        return @{ TimedOut = $true; Out = "killed after $TimeoutSec s" }
    }
    $text = (@((Get-Content $o -ErrorAction SilentlyContinue), @(Get-Content $e -ErrorAction SilentlyContinue)) | ForEach-Object { $_ }) -join "`n"
    return @{ TimedOut = $false; Out = $text }
}

$results = New-Object System.Collections.ArrayList
function Check([string]$name, [bool]$ok, [string]$detail) {
    [void]$results.Add([pscustomobject]@{ Name = $name; Ok = $ok })
    "$(if ($ok) { 'PASS' } else { 'FAIL' })  $name$(if ($detail) { " - $detail" })"
}

try {
    # --- honest server ---------------------------------------------------------------------------------------------
    $srv = Start-Server @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $savesync, 'serve', '-SaveDir', $serve, '-Port', "$Port", '-Token', $Token, '-Minutes', '2')
    if (-not (Wait-Port $Port)) { "the test server did not start on port $Port"; throw 'no server' }

    $r = Invoke-Fetch $Port $Token (Join-Path $root 'client_ok')
    $got = Test-Path (Join-Path $root 'client_ok\G1R-009.sav')
    Check 'correct token transfers the saves' (-not $r.TimedOut -and $got) (($r.Out -split "`n" | Where-Object { $_ -match '\S' } | Select-Object -First 1))

    $r = Invoke-Fetch $Port 'not-the-token' (Join-Path $root 'client_wrong')
    Check 'wrong token is refused' (-not $r.TimedOut -and $r.Out -match 'ERR token') (($r.Out -split "`n" | Where-Object { $_ -match '\S' } | Select-Object -First 1))

    $r = Invoke-Fetch $Port '' (Join-Path $root 'client_none')
    Check 'a missing token is refused' (-not $r.TimedOut -and $r.Out -match 'ERR token') (($r.Out -split "`n" | Where-Object { $_ -match '\S' } | Select-Object -First 1))

    # --- hostile servers -------------------------------------------------------------------------------------------
    function Start-Hostile([int]$port, [string]$payload) {
        $f = Join-Path $root ('payload_' + [guid]::NewGuid().ToString('N').Substring(0, 6) + '.txt')
        [IO.File]::WriteAllText($f, $payload)
        Start-Server @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $hostile, '-Port', "$port", '-PayloadFile', $f, '-Seconds', '20') | Out-Null
        return (Wait-Port $port)
    }

    $p = $Port + 1
    if (Start-Hostile $p ("SAVESYNC1 1`n" + "..\..\pwn.sav|4|0`n" + "EVIL")) {
        $r = Invoke-Fetch $p '' (Join-Path $root 'client_trav')
        $escaped = (Test-Path (Join-Path $root 'pwn.sav')) -or (Test-Path (Join-Path $root 'client_trav\..\..\pwn.sav'))
        Check 'a path-traversal name is refused' (-not $r.TimedOut -and $r.Out -match 'refusing an unexpected file name' -and -not $escaped) (($r.Out -split "`n" | Where-Object { $_ -match '\S' } | Select-Object -First 1))
    } else { Check 'a path-traversal name is refused' $false 'the hostile server did not start' }

    $p = $Port + 2
    if (Start-Hostile $p ("SAVESYNC1 1`n" + "G1R-001.sav|4294967295|0`n")) {
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $r = Invoke-Fetch $p '' (Join-Path $root 'client_big')
        $sw.Stop()
        Check 'an absurd file size does not hang the client' (-not $r.TimedOut) ("{0:N1} s, {1}" -f $sw.Elapsed.TotalSeconds, ($r.Out -split "`n" | Where-Object { $_ -match '\S' } | Select-Object -First 1))
    } else { Check 'an absurd file size does not hang the client' $false 'the hostile server did not start' }

    $p = $Port + 3
    if (Start-Hostile $p ("SAVESYNC1 1`n" + "G1R-002.sav|4|999999999999999999`n" + "DATA")) {
        $r = Invoke-Fetch $p '' (Join-Path $root 'client_ts')
        Check 'a garbage timestamp does not crash the client' (-not $r.TimedOut) (($r.Out -split "`n" | Where-Object { $_ -match '\S' } | Select-Object -First 1))
    } else { Check 'a garbage timestamp does not crash the client' $false 'the hostile server did not start' }
}
catch { if ($_.Exception.Message -ne 'no server') { "test error: $($_.Exception.Message)" } }
finally {
    foreach ($p in $procs) { try { if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } } catch { } }
}

""
$fail = @($results | Where-Object { -not $_.Ok }).Count
$pass = @($results | Where-Object { $_.Ok }).Count
if ($KeepTemps) { "temp files kept in $root" } else { Remove-Item $root -Recurse -Force -ErrorAction SilentlyContinue }
"verdict: $(if ($fail -or $results.Count -eq 0) { 'RED' } else { 'green' }) ($pass passed, $fail failed)"
if ($fail -or $results.Count -eq 0) { exit 1 } else { exit 0 }
