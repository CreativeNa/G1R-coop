# Black box for a co-op session: keeps a rolling history and writes a report when something goes wrong.
#
#   .\tools\blackbox.ps1                  # follow a running session until Ctrl+C
#   .\tools\blackbox.ps1 -Interval 5      # sample every 5 s instead of 10
#
# What it watches, because none of it is visible while playing:
#   * a copy disappears (crash) or stays alive but stops writing to its log (freeze);
#   * the frame rate falls below -FpsFloor;
#   * a new EXCEPTION appears in the log;
#   * the canonical state of the two copies diverges (NPC positions/health, via diff_npcs.ps1).
#
# History: native\build\blackbox_<time>.jsonl (one JSON line per sample, easy to grep later).
# Report:  native\build\blackbox_report_<time>.md (state + the last 200 lines of each copy + a copy of the log),
#          written as soon as an anomaly is seen and again on exit.
param(
    [int]$Interval = 10,
    [int]$FpsFloor = 15,
    [int]$LogSilenceSeconds = 25,
    [switch]$NoProbe,
    [string]$LogPath = "",        # the core log; the launcher passes the installed one
    [string]$OutDir = "",         # where the history and reports go
    [switch]$ExitWhenNoGame,      # started by the launcher: stop by itself once the game is gone
    [switch]$QuietPass,           # nothing on the console (the launcher runs it hidden)
    # The recorder only sees processes on this PC. On a real pair the OTHER copy is behind the diagnostic bridge, so
    # every -GuestEvery samples it pulls the guest's report and records that copy's fps / missing / exceptions too.
    [string]$Peer = '',
    [int]$Port = 40004,
    [int]$GuestEvery = 10
)
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
$build = if ($OutDir) { $OutDir } else { Join-Path $root 'native\build' }
New-Item -ItemType Directory -Force $build | Out-Null
# The installed copy writes to %LOCALAPPDATA%\G1RCoop\app\coopdll.log, not into native\build. Running the recorder by
# hand (not through the launcher, which passes -LogPath) used to read a log that is not there: fps and log age came back
# empty in every sample on 2026-11-07 16:23, which made the recorder useless exactly when it was needed.
$log = if ($LogPath) { $LogPath } elseif (Test-Path (Join-Path $env:LOCALAPPDATA 'G1RCoop\app\coopdll.log')) { Join-Path $env:LOCALAPPDATA 'G1RCoop\app\coopdll.log' } else { Join-Path $build 'coopdll.log' }
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$history = Join-Path $build "blackbox_$stamp.jsonl"
$report = Join-Path $build "blackbox_report_$stamp.md"

$seats = @{}

function Get-SeatPids {
    $seats.Clear()
    $all = @(Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue)
    foreach ($p in $all) {
        $seat = -1
        if ($p.MainWindowTitle -match 'HOST') { $seat = 0 }
        elseif ($p.MainWindowTitle -match 'GUEST') { $seat = 1 }
        if ($seat -ge 0) { $seats[$seat] = $p.Id }
    }
    # the window title appears a few seconds after the process: while it is missing, one copy is still the host
    if ($seats.Count -eq 0 -and $all.Count -eq 1) { $seats[0] = $all[0].Id }
}

function Get-SeatLines([int]$procId, [int]$tail = 400) {
    if (-not (Test-Path -LiteralPath $log)) { return @() }
    return @(Get-Content -LiteralPath $log -Tail $tail -ErrorAction SilentlyContinue | Where-Object { $_ -match "^\[$procId " })
}

function Get-LogAge([int]$procId) {
    $last = Get-SeatLines $procId 300 | Select-Object -Last 1
    if (-not $last) { return -1 }        # no line from this copy yet: unknown, not "frozen" (the game was just started)
    if ($last -match '^\[\d+ (\d\d):(\d\d):(\d\d)\.') {
        $t = (Get-Date).Date.AddHours([int]$matches[1]).AddMinutes([int]$matches[2]).AddSeconds([int]$matches[3])
        return [int]((Get-Date) - $t).TotalSeconds
    }
    return -1
}

function Get-Fps([int]$procId) {
    $line = Get-SeatLines $procId 200 | Where-Object { $_ -match 'PR fps ([\d.]+)' } | Select-Object -Last 1
    if ($line -and $line -match 'PR fps ([\d.]+)') { return [double]$matches[1] }
    return $null
}

function Get-ParityMismatch {
    if ($NoProbe) { return $null }
    $tool = Join-Path $PSScriptRoot 'diff_npcs.ps1'
    if (-not (Test-Path -LiteralPath $tool)) { return $null }
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $tool -Quiet 2>&1
    return @{ exit = $LASTEXITCODE; text = (($out | Out-String).Trim() -replace '\s+', ' ') }
}

function Get-GuestSample {
    if (-not $Peer) { return $null }
    $link = Join-Path $PSScriptRoot 'diag_link.ps1'
    if (-not (Test-Path -LiteralPath $link)) { return @{ error = 'diag_link.ps1 missing' } }
    try { & $link fetch -Peer $Peer -Port $Port | Out-Null } catch { return @{ error = $_.Exception.Message } }
    $r = Get-ChildItem (Join-Path $root 'native\build') -Filter 'guest_report_*.json' -ErrorAction SilentlyContinue |
         Sort-Object LastWriteTime | Select-Object -Last 1
    if (-not $r) { return @{ error = 'the bridge saved no report' } }
    try { $j = Get-Content -LiteralPath $r.FullName -Raw | ConvertFrom-Json } catch { return @{ error = 'the report is not JSON' } }
    $gl = @($j.coopdll_log -split "`r?`n")
    $fps = $null
    $fl = $gl | Where-Object { $_ -match 'PR fps ([\d.]+)' } | Select-Object -Last 1
    if ($fl -and $fl -match 'PR fps ([\d.]+)') { $fps = [double]$matches[1] }
    $missing = $null
    $ml = $gl | Where-Object { $_ -match 'N seat 1: .*missing (\d+)' } | Select-Object -Last 1
    if ($ml -and $ml -match 'missing (\d+)') { $missing = [int]$matches[1] }
    $exc = @($gl | Where-Object { $_ -match 'EXCEPTION' }).Count
    $mem = ($j.processes | Select-Object -First 1).memory_mb
    return @{ fps = $fps; missing = $missing; exceptions = $exc; memory_mb = $mem; time = $j.time }
}

# Counting EXCEPTION by scanning the whole log every sample made the recorder fall behind its own interval once the log
# passed ~10 MB (measured 2026-11-07 17:00: 12 samples where 14 were due). Read only what was appended since the last
# sample and keep a running total instead; a truncated or rotated log resets the counter.
$excOffset = [long]0
$excCount = [long]0
function Update-Exceptions {
    if (-not (Test-Path -LiteralPath $log)) { return $excCount }
    $len = (Get-Item -LiteralPath $log).Length
    if ($len -lt $script:excOffset) { $script:excOffset = 0; $script:excCount = 0 }
    if ($len -eq $script:excOffset) { return $script:excCount }
    try {
        $fs = [IO.File]::Open($log, 'Open', 'Read', 'ReadWrite')
        [void]$fs.Seek($script:excOffset, 'Begin')
        $sr = New-Object IO.StreamReader($fs)
        $txt = $sr.ReadToEnd(); $sr.Close(); $fs.Close()
        $script:excCount += ([regex]::Matches($txt, 'EXCEPTION')).Count
        $script:excOffset = $len
    } catch { }
    return $script:excCount
}

function Get-SeatSample([int]$seat, [int]$procId) {
    $alive = [bool](Get-Process -Id $procId -ErrorAction SilentlyContinue)
    $fps = Get-Fps $procId
    $age = Get-LogAge $procId
    $pos = $null
    if (-not $NoProbe) {
        $dev = Join-Path $PSScriptRoot 'dev.ps1'
        if (Test-Path -LiteralPath $dev) {
            $h = (& $dev probe "@$seat heroinfo" 2>&1 | Where-Object { $_ -match 'HEROINFO pos' } | Select-Object -First 1)
            if ($h -and $h -match 'HEROINFO pos (-?\d+) (-?\d+) (-?\d+)') { $pos = "$($matches[1]),$($matches[2]),$($matches[3])" }
        }
    }
    $memMb = $null
    if ($alive) {
        $pr = Get-Process -Id $procId -ErrorAction SilentlyContinue
        if ($pr) { $memMb = [int]($pr.WorkingSet64 / 1MB) }
    }
    return [pscustomobject]@{ seat = $seat; pid = $procId; alive = $alive; fps = $fps; log_age = $age; pos = $pos; mem_mb = $memMb }
}

function Write-Report([string]$reason, $samples) {
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# Co-op black box report')
    $lines.Add('')
    $lines.Add("* time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    $lines.Add("* reason: **$reason**")
    $lines.Add("* history: $history")
    $lines.Add('')
    $lines.Add('## Last samples')
    $lines.Add('```')
    foreach ($s in ($samples | Select-Object -Last 12)) { $lines.Add(($s | ConvertTo-Json -Compress -Depth 6)) }
    $lines.Add('```')
    foreach ($seat in ($seats.Keys | Sort-Object)) {
        $procId = $seats[$seat]
        $lines.Add('')
        $lines.Add("## seat $seat (pid $procId) - last 200 log lines")
        $lines.Add('```')
        foreach ($l in (Get-SeatLines $procId 800 | Select-Object -Last 200)) { $lines.Add($l) }
        $lines.Add('```')
    }
    $lines.Add('')
    $lines.Add('## Full log')
    $lines.Add("copied to blackbox_report_$stamp.log")
    ($lines -join "`r`n") | Set-Content -LiteralPath $report -Encoding utf8
    if (Test-Path -LiteralPath $log) { Copy-Item -LiteralPath $log -Destination (Join-Path $build "blackbox_report_$stamp.log") -Force }
    "REPORT: $report"
}

"black box started: sample every ${Interval}s, history $history"
"acceptance: fps >= $FpsFloor, log silence <= ${LogSilenceSeconds}s"
$samples = New-Object System.Collections.Generic.List[object]
# The log is appended across sessions, so a cumulative count is not a baseline: starting at 0 reported 11945 "new"
# EXCEPTION lines on 2026-11-07 16:25 that all belonged to earlier game processes. Take the count as it is at start.
$lastExc = if (Test-Path -LiteralPath $log) { (Select-String -LiteralPath $log -Pattern 'EXCEPTION' | Measure-Object).Count } else { 0 }
# the incremental counter starts from the baseline above, so the first sample does not re-report the whole history
$excCount = [long]$lastExc
$excOffset = if (Test-Path -LiteralPath $log) { (Get-Item -LiteralPath $log).Length } else { 0 }
$reported = $false
$gone = 0
$seenAny = $false
$started = Get-Date
$lowFps = @{}
$sampleIndex = 0
$guestExcBase = $null
try {
    while ($true) {
        Get-SeatPids
        $tickNow = Get-Date
        $tick = [pscustomobject]@{
            t          = (Get-Date -Format 'HH:mm:ss')
            seats      = @()
            exceptions = 0
            parity     = $null
            problems   = @()
        }
        foreach ($seat in ($seats.Keys | Sort-Object)) {
            $tick.seats += (Get-SeatSample $seat $seats[$seat])
        }
        if (Test-Path -LiteralPath $log) { $tick.exceptions = Update-Exceptions }
        $tick.parity = Get-ParityMismatch

        # the other PC, when this is a real pair (see -Peer)
        $sampleIndex++
        if ($Peer -and $GuestEvery -gt 0 -and ($sampleIndex % $GuestEvery) -eq 0) {
            $gs = Get-GuestSample
            $tick | Add-Member -NotePropertyName guest -NotePropertyValue $gs -Force
        }

        $problems = New-Object System.Collections.Generic.List[string]
        foreach ($s in $tick.seats) {
            if (-not $s.alive) { $problems.Add("seat $($s.seat): the game is gone (crash?)") }
            elseif ($s.log_age -ge 0 -and $s.log_age -gt $LogSilenceSeconds) { $problems.Add("seat $($s.seat): no log line for $($s.log_age) s (frozen?)") }
            if ($s.fps -and $s.fps -lt $FpsFloor) {
                $lowFps[$s.seat] = 1 + [int]$lowFps[$s.seat]
                # one low sample is a load screen or a hitch; two in a row is a real problem
                if ($lowFps[$s.seat] -ge 2 -and (($tickNow - $started).TotalSeconds -gt 90)) {
                    $problems.Add("seat $($s.seat): $($s.fps) fps for $($lowFps[$s.seat]) samples")
                }
            } else {
                $lowFps[$s.seat] = 0
            }
        }
        if ($tick.seats.Count -eq 0) {
            if ($seenAny -or ((Get-Date) - $started).TotalSeconds -gt 90) { $problems.Add('no game copy is running') }
        } else { $seenAny = $true }
        if ($tick.exceptions -gt $lastExc) { $problems.Add("new EXCEPTION in the log ($lastExc -> $($tick.exceptions))") }
        if ($Peer -and $tick.guest) {
            $g = $tick.guest
            if ($g.error) { $problems.Add("guest: $($g.error)") }
            else {
                if ($null -eq $guestExcBase) { $guestExcBase = $g.exceptions }
                elseif ($g.exceptions -gt $guestExcBase) { $problems.Add("guest: new EXCEPTION ($guestExcBase -> $($g.exceptions))"); $guestExcBase = $g.exceptions }
                if ($g.fps -and $g.fps -lt $FpsFloor) { $problems.Add("guest: $($g.fps) fps") }
            }
        }
        if ($tick.parity -and $tick.parity.exit -ne 0) { $problems.Add("state parity mismatch: $($tick.parity.text)") }
        $tick.problems = @($problems)

        $samples.Add($tick)
        ($tick | ConvertTo-Json -Compress -Depth 6) | Add-Content -LiteralPath $history -Encoding utf8

        if (-not $QuietPass) {
            $status = (($tick.seats | ForEach-Object { "seat$($_.seat) pid=$($_.pid) fps=$($_.fps) log=$($_.log_age)s" }) -join '  ')
            $suffix = if ($problems.Count) { '  !! ' + ($problems -join '; ') } else { '  ok' }
            "[$($tick.t)] $status$suffix"
        }

        if ($problems.Count -and -not $reported) { Write-Report ($problems -join '; ') $samples; $reported = $true }
        $lastExc = $tick.exceptions
        if ($ExitWhenNoGame) {
            if ($tick.seats.Count -eq 0) { $gone++ } else { $gone = 0 }
            if ($gone -ge 3) { Write-Report 'the game has exited' $samples; exit 0 }
        }
        Start-Sleep -Seconds $Interval
    }
} finally {
    Write-Report 'session ended' $samples
}
