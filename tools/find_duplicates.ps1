# Finds the "the same script fired on both copies" pattern: identical event text applied on BOTH copies inside a short
# window. That is how the known bug looks (an NPC script written for one player runs twice - a reminder, an ore demand, a
# gate check), and it is invisible in a single log because each copy legitimately sees its own event.
#
#   .\tools\find_duplicates.ps1 -Peer x.x.x.x                    # pulls the guest log through the bridge
#   .\tools\find_duplicates.ps1 -GuestReport native\build\guest_report_<stamp>.json
#   .\tools\find_duplicates.ps1 -Peer ... -WindowSeconds 8 -Gate 0   # exit 1 if any pair is found
#
# It is a FINDER, not a verdict: in a co-op session some events really are applied on both copies (quest state, story
# words). The report separates "applied on both within N seconds" from "retried on one copy" (those carry
# "(dropped: seen already)" and are the ack system working).
#
# Exit code: 0 = nothing suspicious (or no -Gate), 1 = -Gate was exceeded, 2 = no data.
param(
    [string]$Peer = '',
    [string]$GuestReport = '',
    [int]$Port = 40004,
    [string]$Token = '',
    [string]$HostLog = (Join-Path $env:LOCALAPPDATA 'G1RCoop\app\coopdll.log'),
    [int]$WindowSeconds = 6,
    [int]$Top = 15,
    [int]$Gate = -1,
    # These are mirrored on purpose (fingerprint exchange, light, clock, shared load); the finder skips them unless asked.
    [switch]$IncludeExpected
)
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot

if (-not (Test-Path -LiteralPath $HostLog)) { "host log not found: $HostLog"; exit 2 }
$hostLines = Get-Content -LiteralPath $HostLog -Tail 6000 -ErrorAction SilentlyContinue

$guestLines = @()
if ($GuestReport) {
    if (-not (Test-Path -LiteralPath $GuestReport)) { "guest report not found: $GuestReport"; exit 2 }
    $guestLines = @((Get-Content -LiteralPath $GuestReport -Raw | ConvertFrom-Json).coopdll_log -split "`r?`n")
} elseif ($Peer) {
    $link = Join-Path $PSScriptRoot 'diag_link.ps1'
    if (-not (Test-Path -LiteralPath $link)) { "diag_link.ps1 missing"; exit 2 }
    & $link fetch -Peer $Peer -Port $Port -Token $Token -LogLines 6000 | Out-Null
    $rep = Get-ChildItem (Join-Path $root 'native\build') -Filter 'guest_report_*.json' |
           Sort-Object LastWriteTime | Select-Object -Last 1
    if (-not $rep) { "the bridge saved no report"; exit 2 }
    $guestLines = @((Get-Content -LiteralPath $rep.FullName -Raw | ConvertFrom-Json).coopdll_log -split "`r?`n")
} else { "give -Peer or -GuestReport"; exit 2 }

# "[pid 12:34:56.789] S event in: type 15 'quest|name' lid 123 (new)" -> time + the event text without the per-copy noise
function Parse-Events($lines) {
    $out = @()
    foreach ($l in $lines) {
        if ($l -notmatch '^\[(\d+)\s+(\d\d):(\d\d):(\d\d)') { continue }
        $t = [int]$Matches[2] * 3600 + [int]$Matches[3] * 60 + [int]$Matches[4]
        if ($l -match 'S event in: type (\d+) ''([^'']*)''.*\(new\)') {
            $out += [pscustomobject]@{ t = $t; key = "type $($Matches[1]): $($Matches[2])" }
        } elseif ($l -match 'S trade: trader #(\d+) matched by item') {
            $out += [pscustomobject]@{ t = $t; key = "trade stock apply on trader #$($Matches[1])" }
        } elseif ($l -match 'S (poly|light|death|load): ([^,]{0,80})') {
            $out += [pscustomobject]@{ t = $t; key = "S $($Matches[1]): $(($Matches[2] -replace '\d+','N').Trim())" }
        }
    }
    return , $out
}

$he = Parse-Events $hostLines
$ge = Parse-Events $guestLines
"host events: $($he.Count), guest events: $($ge.Count), window: ${WindowSeconds}s"

$pairs = @()
foreach ($h in $he) {
    foreach ($g in $ge) {
        if ($h.key -ne $g.key) { continue }
        $d = [Math]::Abs($h.t - $g.t)
        if ($d -le $WindowSeconds) { $pairs += [pscustomobject]@{ Key = $h.key; Seconds = $d } }
    }
}
$expected = 'type 28|type 27|type 22|^S load|^S light|^S time'
if (-not $IncludeExpected) {
    $before = $pairs.Count
    $pairs = @($pairs | Where-Object { $_.Key -notmatch $expected })
    if ($before -ne $pairs.Count) { "skipped $($before - $pairs.Count) pair(s) that are mirrored on purpose (fingerprint, light, clock, shared load) - use -IncludeExpected to see them" }
}
$grouped = $pairs | Group-Object Key | Sort-Object Count -Descending

if (-not $grouped) {
    "no event was applied on both copies inside ${WindowSeconds}s"
    exit 0
}

"the same event reached both copies (candidate double-fire, review before calling it a bug):"
$grouped | Select-Object -First $Top | ForEach-Object {
    "  {0,3}x  {1}" -f $_.Count, $_.Name
}
$worse = @($grouped | Where-Object { $_.Count -ge 2 }).Count
"keys seen more than once: $worse"

if ($Gate -ge 0 -and $grouped.Count -gt $Gate) {
    "GATE exceeded: $($grouped.Count) candidate keys (limit $Gate)"
    exit 1
}
exit 0
