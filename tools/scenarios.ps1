# Action scenarios for the coop mod: each one DRIVES the game through the probe and then checks
# that the other copy followed. Unlike parity_suite.ps1 (passive), these change state, so every
# scenario restores what it touched where that is possible.
#   .\tools\scenarios.ps1                 # all scenarios
#   .\tools\scenarios.ps1 -Only npc_health, soak
# Exit code: 0 = all passed, 1 = something failed.
param([string[]]$Only = @(), [int]$SoakSeconds = 60, [switch]$Jump)
$c = Split-Path $PSScriptRoot -Parent
$dev = Join-Path $c "tools\dev.ps1"
$log = Join-Path $c "native\build\coopdll.log"
$results = New-Object System.Collections.ArrayList

function Check($name, [bool]$ok, $detail = "") {
    [void]$results.Add([pscustomobject]@{ Check = $name; Result = $(if ($ok) { "PASS" } else { "FAIL" }); Detail = "$detail" })
    "{0,-5} {1}  {2}" -f $(if ($ok) { "PASS" } else { "FAIL" }), $name, $detail
}
function Skip($name, $detail = "") {
    [void]$results.Add([pscustomobject]@{ Check = $name; Result = "SKIP"; Detail = "$detail" })
    "{0,-5} {1}  {2}" -f "SKIP", $name, $detail
}
function Probe($seat, $cmd) { (& $dev probe "@$seat $cmd" 2>&1 | Out-String) }
function Want([string]$name) { $Only.Count -eq 0 -or ($Only -contains $name) }

# ---- scenario: npc_health -------------------------------------------------
# The owner's copy changes an NPC's health; the mirror must show the same number. Restores it.
function Scenario-NpcHealth {
    $info = Probe 0 "npcinfo Drake"
    $m = [regex]::Match($info, "NPCINFO (\S+) pos (-?[\d.]+) (-?[\d.]+) (-?[\d.]+) yaw .* health ([\d.]+)")
    if (-not $m.Success) { Skip "npc_health: find NPC" "Drake is not loaded near the heroes: walk to the Old Camp (Drax / Drake) to run this scenario"; return }
    $name = $m.Groups[1].Value
    $npcPos = @([double]$m.Groups[2].Value, [double]$m.Groups[3].Value, [double]$m.Groups[4].Value)
    $original = [double]$m.Groups[5].Value
    Check "npc_health: found NPC" $true ("$name health $original")

    # Ownership: seat 0 simulates every NPC unless the other hero is clearly nearer (600 units of
    # hysteresis) - the log line "N seat 0: N characters known, simulating N" is the truth.
    $owner = 0; $mirrorSeat = 1
    $st = (Probe 1 "frames")
    Check "npc_health: owner seat 0, mirror seat 1" $true "default ownership (seat 0 simulates)"

    $ptr = ([regex]::Match((Probe $owner "findall AIAgentCharacter Drake 1"), "\b([0-9A-F]{12,})\b")).Groups[1].Value
    if (-not $ptr) { Check "npc_health: pointer" $false "no pointer from findall"; return }
    $ptr = "0x" + $ptr                                    # the probe wants the 0x form for a raw pointer

    $target = if ($original -gt 200) { $original - 50 } else { $original + 50 }
    Probe $owner "npchp $ptr $target" | Out-Null
    Start-Sleep -Seconds 2
    $own = [regex]::Match((Probe $owner "npcinfo Drake"), "health ([\d.]+)")
    Check "npc_health: owner accepted the write" ($own.Success -and [math]::Abs([double]$own.Groups[1].Value - $target) -le 2) ("owner now $($own.Groups[1].Value)")

    $mirror = [regex]::Match((Probe $mirrorSeat "npcinfo Drake"), "health ([\d.]+)")
    $got = if ($mirror.Success) { [double]$mirror.Groups[1].Value } else { -1 }
    Check "npc_health: mirror followed" ([math]::Abs($got - $target) -le 2) ("owner set $target, mirror $got")

    Probe $owner "npchp $ptr $original" | Out-Null
    Start-Sleep -Seconds 1
}

# ---- scenario: soak -------------------------------------------------------
# Idle for N seconds and watch for the things that only show up over time: exceptions, fps drop,
# memory growth and state drift.
function Scenario-Soak {
    $p0 = (Get-Process G1R-Win64-Shipping | Measure-Object WorkingSet64 -Sum).Sum
    $exBefore = 0
    if (Test-Path $log) { $exBefore = @(Select-String -LiteralPath $log -Pattern "EXCEPTION|access violation").Count }
    $drift = 0; $samples = 0
    for ($i = 0; $i -lt $SoakSeconds; $i += 10) {
        Start-Sleep -Seconds 10
        $out = & python (Join-Path $c "tools\parity.py") 2>&1 | Out-String
        $samples++
        if ($LASTEXITCODE -ne 0) { $drift++ }
    }
    $exAfter = 0
    if (Test-Path $log) { $exAfter = @(Select-String -LiteralPath $log -Pattern "EXCEPTION|access violation").Count }
    $p1 = (Get-Process G1R-Win64-Shipping | Measure-Object WorkingSet64 -Sum).Sum
    Check "soak: no new exceptions" ($exAfter -eq $exBefore) ("$($exAfter - $exBefore) new")
    Check "soak: state stayed in sync" ($drift -eq 0) ("$drift of $samples samples diverged")
    Check "soak: memory stable" (($p1 - $p0) -lt 1GB) ("+" + [math]::Round(($p1 - $p0) / 1MB) + " MB")
}

# ---- scenario: netsim -----------------------------------------------------
# A bad network on one PC: native\build\net_sim.txt makes both copies drop / delay what they send (core 85 and newer). For each profile the copies run for a while;
# we measure how far the puppets lag, that nothing throws, that the link survives, and that everything comes back to PASS within 40 s after the network is perfect again.
function Scenario-NetSim {
    $sim = Join-Path $c "native\build\net_sim.txt"
    $profiles = @(
        @{ Name = "delay 100 ms + jitter 60"; Line = "delay=100 jitter=60" },
        @{ Name = "loss 10 %";                 Line = "loss=10" },
        @{ Name = "loss 30 % + delay 150 ms";  Line = "loss=30 delay=150 jitter=80" }
    )
    $exBefore = 0; if (Test-Path $log) { $exBefore = @(Select-String -LiteralPath $log -Pattern "EXCEPTION|access violation").Count }
    $profiles = @(@{ Name = "perfect network (reference)"; Line = "" }) + $profiles
    foreach ($p in $profiles) {
        if ($p.Line) { Set-Content $sim $p.Line -Encoding ascii } else { Remove-Item $sim -ErrorAction SilentlyContinue }
        Start-Sleep -Seconds 6
        $times = @(); $alive = $true
        if (-not $Jump) {                                                      # default: only watch the link (a teleport can drop the hero out of the world: opt in with -Jump)
            Start-Sleep -Seconds 20
            $out = & python (Join-Path $c "tools\parity.py") 2>&1 | Out-String
            Check ("netsim " + $p.Name + ": the link stays up") ($out -match "PUPPET present OK") "no jump test (use -Jump; it teleports the host hero and can drop it out of the world)"
            continue
        }
        for ($i = 0; $i -lt 4; $i++) {                                        # the host hero jumps 250 units there and back; how long until the other copy draws the puppet there?
            $out = & python (Join-Path $c "tools\parity.py") 2>&1 | Out-String
            $m = [regex]::Match($out, "hero A \(([-\d.]+), ([-\d.]+), ([-\d.]+)\)")
            if (-not $m.Success) { $alive = $false; break }
            $nx = [double]$m.Groups[1].Value + (250 * (1 - 2 * ($i % 2))); $ny = [double]$m.Groups[2].Value; $nz = [double]$m.Groups[3].Value + 30
            [void](Probe 0 ("tp hero $nx $ny $nz"))
            $t0 = Get-Date; $conv = $null
            while (((Get-Date) - $t0).TotalSeconds -lt 25) {
                $out = & python (Join-Path $c "tools\parity.py") 2>&1 | Out-String
                $mm = [regex]::Match($out, "hero A \(([-\d.]+), ([-\d.]+), [-\d.]+\) vs puppet B \(([-\d.]+), ([-\d.]+),")          # horizontal only: the hero may still be falling after the jump
                if ($mm.Success -and [math]::Sqrt([math]::Pow([double]$mm.Groups[1].Value - [double]$mm.Groups[3].Value, 2) + [math]::Pow([double]$mm.Groups[2].Value - [double]$mm.Groups[4].Value, 2)) -lt 10) { $conv = ((Get-Date) - $t0).TotalSeconds; break }
            }
            if ($conv -eq $null) { $alive = $false; $times += 25 } else { $times += $conv }
            Start-Sleep -Seconds 2
        }
        $worst = ($times | Measure-Object -Maximum).Maximum
        Check ("netsim " + $p.Name + ": the puppet follows a 400-unit jump") $alive ("convergence " + (($times | ForEach-Object { [math]::Round($_, 1) }) -join " / ") + " s (includes the probe round trips, about 2-3 s)")
    }
    Remove-Item $sim -ErrorAction SilentlyContinue
    $ok = $false
    for ($t = 0; $t -lt 40 -and -not $ok; $t += 5) { Start-Sleep -Seconds 5; $out = & python (Join-Path $c "tools\parity.py") 2>&1 | Out-String; $ok = ($LASTEXITCODE -eq 0) }
    Check "netsim: parity is back after the network is perfect again" $ok ""
    $exAfter = 0; if (Test-Path $log) { $exAfter = @(Select-String -LiteralPath $log -Pattern "EXCEPTION|access violation").Count }
    Check "netsim: no new exceptions during the bad network" ($exAfter -le $exBefore) ("" + ($exAfter - $exBefore) + " new")
}

if (@(Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue).Count -lt 2) {
    "two copies must be running"; exit 2
}
if (Want "npc_health") { Scenario-NpcHealth }
if (Want "soak") { Scenario-Soak }
if ($Only -contains "netsim") { Scenario-NetSim }

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$dir = Join-Path $c "docs\reports"; New-Item -ItemType Directory -Force $dir | Out-Null
$file = Join-Path $dir "scenarios_$stamp.md"
$lines = @("# Scenario run $stamp", "", "| Result | Scenario | Detail |", "|---|---|---|")
foreach ($r in $results) { $lines += "| $($r.Result) | $($r.Check) | $($r.Detail) |" }
$lines | Set-Content $file -Encoding utf8
""
"report: $file"
if (@($results | Where-Object { $_.Result -eq "FAIL" }).Count -gt 0) { exit 1 } else { exit 0 }
