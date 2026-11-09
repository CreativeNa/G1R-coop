# One command to run after any change to the coop mod.
#   .\tools\check.ps1            # parity gate + the npc_health scenario
#   .\tools\check.ps1 -Soak 60   # ... and a 60 s soak
#   .\tools\check.ps1 -Quick     # parity gate only
# Exit code: 0 = everything passed, 1 = something failed, 2 = no two copies running.
param([switch]$Quick, [int]$Soak = 0)
$c = Split-Path $PSScriptRoot -Parent
if (@(Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue).Count -lt 2) {
    "two copies must be running (tools\start_coop_11.ps1)"; exit 2
}

$failed = 0
"=== parity gate ==="
& (Join-Path $c "tools\parity_suite.ps1") | ForEach-Object { $_ }
if ($LASTEXITCODE -ne 0) { $failed++ }

"`n=== load audit (log) ==="
& (Join-Path $c "tools\load_audit.ps1") | ForEach-Object { $_ }   # incremental: only new faults count
if ($LASTEXITCODE -ne 0) { $failed++ }

if (-not $Quick) {
    "`n=== scenario: npc_health ==="
    & (Join-Path $c "tools\scenarios.ps1") -Only npc_health | ForEach-Object { $_ }
    if ($LASTEXITCODE -ne 0) { $failed++ }
}

if ($Soak -gt 0) {
    "`n=== soak ${Soak}s ==="
    & (Join-Path $c "tools\scenarios.ps1") -Only soak -SoakSeconds $Soak | ForEach-Object { $_ }
    if ($LASTEXITCODE -ne 0) { $failed++ }
}

""
if ($failed -gt 0) { "RESULT: FAIL ($failed block(s) failed)"; exit 1 } else { "RESULT: PASS"; exit 0 }
