# Raw bytes of the camera's point-of-view data (the part that holds FOV and post-process settings), for a before/after comparison:
#   .\tools\veil_hex.ps1 before 0   (veil on screen on seat 0)  ->  swing the pickaxe until it is gone  ->  .\tools\veil_hex.ps1 after 0  ->  .\tools\veil_hex.ps1 diff
param([string]$Mode = "before", [int]$Seat = 0)
$root = Split-Path $PSScriptRoot -Parent
$dir = Join-Path $root "native\build\veil"
New-Item -ItemType Directory -Force $dir | Out-Null
$dev = Join-Path $PSScriptRoot "dev.ps1"
if ($Mode -eq "diff") {
    $b = Get-Content "$dir\hex_before.txt"; $a = Get-Content "$dir\hex_after.txt"
    $n = [Math]::Min($b.Count, $a.Count); $shown = 0
    for ($i = 0; $i -lt $n; $i++) { if ($b[$i] -ne $a[$i] -and $b[$i] -match '^\+' ) { "B $($b[$i])"; "A $($a[$i])"; $shown++ } }
    "$shown differing lines of $n"
    return
}
$f = & $dev probe "@$Seat findall PlayerCameraManagerBP_C PlayerCameraManagerBP_C_2 1" 2>&1 | Out-String
$m = [regex]::Match($f, '0000([0-9A-F]{12}) ')
if (-not $m.Success) { "camera manager not found"; return }
$p = "0x" + $m.Groups[1].Value
$out = & $dev probe "@$Seat hex $p 800 2080" "@$Seat hex $p 5008 2064" 2>&1 | Out-String
Set-Content "$dir\hex_$Mode.txt" $out
"saved hex_$Mode.txt ($((($out -split "`n") | Where-Object { $_ -match '^\+' }).Count) lines)"
