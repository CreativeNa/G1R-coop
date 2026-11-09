# One-command status of the running co-op: processes, frame rate, module costs, exceptions, log tail.
#   .\tools\health.ps1
param([int]$Tail = 6)
$root = Split-Path -Parent $PSScriptRoot
$log = Join-Path $root 'native\build\coopdll.log'

"=== processes ==="
$procs = Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue
if (-not $procs) { "no game copy is running"; exit 1 }
foreach ($p in $procs) {
    $seat = if ($p.MainWindowTitle -match 'HOST') { 'host' } elseif ($p.MainWindowTitle -match 'GUEST') { 'guest' } else { '?' }
    "{0,-6} pid {1,-6} {2}" -f $seat, $p.Id, $p.MainWindowTitle
}
$ids = @($procs | ForEach-Object { $_.Id })

if (Test-Path $log) {
    $lines = Get-Content $log -Tail 4000

    "=== frame rate (last sample per copy) ==="
    foreach ($procId in $ids) {
        $l = $lines | Where-Object { $_ -match "^\[$procId .*PR fps" } | Select-Object -Last 1
        if ($l -and $l -match 'PR fps ([\d.]+) worst frame (\d+) ms, window (\w+)') {
            "pid ${procId}: $($matches[1]) fps, worst $($matches[2]) ms, $($matches[3])"
        } else { "pid ${procId}: no fps line" }
    }

    "=== module cost (last sample per copy) ==="
    foreach ($procId in $ids) {
        $l = $lines | Where-Object { $_ -match "^\[$procId .*M cost ms" } | Select-Object -Last 1
        if ($l) { "pid ${procId}: " + ($l -replace '^\[[^\]]+\]\s*', '') }
    }

    "=== exceptions in the last 4000 lines ==="
    $exc = $lines | Where-Object { $_ -match 'EXCEPTION' }
    if ($exc) { $exc | Select-Object -Last 3 | ForEach-Object { $_ } } else { "none" }

    "=== log tail ==="
    Get-Content $log -Tail $Tail | ForEach-Object { $_.Substring(0, [Math]::Min(140, $_.Length)) }
}
