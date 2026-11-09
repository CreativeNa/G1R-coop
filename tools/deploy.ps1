# One command to update the guest: build a module, copy it locally, push it over the bridge, verify the hashes.
#
#   .\tools\deploy.ps1 -Module story -Peer x.x.x.x
#   .\tools\deploy.ps1 -All -Peer x.x.x.x
#
# No package, no installer, no release: the guest's game hot-reloads modules and both copies end up on the same build.
# The guest only needs to have diag_link serve running (the launcher starts it) and this newer diag_link on his PC once.
param(
    [string]$Module = '',
    [switch]$All,
    [string]$Peer = '',
    [int]$Port = 40004,
    [string]$Token = ''
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$mods = @('anim', 'equip', 'menu', 'npc', 'pose', 'probe', 'story')
if (-not $All -and -not $Module) { "usage: deploy.ps1 -Module story | -All   [-Peer <guest ip>]"; exit 1 }
if ($All) { $build = $mods } else { $build = @($Module) }

$failed = 0
foreach ($m in $build) {
    "=== $m ==="
    & (Join-Path $PSScriptRoot '..\native\build_module.bat') $m 2>&1 | Select-String -Pattern ': error' | ForEach-Object { "  " + $_.Line.Trim() }
    if ($LASTEXITCODE -ne 0) { "  build FAILED"; $failed++; continue }
    $src = Join-Path $root ("native\build\modules\$m.dll")
    if (-not (Test-Path -LiteralPath $src)) { "  $src missing"; $failed++; continue }
    $appMods = Join-Path $env:LOCALAPPDATA 'G1RCoop\app\modules'
    Copy-Item -LiteralPath $src -Destination (Join-Path $appMods "$m.dll") -Force
    "  local copy updated"
    if ($Peer) {
        & (Join-Path $PSScriptRoot 'diag_link.ps1') upload -Peer $Peer -Port $Port -Token $Token -File $src
        if ($LASTEXITCODE -ne 0) { "  push FAILED"; $failed++ }
    }
}
if ($Peer) {
    ""
    "waiting 12 s for both games to reload..."
    Start-Sleep -Seconds 12
    & (Join-Path $PSScriptRoot 'diag_link.ps1') fetch -Peer $Peer -Port $Port -Token $Token | Out-Null
    $rep = Get-ChildItem (Join-Path $root 'native\build') -Filter 'guest_report_*.json' | Sort-Object LastWriteTime | Select-Object -Last 1
    $g = (Get-Content $rep.FullName -Raw | ConvertFrom-Json)
    # Compare CONTENT of what was just pushed, not the "this build is" line: that line is written once, when the STORY
    # module loads, so deploying npc or pose left it stale forever and this script happily printed an old MATCH
    # (2026-11-07 16:35, after an npc deploy).
    $appMods = Join-Path $env:LOCALAPPDATA 'G1RCoop\app\modules'
    $bad = 0
    foreach ($m in $build) {
        $local = Join-Path $appMods "$m.dll"
        $ls = if (Test-Path $local) { (Get-FileHash -LiteralPath $local -Algorithm SHA256).Hash.Substring(0,16) } else { '?' }
        $ge = @($g.modules | Where-Object { $_.name -eq "$m.dll" } | Select-Object -First 1)
        $gs = if ($ge.Count -and $ge[0].sha) { $ge[0].sha } else { '?' }
        if ($ls -eq $gs -and $ls -ne '?') { "  $m : MATCH ($ls)" } else { "  $m : MISMATCH (host $ls, guest $gs)"; $bad++ }
    }
    $gv = ($g.coopdll_log -split "`n" | Select-String -Pattern 'S versions: this build is' | Select-Object -Last 1)
    $hlog = Join-Path $env:LOCALAPPDATA 'G1RCoop\app\coopdll.log'
    $hv = (Select-String -LiteralPath $hlog -Pattern 'S versions: this build is' | Select-Object -Last 1)
    "fingerprint (written when the STORY module loads; may be older than this push):"
    "  host : $($hv.Line)"
    "  guest: $gv"
    if ($bad) { "RESULT: $bad module(s) differ between the copies" } else { "RESULT: every pushed module is identical on both copies" }
    if ($bad) { $failed++ }
}
if ($failed) { exit 1 } else { exit 0 }
