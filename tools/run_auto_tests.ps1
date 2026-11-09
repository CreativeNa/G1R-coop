# One command for the automated checks that need no player input. Runs what it can and skips the rest with a reason.
#
#   .\tools\run_auto_tests.ps1                      # everything available right now
#   .\tools\run_auto_tests.ps1 -Peer x.x.x.x    # also the pair checks (invariants, duplicates)
#   .\tools\run_auto_tests.ps1 -SkipSecurity
#
# Order: save-transfer security (no game needed) -> invariants on the pair -> packet fuzzing -> duplicate-event finder ->
# a short log-growth gate. Each step prints its own verdict; the summary at the end says which steps ran and how long
# they took. Nothing here changes game state, and no step needs the player to do anything.
#
# Exit code: 0 = every step that ran passed, 1 = something failed.
param(
    [string]$Peer = '',
    [int]$Port = 40004,
    [string]$Token = '',
    [switch]$SkipSecurity,
    [switch]$SkipFuzz,
    [int]$FuzzCount = 200
)
$ErrorActionPreference = 'Continue'
$here = $PSScriptRoot
$total = [Diagnostics.Stopwatch]::StartNew()
$steps = New-Object System.Collections.ArrayList

function Step([string]$name, [scriptblock]$body) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    ""
    "=== $name ==="
    $code = 0
    try { & $body; $code = $LASTEXITCODE } catch { "exception: $($_.Exception.Message)"; $code = 1 }
    $sw.Stop()
    [void]$steps.Add([pscustomobject]@{ Name = $name; Code = $code; Seconds = [math]::Round($sw.Elapsed.TotalSeconds, 1) })
}

$game = [bool](Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue)

if (-not $SkipSecurity) {
    Step 'installer package: layout and manifest' { & (Join-Path $here 'test_install_cycle.ps1') | Out-Null }
}
if (-not $SkipSecurity) {
    Step 'save transfer: token, path traversal, absurd size' { & (Join-Path $here 'test_savesync_security.ps1') | Out-Null }
}

if ($Peer) {
    Step 'invariants on both copies' { & (Join-Path $here 'cooptest.ps1') -Mode Check -Peer $Peer -Port $Port -Token $Token | Out-Null }
} else {
    ""
    "SKIP  invariants: no -Peer given"
}

if (-not $SkipFuzz) {
    if ($game) { Step "packet fuzzing ($FuzzCount packets)" { & (Join-Path $here 'fuzz_net.ps1') -Count $FuzzCount | Out-Null } }
    else { ""; "SKIP  packet fuzzing: no game copy is running" }
} else { ""; "SKIP  packet fuzzing: -SkipFuzz" }

if ($Peer) {
    Step 'duplicate events across the copies (report only)' { & (Join-Path $here 'find_duplicates.ps1') -Peer $Peer -Port $Port -Token $Token | Out-Null }
} else {
    ""
    "SKIP  duplicate events: no -Peer given"
}

$total.Stop()
""
"--- summary -------------------------------------------------------------------"
foreach ($s in $steps) { "{0,-52} {1,-4} {2,5:N1}s" -f $s.Name, $(if ($s.Code -eq 0) { 'ok' } else { "FAIL($($s.Code))" }), $s.Seconds }
$failed = @($steps | Where-Object { $_.Code -ne 0 }).Count
"total $([math]::Round($total.Elapsed.TotalSeconds,1)) s, steps run $($steps.Count), failed $failed"
if ($failed) { exit 1 } else { exit 0 }
