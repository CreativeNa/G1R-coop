# Snapshot of the state that could hold the white veil, for a before/after comparison:
#   .\tools\veil_snapshot.ps1 before 0      (veil is on screen on seat 0)  ->  swing the pickaxe until it is gone  ->  .\tools\veil_snapshot.ps1 after 0
# then: .\tools\veil_snapshot.ps1 diff
param([string]$Mode = "before", [int]$Seat = 0)
$root = Split-Path $PSScriptRoot -Parent
$dir = Join-Path $root "native\build\veil"
New-Item -ItemType Directory -Force $dir | Out-Null
$dev = Join-Path $PSScriptRoot "dev.ps1"
if ($Mode -eq "diff") {
    $b = Get-Content "$dir\before.txt" | Where-Object { $_ -match "prop|obj " }
    $a = Get-Content "$dir\after.txt" | Where-Object { $_ -match "prop|obj " }
    Compare-Object $b $a | ForEach-Object { "$($_.SideIndicator) $($_.InputObject)" }
    return
}
function Ptr($cls, $name) { $o = & $dev probe "@$Seat findall $cls $name 1" 2>&1 | Out-String; $m = [regex]::Match($o, '0000([0-9A-F]{12}) '); if ($m.Success) { "0x" + $m.Groups[1].Value } }
$targets = @(
    @("PlayerCameraManagerBP_C", "PlayerCameraManagerBP_C_2"),
    @("GothicHUD", "GothicHUD_2"),
    @("PlayerControllerBP_C", "PlayerControllerBP_C_2"),
    @("HUDVisibilityStateManagerSubsystem", "HUDVisibilityStateManagerSubsystem_2"),
    @("LoadingScreenHelperSubsystem", "LoadingScreenHelperSubsystem_2"),
    @("GothicCinematicManagerSubsystemScript", "GothicCinematicManagerSubsystemScript_2")
)
$cmds = @("@$Seat members hero")
foreach ($t in $targets) { $p = Ptr $t[0] $t[1]; if ($p) { $cmds += "@$Seat members $p" } else { $cmds += "@$Seat echo missing $($t[0])" } }
$out = & $dev probe @cmds 2>&1 | Out-String
# the hero's own components and its player state: their pointers are in the hero dump
$extra = @()
foreach ($n in "m_CarryComponent","m_MagicComponent","m_FXComponent","m_MaterialsComponent","m_CharacterVisualsComponent","CharacterMovement","PlayerState","Mesh","m_WalkSpeedModifierComponent","m_PerceptionComponent") {
    $m = [regex]::Match($out, "::$n \[ObjectProperty[^=]*= 0000([0-9A-F]{12}) ")
    if ($m.Success) { $extra += "@$Seat members 0x$($m.Groups[1].Value)" }
}
if ($extra.Count) { $out += & $dev probe @extra 2>&1 | Out-String }
Set-Content "$dir\$Mode.txt" $out
"snapshot '$Mode' saved: $((($out -split "`n") | Where-Object { $_ -match 'prop' }).Count) properties"
