# Live UI widgets with their visibility, for a before/after comparison (is the veil a full-screen widget that the pickaxe swing hides or removes?):
#   .\tools\veil_widgets.ps1 before 0  ->  swing the pickaxe until the veil is gone  ->  .\tools\veil_widgets.ps1 after 0  ->  .\tools\veil_widgets.ps1 diff
param([string]$Mode = "before", [int]$Seat = 0)
$root = Split-Path $PSScriptRoot -Parent
$dir = Join-Path $root "native\build\veil"
New-Item -ItemType Directory -Force $dir | Out-Null
$dev = Join-Path $PSScriptRoot "dev.ps1"
if ($Mode -eq "diff") {
    $b = Get-Content "$dir\widgets_before.txt"; $a = Get-Content "$dir\widgets_after.txt"
    Compare-Object $b $a | ForEach-Object { "$($_.SideIndicator) $($_.InputObject)" }
    return
}
$rows = @()
foreach ($pat in "W_", "WB_", "HUD", "Loading") {
    $f = & $dev probe "@$Seat findall $pat _21 400" 2>&1 | Out-String
    $rows += [regex]::Matches($f, '0000([0-9A-F]{12}) (\S+) \((\S+)\)') | Where-Object { $_.Groups[2].Value -notmatch '^Default__' } | ForEach-Object { "$($_.Groups[1].Value) $($_.Groups[2].Value)" }
}
$rows = $rows | Sort-Object -Unique
$cmds = $rows | ForEach-Object { "@$Seat get 0x$($_.Split(' ')[0]) Visibility" }
$vis = if ($cmds) { & $dev probe @cmds 2>&1 | Out-String } else { "" }
$map = @{}
$cur = $null
foreach ($ln in ($vis -split "`n")) {
    $m1 = [regex]::Match($ln, '^> get 0x0*([0-9A-Fa-f]+) Visibility')
    if ($m1.Success) { $cur = $m1.Groups[1].Value.ToUpper(); continue }
    $m2 = [regex]::Match($ln, 'Visibility \[[^\]]*\] = (\S+)')
    if ($m2.Success -and $cur) { $map[$cur] = $m2.Groups[1].Value; $cur = $null }
}
$lines = foreach ($r in $rows) { $ptr = $r.Split(' ')[0].TrimStart('0').ToUpper(); "$($r.Split(' ')[1] -replace '_\d{6,}','') vis=$(if ($map.ContainsKey($ptr)) { $map[$ptr] } else { '?' })" }
Set-Content "$dir\widgets_$Mode.txt" ($lines | Sort-Object)
"saved widgets_$Mode.txt ($($lines.Count) widgets)"
