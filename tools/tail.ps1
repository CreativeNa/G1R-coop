# Tail the mod log with filters, so digging through a 300 KB log is one command.
#   .\tools\tail.ps1 -Pattern 'S light' -N 10
#   .\tools\tail.ps1 -Seat host -Pattern 'N dmg|N death' -N 20
#   .\tools\tail.ps1 -Since '21:1'
param(
    [string]$Pattern = '',
    [ValidateSet('host', 'guest', 'both')][string]$Seat = 'both',
    [int]$N = 20,
    [string]$Since = ''
)
$root = Split-Path -Parent $PSScriptRoot
$log = Join-Path $root 'native\build\coopdll.log'
if (-not (Test-Path $log)) { "no log at $log"; exit 1 }

$procs = Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue
$hostPid = ($procs | Where-Object { $_.MainWindowTitle -match 'HOST' } | Select-Object -First 1).Id
$guestPid = ($procs | Where-Object { $_.MainWindowTitle -match 'GUEST' } | Select-Object -First 1).Id

$lines = Get-Content $log -Tail 6000
$sel = $lines
if ($Pattern) { $sel = $sel | Where-Object { $_ -match $Pattern } }
if ($Seat -ne 'both') {
    $pidWanted = if ($Seat -eq 'host') { $hostPid } else { $guestPid }
    if ($pidWanted) { $sel = $sel | Where-Object { $_ -match "^\[$pidWanted " } }
}
if ($Since) { $sel = $sel | Where-Object { $_ -match "^\S+ $Since" } }
$sel | Select-Object -Last $N | ForEach-Object { $_.Substring(0, [Math]::Min(160, $_.Length)) }
