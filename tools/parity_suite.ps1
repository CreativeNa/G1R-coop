# Parity suite: the passive regression run for the coop mod.
# Starts nothing and changes nothing: it asks both running copies for their canonical state, compares
# them, scans the log for exceptions and fps, and writes one report with PASS/FAIL per check.
#   .\tools\parity_suite.ps1                 # both copies must be running
#   .\tools\parity_suite.ps1 -Start          # start them first (start_coop_11.ps1)
#   .\tools\parity_suite.ps1 -Watch 5        # keep checking and report every transition
# Exit code: 0 = all checks passed, 1 = something failed.
param([switch]$Start, [int]$Watch = 0, [string]$Report = "")
$c = Split-Path $PSScriptRoot -Parent
$log = Join-Path $c "native\build\coopdll.log"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
if (-not $Report) { $Report = "parity_$stamp" }
$results = New-Object System.Collections.ArrayList
function Check($name, [bool]$ok, $detail = "") {
    [void]$results.Add([pscustomobject]@{ Check = $name; Result = $(if ($ok) { "PASS" } else { "FAIL" }); Detail = "$detail" })
    "{0,-5} {1}  {2}" -f $(if ($ok) { "PASS" } else { "FAIL" }), $name, $detail
}

function Copies { Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue }

if ($Start) {
    if (Copies) { "a copy is already running, using it" }
    else { & (Join-Path $c "tools\start_coop_11.ps1") | Select-Object -Last 2; Start-Sleep -Seconds 90 }
}

function RunOnce {
    $results.Clear()
    $procs = @(Copies)
    Check "two copies running" ($procs.Count -ge 2) ("found " + $procs.Count)
    if ($procs.Count -lt 2) { return }

    # 1. canonical state comparison (puppet, camera, chests, NPC, inventory)
    $out = & python (Join-Path $c "tools\parity.py") 2>&1 | Out-String
    $code = $LASTEXITCODE
    $sections = ($out -split "`n" | Where-Object { $_ -match "^\s+\S+\s+(OK|DIFF)" }) -join "; "
    Check "state parity" ($code -eq 0) ($sections.Trim() -replace "\s+", " ")

    # 2. fps of both copies
    foreach ($seat in 0, 1) {
        $r = & (Join-Path $c "tools\dev.ps1") probe "@$seat fps" 2>&1 | Out-String
        $m = [regex]::Match($r, "fps\s+([\d.]+)")
        $fps = if ($m.Success) { [double]$m.Groups[1].Value } else { 0 }
        Check "fps seat $seat >= 5" ($fps -ge 5) "$fps (background windows are throttled; not a hard signal)"
    }

    # 3. exceptions NEW since the previous run. The mod already carries known, caught access
    # violations (K2_AttachToComponent); counting the whole log would make this gate permanently
    # red and therefore ignored. The marker file remembers how far the log was checked.
    $marker = Join-Path $c "native\build\parity_lastline.txt"
    $from = 0
    if (Test-Path $marker) { $from = [int](Get-Content $marker -ErrorAction SilentlyContinue) }
    $all = @()
    if (Test-Path $log) { $all = @(Get-Content -LiteralPath $log) }
    if ($from -gt $all.Count) { $from = 0 }                      # the log was rotated: start over
    $new = if ($all.Count -gt $from) { $all[$from..($all.Count - 1)] } else { @() }
    $ex = @($new | Select-String -Pattern "EXCEPTION|access violation" -ErrorAction SilentlyContinue)
    $known = @($ex | Where-Object { $_.Line -match "K2_AttachToComponent" })
    $unknown = @($ex | Where-Object { $_.Line -notmatch "K2_AttachToComponent" })
    Check "no new unknown exceptions" ($unknown.Count -eq 0) ("$($unknown.Count) unknown, $($known.Count) known (K2_AttachToComponent), $($all.Count) lines in the log")
    if ($unknown.Count -gt 0) { $unknown | Select-Object -Last 3 | ForEach-Object { "      " + $_.Line.Trim() } }
    $all.Count | Set-Content $marker -Encoding ascii

    # 4. corpse pose: if one copy bone-drives a defeated NPC, the other must be APPLYING it.
    # The npc module prints both numbers in its periodic line, so no extra probing is needed.
    $nf = @{}; $np = @{}
    foreach ($seat in 0, 1) {
        $hit = @(Select-String -LiteralPath $log -Pattern "N seat ${seat}: .*bone-driven here (\d+), bone-driven mirrors applied (\d+)" -ErrorAction SilentlyContinue |
                 Select-Object -Last 1)
        if ($hit -and $hit.Line -match "bone-driven here (\d+), bone-driven mirrors applied (\d+)") {
            $nf[$seat] = [int]$Matches[1]; $np[$seat] = [int]$Matches[2]
        }
    }
    if ($nf.Count -lt 2) {
        Check "corpse pose mirrored" $true "no stat line in this log yet"
    } elseif (($nf[0] + $nf[1]) -eq 0) {
        Check "corpse pose mirrored" $true "no defeated NPC right now, nothing to mirror"
    } else {
        $ok = (($nf[0] -eq 0) -or ($np[1] -gt 0)) -and (($nf[1] -eq 0) -or ($np[0] -gt 0))
        Check "corpse pose mirrored" $ok ("bone-driven here $($nf[0])/$($nf[1]), applied $($np[0])/$($np[1])")
    }
}

if ($Watch -le 0) {
    RunOnce
} else {
    "watching every $Watch s, Ctrl-C stops"
    $last = ""
    while ($true) {
        RunOnce
        $state = ($results | ForEach-Object { $_.Check + "=" + $_.Result }) -join "|"
        if ($state -ne $last) { "--- " + (Get-Date -Format "HH:mm:ss") + " ---"; $last = $state }
        Start-Sleep -Seconds $Watch
    }
}

$dir = Join-Path $c "docs\reports"; New-Item -ItemType Directory -Force $dir | Out-Null
$file = Join-Path $dir "$Report.md"
$lines = @("# Parity suite $stamp", "", "| Result | Check | Detail |", "|---|---|---|")
foreach ($r in $results) { $lines += "| $($r.Result) | $($r.Check) | $($r.Detail) |" }
$lines | Set-Content $file -Encoding utf8
""
"report: $file"
$failed = @($results | Where-Object { $_.Result -eq "FAIL" }).Count
if ($failed -gt 0) { exit 1 } else { exit 0 }
