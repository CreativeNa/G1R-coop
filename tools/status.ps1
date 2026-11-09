# One screen with everything needed to judge the state of a run:
# processes, seats, active switches, loaded module builds, fps, the last errors, the load memory.
#   .\tools\status.ps1
param([switch]$NoProbe)
$c = Split-Path $PSScriptRoot -Parent

"=== processes ==="
$games = @(Get-CimInstance Win32_Process -Filter "Name='G1R-Win64-Shipping.exe'" -ErrorAction SilentlyContinue)
if (-not $games) { "no game running"; exit 2 }
foreach ($g in $games) {
    $seat = if ($g.CommandLine -match '-CoopSeat=(\d+)') { $Matches[1] } else { '?' }
    $p = Get-Process -Id $g.ProcessId -ErrorAction SilentlyContinue
    $mem = if ($p) { [math]::Round($p.WorkingSet64 / 1GB, 1) } else { 0 }
    "  seat $seat   pid $($g.ProcessId)   ${mem} GB"
}

"`n=== switches (only the ones that change behaviour) ==="
$known = @('story_off','story_noloadsync','story_loadkey','story_nochest','story_noscan','story_nokeys',
           'equip_off','npc_off','modules_off','gate_off','god_off','time_sync_off','memwatch','loadprobe')
$sw = @(Get-ChildItem (Join-Path $c "native\build") -Filter *.txt -ErrorAction SilentlyContinue |
        Where-Object { $known -contains ($_.BaseName -replace '_(on|off)?$','') -or $known -contains $_.BaseName -or $_.BaseName -like 'pose_*' -or $_.BaseName -like 'anim_*' })
if ($sw) { $sw | ForEach-Object { "  " + $_.Name } } else { "  none (everything on)" }

"`n=== modules: source vs what each seat actually runs ==="
$seatOf = @{}                                    # pid -> seat
foreach ($g in $games) {
    $st = if ($g.CommandLine -match '-CoopSeat=(\d+)') { [int]$Matches[1] } else { -1 }
    $seatOf[[int]$g.ProcessId] = $st
}
foreach ($name in 'anim','equip','pose','npc','story','menu','probe') {
    $src = Join-Path $c "native\build\modules\$name.dll"
    if (-not (Test-Path $src)) { "  {0,-6} no source dll" -f $name; continue }
    $srcTime = (Get-Item $src).LastWriteTime
    $cells = @()
    foreach ($procId in ($seatOf.Keys | Sort-Object { $seatOf[$_] })) {
        $f = @(Get-ChildItem (Join-Path $c "native\build\modules") -Filter "${name}_${procId}_*.dll" -ErrorAction SilentlyContinue |
               Sort-Object LastWriteTime -Descending | Select-Object -First 1)
        $seat = $seatOf[$procId]
        if (-not $f) { $cells += "seat ${seat}: not loaded"; continue }
        $same = [math]::Abs(($f[0].LastWriteTime - $srcTime).TotalSeconds) -lt 2
        $cells += ("seat ${seat}: " + $f[0].LastWriteTime.ToString('HH:mm:ss') + $(if ($same) { ' ok' } else { ' STALE' }))
    }
    "  {0,-6} source {1}   {2}" -f $name, $srcTime.ToString('HH:mm:ss'), ($cells -join '   ')
}

"`n=== last errors in the log ==="
$log = Join-Path $c "native\build\coopdll.log"
if (Test-Path $log) {
    $err = @(Select-String -LiteralPath $log -Pattern 'AV at coopdll|EXCEPTION|or crash' -ErrorAction SilentlyContinue)
    "  $($err.Count) total;"
    if ($err.Count -gt 0) { $err | Select-Object -Last 2 | ForEach-Object { "    " + $_.Line.Trim() } }
    "  log: $((Get-Content -LiteralPath $log).Count) lines"
} else { "  no log" }

"`n=== load memory ==="
$lid = Join-Path $c "native\build\last_load_lid.txt"
if (Test-Path $lid) { "  last applied event (pid:lid) = " + (Get-Content -LiteralPath $lid) } else { "  none yet this session" }

if (-not $NoProbe) {
    "`n=== live state ==="
    foreach ($seat in 0, 1) {
        $r = & (Join-Path $c "tools\dev.ps1") probe "@$seat fps" 2>&1 | Out-String
        $m = [regex]::Match($r, "fps\s+([\d.]+)")
        $fps = if ($m.Success) { $m.Groups[1].Value } else { 'n/a' }
        $h = & (Join-Path $c "tools\dev.ps1") probe "@$seat heroinfo" 2>&1 | Out-String
        $pos = [regex]::Match($h, "HEROINFO pos ([-\d.]+ [-\d.]+ [-\d.]+)")
        $p = if ($pos.Success) { $pos.Groups[1].Value } else { 'n/a' }
        "  seat $seat   fps $fps   hero at $p"
    }
}
