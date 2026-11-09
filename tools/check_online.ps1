# One command for the state of a live two-PC session: the co-op invariants, the save/load audit and the log growth rate.
#   .\tools\check_online.ps1 -Peer x.x.x.x
#   .\tools\check_online.ps1 -Peer x.x.x.x -Minutes 2      # measure the log over 2 minutes instead of 1
# Exit code: 0 = everything green, 1 = a check failed.
#
# It changes nothing: cooptest only reads both logs (the guest through tools\diag_link.ps1), load_audit reads the host
# log, and the growth rate is two file sizes a minute apart. For the scenarios that need players use cooptest -Mode Run.
param(
    [Parameter(Mandatory = $true)][string]$Peer,
    [int]$Port = 40004,
    [string]$Token = '',
    [int]$Minutes = 1
)
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$log = Join-Path $env:LOCALAPPDATA 'G1RCoop\app\coopdll.log'
$fail = 0

if (-not (Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue)) {
    "no Gothic 1 Remake process is running - start the session first"; exit 2
}

"=== 1/3 invariants on both copies ==="
& (Join-Path $PSScriptRoot 'cooptest.ps1') -Mode Check -Peer $Peer -Port $Port -Token $Token
if ($LASTEXITCODE -ne 0) { $fail++; "(cooptest reported a failure)" }

""
"=== 2/3 save/load audit (host log) ==="
& (Join-Path $PSScriptRoot 'load_audit.ps1')
if ($LASTEXITCODE -ne 0) { $fail++ }

""
"=== 3/3 log growth ($Minutes min) ==="
if (Test-Path -LiteralPath $log) {
    $b0 = (Get-Item -LiteralPath $log).Length
    $t0 = Get-Date
    Start-Sleep -Seconds ($Minutes * 60)
    $b1 = (Get-Item -LiteralPath $log).Length
    $hours = ((Get-Date) - $t0).TotalHours
    $mb = [math]::Round($b1 / 1MB, 2)
    $rate = if ($hours -gt 0) { [math]::Round((($b1 - $b0) / 1MB) / $hours, 1) } else { 0 }
    # Before the npc diagnostics were gated this was 13 MB/hour on an idle-ish session, so the line is a regression gate.
    if ($rate -le 20) { "PASS  log growth $rate MB/hour (log $mb MB)" }
    else { "FAIL  log growth $rate MB/hour (log $mb MB) - is npc_diag.txt lying around?"; $fail++ }
} else { "SKIP  log growth: no log at $log" }

""
if ($fail) { "VERDICT: red ($fail check(s) failed)" } else { "VERDICT: green" }
if ($fail) { exit 1 } else { exit 0 }
