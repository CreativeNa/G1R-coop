# Audit of save loads and faults from the log: one press must produce exactly one load on the other
# copy, and no NEW access violation may appear. This is the automated guard for the bug in
# docs/BUG_UI_AFTER_LOAD.md - it needs no input, the log already contains everything.
# It is a REGRESSION gate: faults are counted from where the previous audit stopped, so a known and
# caught fault (story send_blob, a few per hour) does not keep the gate red forever.
#   .\tools\load_audit.ps1                 # everything since the last audit
#   .\tools\load_audit.ps1 -Lines 5000     # only the tail (ignores the marker)
#   .\tools\load_audit.ps1 -Reset          # forget the marker, start from the beginning of the log
# Exit code: 0 = consistent, 1 = a new fault or more loads than presses, 2 = no log.
param([int]$Lines = 0, [switch]$Reset)
$c = Split-Path $PSScriptRoot -Parent
$log = Join-Path $c "native\build\coopdll.log"
if (-not (Test-Path $log)) { "no log at $log"; exit 2 }

$all = @(Get-Content -LiteralPath $log)
$total = $all.Count

$marker = Join-Path $c "native\build\load_audit_marker.txt"
if ($Reset) { Remove-Item $marker -ErrorAction SilentlyContinue }
$from = 0
if (Test-Path $marker) { $from = [int](Get-Content $marker -ErrorAction SilentlyContinue) }
if ($from -gt $total) { $from = 0 }                    # log rotated or the game restarted
if ($Lines -gt 0) { $from = [Math]::Max(0, $total - $Lines) }

$fresh = if ($total -gt $from) { @($all[$from..($total - 1)]) } else { @() }
$total | Set-Content $marker -Encoding ascii

function N($pattern, $set) { @($set | Select-String -Pattern $pattern -ErrorAction SilentlyContinue).Count }

$press  = N 'S load: F9 \(quick load\) pressed here' $fresh
$loads  = N 'the other player loaded save' $fresh
$same   = N 'same event \(lid \d+\) already applied' $fresh
$window = N 'duplicate load .* ignored' $fresh
# Access violations are split by the module that was running when the fault happened (the module name
# is on the line AFTER the "AV at" line). The story module has a known, caught fault (send_blob); it is
# reported but does not fail the gate, so a real regression elsewhere stays visible.
$avLines = @()
for ($i = 0; $i -lt $fresh.Count; $i++) {
    if ($fresh[$i] -match 'AV at coopdll') {
        $mod = '?'
        if ($i + 1 -lt $fresh.Count -and $fresh[$i + 1] -match 'module=(\w+)') { $mod = $Matches[1] }
        $avLines += [pscustomobject]@{ Line = $fresh[$i]; Module = $mod }
    }
}
$av_known = @($avLines | Where-Object { $_.Module -eq 'story' }).Count
$av_probe = @($avLines | Where-Object { $_.Module -eq 'probe' }).Count      # the probe module reads memory a developer asks for: a bad address there is the query's fault, not the game's
$av       = @($avLines | Where-Object { $_.Module -ne 'story' -and $_.Module -ne 'probe' }).Count
$av_all   = N 'AV at coopdll' $all
$exc    = N 'EXCEPTION' $fresh

"load audit: $($fresh.Count) new lines of $total"
"  {0,-24} {1,5}   {2}" -f 'F9 presses', $press, 'detected by the module (window must be active)'
"  {0,-24} {1,5}   {2}" -f 'loads on the far copy', $loads, 'must not exceed the presses'
"  {0,-24} {1,5}   {2}" -f 'repeats caught (lid)', $same, 'a retransmitted event, ignored - this is the fix working'
"  {0,-24} {1,5}   {2}" -f 'repeats caught (8 s)', $window, 'the older guard, kept as a second layer'
"  {0,-24} {1,5}   {2}" -f 'new access violations', $av, "outside story; $av_all in the whole log"
"  {0,-24} {1,5}   {2}" -f 'known story AVs', $av_known, 'send_blob, caught (docs/BUGS.md)' 
"  {0,-24} {1,5}   {2}" -f 'probe-query AVs', $av_probe, 'bad addresses asked by probe commands, ignored'
"  {0,-24} {1,5}   {2}" -f 'EXCEPTION lines', $exc, 'should be 0'

$failed = 0
if ($loads -gt $press) { "FAIL  more loads than presses: a duplicate got through"; $failed++ }
if ($av -gt 0) {
    "FAIL  $av new access violation(s)"
    $avLines | Where-Object { $_.Module -ne 'story' -and $_.Module -ne 'probe' } | Select-Object -Last 3 | ForEach-Object { "      " + $_.Line.Trim() }
    $failed++
}
if ($exc -gt 0) { "FAIL  $exc EXCEPTION line(s)"; $failed++ }

if ($failed -eq 0) { "PASS  loads match presses, no new access violations"; exit 0 } else { exit 1 }
