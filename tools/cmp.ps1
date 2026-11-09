param(
    [Parameter(Mandatory = $true)][string]$Class,
    [string]$Name = '',
    [string]$Filter = '',
    [int]$Max = 4
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$dev = Join-Path $root 'tools\dev.ps1'

function Get-SeatProps([int]$seat) {
    $cmd = "@$seat findall $Class"
    if ($Name) { $cmd += " $Name" }
    $cmd += " $Max"
    $found = & $dev probe $cmd 2>&1
    $obj = $null
    foreach ($line in $found) {
        if ($line -match '^\s*([0-9A-Fa-f]{16})\s+(\S+)\s+\((.*)\)') {
            $n = $matches[2]
            if ($n -notlike 'Default__*') { $obj = @{ ptr = $matches[1]; name = $n; cls = $matches[3] }; break }
        }
    }
    if (-not $obj) { return $null }
    $props = [ordered]@{}
    $cmd2 = "@$seat members 0x$($obj.ptr)"
    if ($Filter) { $cmd2 += " $Filter" }
    $out = & $dev probe $cmd2 2>&1
    foreach ($line in $out) {
        if ($line -match '^\s*prop\s+(\S+)\s+\[[^\]]*\]\s+=\s*(.*)$') {
            $props[$matches[1]] = $matches[2].Trim()
        }
    }
    return @{ obj = $obj; props = $props }
}

$a = Get-SeatProps 0
$b = Get-SeatProps 1
if (-not $a -and -not $b) { "no '$Class' found on either copy"; exit 1 }
if ($a) { "host : $($a.obj.name) ($($a.obj.cls)) at $($a.obj.ptr)" } else { "host : not found" }
if ($b) { "guest: $($b.obj.name) ($($b.obj.cls)) at $($b.obj.ptr)" } else { "guest: not found" }
if (-not $a -or -not $b) { exit 2 }

$keys = @($a.props.Keys + $b.props.Keys | Sort-Object -Unique)
$same = 0; $diff = 0
foreach ($k in $keys) {
    $va = $a.props[$k]; $vb = $b.props[$k]
    if ($null -eq $va) { "  ONLY GUEST  $k = $vb"; $diff++; continue }
    if ($null -eq $vb) { "  ONLY HOST   $k = $va"; $diff++; continue }
    if ($va -eq $vb) { $same++ }
    else {
        $diff++
        "  DIFF        $k"
        "                host : $va"
        "                guest: $vb"
    }
}
""
"$same properties match, $diff differ (out of $($keys.Count))"
