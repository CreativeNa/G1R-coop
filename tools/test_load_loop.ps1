# Presses F9 (load last save) a number of times and checks that every press produces exactly ONE load on BOTH copies.
#
#   .\tools\test_load_loop.ps1 -Count 5                  # shows what it would do and stops (safe)
#   .\tools\test_load_loop.ps1 -Count 5 -IUnderstand     # really presses F9 five times
#   .\tools\test_load_loop.ps1 -Count 5 -IUnderstand -Seat 0 -WaitSeconds 90
#
# WARNING: this reloads the game. Progress since the last save is lost, every time. That is why -IUnderstand is required.
#
# Why it waits for the friend: the first version pressed F9 on a timer and did not look at the guest at all. On 2026-11-07
# it produced five host loads and one guest load - the guest was still loading when the next press arrived, and after that
# only the host followed. A load loop is only meaningful when BOTH copies confirm the load, so now the next press happens
# only after the guest has reported its load too, and the loop STOPS as soon as the friend does not follow.
#
# Exit code: 0 = one load per press on both copies, 1 = the friend did not follow / double load / no load, 2 = safety flag
# missing or no game.
param(
    [int]$Count = 5,
    [int]$Seat = 0,
    [int]$WaitSeconds = 90,
    [int]$SettleSeconds = 8,
    [switch]$IUnderstand,
    [string]$Peer = '',
    [int]$Port = 40004,
    [string]$Token = '',
    [string]$LogPath = (Join-Path $env:LOCALAPPDATA 'G1RCoop\app\coopdll.log')
)
$ErrorActionPreference = 'Continue'
$here = $PSScriptRoot

if (-not $IUnderstand) {
    "refusing to run: this presses F9 $Count times and throws away progress since the last save."
    "add -IUnderstand to confirm, e.g.:  .\tools\test_load_loop.ps1 -Count $Count -IUnderstand"
    exit 2
}
$proc = Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $proc) { "no Gothic 1 Remake process is running"; exit 2 }
if (-not (Test-Path -LiteralPath $LogPath)) { "no log at $LogPath"; exit 2 }
$realkey = Join-Path $here 'realkey.ps1'
if (-not (Test-Path -LiteralPath $realkey)) { "realkey.ps1 missing next to this script"; exit 2 }
if (-not $Peer) {
    "no -Peer: this loop must watch the friend too, otherwise it repeats the 2026-11-07 mistake (five host loads, one guest)"
    exit 2
}

# Windows only lets a process call SetForegroundWindow when it is already the foreground one; the plain call fails
# silently and the key goes nowhere (that is why the first runs pressed F9 with no load in the log). AttachThreadInput
# borrows the foreground thread's input state, which works from a background process.
Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class LFFocus {
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool f);
  [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
  public static string Title(IntPtr h) { var sb = new StringBuilder(256); GetWindowText(h, sb, 256); return sb.ToString(); }
}
"@
function Focus-Game {
    $proc = Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $proc) { return $false }
    $h = $proc.MainWindowHandle
    $fg = [LFFocus]::GetForegroundWindow()
    if ([LFFocus]::Title($fg) -match 'Gothic 1 Remake') { return $true }
    [void][LFFocus]::ShowWindow($h, 9)
    [void][LFFocus]::SetForegroundWindow($h)
    if ([LFFocus]::Title([LFFocus]::GetForegroundWindow()) -match 'Gothic 1 Remake') { return $true }
    $fgPid = 0; $fgThread = [LFFocus]::GetWindowThreadProcessId($fg, [ref]$fgPid)
    $me = [LFFocus]::GetCurrentThreadId()
    [void][LFFocus]::AttachThreadInput($me, $fgThread, $true)
    [void][LFFocus]::SetForegroundWindow($h)
    [void][LFFocus]::AttachThreadInput($me, $fgThread, $false)
    Start-Sleep -Milliseconds 300
    return ([LFFocus]::Title([LFFocus]::GetForegroundWindow()) -match 'Gothic 1 Remake')
}
$script:guestLog = $null
function Update-GuestLog {
    & (Join-Path $here 'diag_link.ps1') fetch -Peer $Peer -Port $Port -Token $Token | Out-Null
    $rep = Get-ChildItem (Join-Path $here '..\native\build') -Filter 'guest_report_*.json' | Sort-Object LastWriteTime | Select-Object -Last 1
    if (-not $rep) { return $null }
    $script:guestLog = @((Get-Content -LiteralPath $rep.FullName -Raw | ConvertFrom-Json).coopdll_log -split "`r?`n")
    return $script:guestLog
}
# counts of "a world load started" in a given text block, and the last timestamp of such a line
function Count-Loads([string[]]$lines) { return @($lines | Where-Object { $_ -match 'S load: a new hero' }).Count }
function Last-LoadTime([string[]]$lines) {
    $l = @($lines | Where-Object { $_ -match 'S load: a new hero' }) | Select-Object -Last 1
    if ($l -and $l -match '^\[\d+ (\d\d:\d\d:\d\d)') { return $Matches[1] }
    return ''
}
function Host-Text {
    $fs = [IO.File]::Open($LogPath, 'Open', 'Read', 'ReadWrite')
    try { $sr = New-Object IO.StreamReader($fs); $t = $sr.ReadToEnd(); $sr.Close() } finally { $fs.Dispose() }
    return $t
}

"watching both copies; one press, then wait for the host AND the guest to report the load"
$results = @()
for ($i = 1; $i -le $Count; $i++) {
    if (-not (Focus-Game)) { "could not bring the game window to the foreground - the key would go nowhere"; exit 1 }
    # Count by TIME, not by absolute number: the guest log is only a 2000-line tail, so older load lines scroll out and an
    # absolute count can go DOWN (that produced "guest 3 -> 2" and a false "did not follow" at 19:29).
    $since = (Get-Date).ToString('HH:mm:ss')
    $t0 = Get-Date
    & $realkey -Seat $Seat -Vk 0x78 | Out-Null

    function Loads-Since([string[]]$lines, [string]$from) {
        return @($lines | Where-Object { $_ -match 'S load: a new hero' -and $_ -match '^\[\d+ (\d\d:\d\d:\d\d)' -and $Matches[1] -ge $from }).Count
    }

    $hostOk = $false; $guestOk = $false
    $deadline = (Get-Date).AddSeconds($WaitSeconds)
    $lastFetch = Get-Date
    while ((Get-Date) -lt $deadline) {
        if (-not $hostOk) { $hostOk = ((Loads-Since ((Host-Text) -split "`r?`n") $since) -ge 1) }
        if ($hostOk -and -not $guestOk -and ((Get-Date) - $lastFetch).TotalSeconds -ge 4) {
            [void](Update-GuestLog)
            $lastFetch = Get-Date
            $guestOk = ((Loads-Since $script:guestLog $since) -ge 1)
        }
        if ($hostOk -and $guestOk) { break }
        Start-Sleep -Milliseconds 500
    }
    # The guest logs `S event in: type 9 '<slot>'` the moment the load arrives, about 10 s before its own "new hero"
    # line. Waiting for the load SCREEN to finish is what took the world back; a fixed 35 s settle does that reliably,
    # while the fragile "is there a live line after the load" check kept reporting a guest that had actually followed
    # (2026-11-07 19:22: host 19:22:12, guest type 9 19:21:58 and its load 19:22:18).
    Start-Sleep -Seconds 35
    [void](Update-GuestLog)
    $hostExtra = Loads-Since ((Host-Text) -split "`r?`n") $since
    $guestExtra = Loads-Since $script:guestLog $since
    $took = [math]::Round(((Get-Date) - $t0).TotalSeconds, 1)

    if (-not $hostOk) {
        "{0,2}/{1}: NO HOST LOAD after {2} s - stopping" -f $i, $Count, $took
        $results += [pscustomobject]@{ Press = $i; Host = $false; Guest = $false; Verdict = 'no host load' }
        break
    }
    if (-not $guestOk) {
        "{0,2}/{1}: host loaded, THE FRIEND DID NOT follow within {2} s - stopping" -f $i, $Count, $WaitSeconds
        "        loads since the press: host $((Loads-Since ((Host-Text) -split "`r?`n") $since)), guest $((Loads-Since $script:guestLog $since))"
        $results += [pscustomobject]@{ Press = $i; Host = $true; Guest = $false; Verdict = 'guest did not follow' }
        break
    }

    # both loaded: let the world settle, then make sure no SECOND load happened on either copy
    Start-Sleep -Seconds $SettleSeconds
    $hostExtra = Loads-Since ((Host-Text) -split "`r?`n") $since
    [void](Update-GuestLog)
    $guestExtra = Loads-Since $script:guestLog $since
    $verdict = if ($hostExtra -eq 1 -and $guestExtra -eq 1) { 'one load each' } else { "host $hostExtra / guest $guestExtra" }
    "{0,2}/{1}: {2,-18} {3,5}s  (host {4}, guest {5} loads)" -f $i, $Count, $verdict, $took, $hostExtra, $guestExtra
    $results += [pscustomobject]@{ Press = $i; Host = ($hostExtra -eq 1); Guest = ($guestExtra -eq 1); Verdict = $verdict }
    Start-Sleep -Seconds 2
}

""
$bad = @($results | Where-Object { $_.Verdict -ne 'one load each' })
if ($bad.Count) {
    "FAIL $($bad.Count) of $($results.Count) press(es) did not give exactly one load on both copies"
    $bad | ForEach-Object { "  press $($_.Press): $($_.Verdict)" }
    exit 1
}
"=== load audit ==="
& (Join-Path $here 'load_audit.ps1') | Select-Object -Last 10
"PASS every press produced exactly one load on both copies"
exit 0
