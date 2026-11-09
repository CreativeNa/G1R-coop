# Adds or removes the Windows Firewall rules the co-op needs, so the friend can actually reach this PC.
# Run as administrator (the script says so and prints the exact command when it is not).
#
#   .\tools\firewall_coop.ps1 -Action add      # UDP 40001-40002 (game, discovery) + TCP 40003-40004 (saves, diagnostics)
#   .\tools\firewall_coop.ps1 -Action remove
#   .\tools\firewall_coop.ps1 -Action show
#
# The rules are scoped to the game executable, not to every program: only Gothic 1 Remake gets them.
param(
    [ValidateSet("add", "remove", "show")][string]$Action = "show",
[int[]]$Port = @(40001, 40002, 40003, 40004),   # UDP 40001 game, UDP 40002 discovery, TCP 40003 saves, TCP 40004 diagnostics
    [string]$GameExe = "C:\Program Files (x86)\Steam\steamapps\common\Gothic 1 Remake\G1R\Binaries\Win64\G1R-Win64-Shipping.exe"
)
$ErrorActionPreference = "Stop"
$name = "Gothic 1 Remake co-op"

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if ($Action -eq "show") {
    $rules = Get-NetFirewallRule -DisplayName "$name*" -ErrorAction SilentlyContinue
    if (-not $rules) { "no rules of this mod exist yet"; exit 0 }
    $rules | ForEach-Object {
        $pf = $_ | Get-NetFirewallPortFilter
        "{0,-28} {1,-6} {2,-4} {3}" -f $_.DisplayName, $_.Direction, $_.Action, ($pf.Protocol + " " + ($pf.LocalPort -join ','))
    }
    exit 0
}

if (-not (Test-Admin)) {
    "this needs administrator rights. Open PowerShell as administrator and run:"
    "  cd `"$(Split-Path -Parent $PSScriptRoot)`""
    "  .\tools\firewall_coop.ps1 -Action $Action"
    exit 1
}
if (-not (Test-Path $GameExe)) { "game executable not found: $GameExe (pass -GameExe)"; exit 1 }

if ($Action -eq "remove") {
    Get-NetFirewallRule -DisplayName "$name*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule
    "removed the co-op firewall rules"
    exit 0
}

$udp = @($Port | Where-Object { $_ -le 40002 })     # the game's traffic and the host discovery probe
$tcp = @($Port | Where-Object { $_ -ge 40003 })     # save transfer and the diagnostic bridge
if ($udp.Count) {
    Remove-NetFirewallRule -DisplayName "$name (UDP)" -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "$name (UDP)" -Direction Inbound -Action Allow -Protocol UDP `
        -LocalPort $udp -Program $GameExe -Profile Any -Description "co-op position, events and trades" | Out-Null
    "UDP $($udp -join ',') allowed for the game"
}
if ($tcp.Count) {
    Remove-NetFirewallRule -DisplayName "$name (save sync)" -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "$name (save sync)" -Direction Inbound -Action Allow -Protocol TCP `
        -LocalPort $tcp -Profile Any -Description "savesync.ps1 hands the save games over" | Out-Null
    "TCP $($tcp -join ',') allowed (save sync and the diagnostic bridge)"
}
"done. This PC is reachable on the addresses listed by: Get-NetIPAddress -AddressFamily IPv4"
