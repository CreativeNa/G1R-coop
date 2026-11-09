# Scenario: acknowledged events under a bad network (core 85+). On a lossy, delayed link the host hero is killed with the test aid; the guest hero must die too
# (shared death) and, when the death screen's "load last save" is started on the host, the guest must load as well (synced load). Both events travel on the
# acknowledged list, so they must arrive even with 30 % loss. WARNING: it kills both heroes and reloads the last save (state since that save is lost).
#   .\tools\scenario_netevents.ps1 [-Loss 30] [-Delay 100] [-Jitter 60]
# Exit code: 0 = all passed, 1 = something failed, 2 = no two copies running.
param([int]$Loss = 30, [int]$Delay = 100, [int]$Jitter = 60)
$c = Split-Path $PSScriptRoot -Parent
$dev = Join-Path $c "tools\dev.ps1"
$log = Join-Path $c "native\build\coopdll.log"
$sim = Join-Path $c "native\build\net_sim.txt"
$give = Join-Path $c "native\build\give_host.txt"
if (@(Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue).Count -lt 2) { "two copies must be running"; exit 2 }
$failed = 0
function Check($name, [bool]$ok, $detail = "") { if (-not $ok) { $script:failed++ }; "{0,-5} {1}  {2}" -f $(if ($ok) { "PASS" } else { "FAIL" }), $name, $detail }
function Probe($seat, $cmd) { (& $dev probe "@$seat $cmd" 2>&1 | Out-String) }
function LogCount($pattern) { @(Select-String -LiteralPath $log -Pattern $pattern -ErrorAction SilentlyContinue).Count }
function WaitFor($pattern, $base, $seconds) {
    $t0 = Get-Date
    while (((Get-Date) - $t0).TotalSeconds -lt $seconds) { if ((LogCount $pattern) -gt $base) { return ((Get-Date) - $t0).TotalSeconds }; Start-Sleep -Milliseconds 500 }
    return $null
}

Set-Content $sim "loss=$Loss delay=$Delay jitter=$Jitter" -Encoding ascii
Start-Sleep -Seconds 6
$diedBase = LogCount "the friend died, this hero is killed too"
$t = Get-Date
Set-Content $give "killme" -Encoding ascii
$kill = WaitFor "the friend died, this hero is killed too" $diedBase 45
Check "netevents: the guest dies when the host dies (loss $Loss %, delay $Delay ms)" ($kill -ne $null) $(if ($kill -ne $null) { "{0:N1} s" -f $kill } else { "no death on the other copy within 45 s" })

if ($kill -ne $null) {
    Start-Sleep -Seconds 12                                                   # the death screen needs a moment to appear
    $o = Probe 0 "findall W_GameOverMenu_C"
    $ptr = ([regex]::Match($o, "(?m)^\s+([0-9A-F]{12,16}) W_GameOverMenu_C_")).Groups[1].Value
    if (-not $ptr) { Check "netevents: death screen found on the host" $false "no W_GameOverMenu_C instance" }
    else {
        $loadBase = LogCount "the friend loaded the last save from the death screen"
        [void](Probe 0 ("call 0x$ptr GameOverWidget LoadLastSave"))
        $ld = WaitFor "the friend loaded the last save from the death screen" $loadBase 60
        Check "netevents: the guest loads the last save when the host does" ($ld -ne $null) $(if ($ld -ne $null) { "{0:N1} s" -f $ld } else { "the other copy did not load within 60 s" })
    }
}
Remove-Item $sim -ErrorAction SilentlyContinue
"waiting for both heroes to be back (up to 120 s) ..."
$ok = $false
for ($i = 0; $i -lt 24 -and -not $ok; $i++) { Start-Sleep -Seconds 5; $out = & python (Join-Path $c "tools\parity.py") 2>&1 | Out-String; $ok = ($LASTEXITCODE -eq 0) }
Check "netevents: both copies are in sync again after the reload" $ok ""
""
if ($failed -gt 0) { "RESULT: FAIL ($failed)"; exit 1 } else { "RESULT: PASS"; exit 0 }
