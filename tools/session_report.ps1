# Session report: merges every blackbox history file (all recorder restarts) and the logs into one markdown page.
#   .\tools\session_report.ps1 [-Out docs\reports\session.md] [-Peer x.x.x.x]
# It changes nothing; the guest is only read through the diagnostic bridge.
# Written for the two-hour checkpoint of 2026-11-07 and kept because the merge matters: a recorder restart is normal and
# taking only the newest jsonl throws the earlier samples away.
# Runs at the two-hour mark of the session and writes the 12A summary (memory, fps, missing, exceptions, log size).
param(
    [string]$Out = '',
    [string]$Peer = ''
)
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if (-not $Out) { $Out = Join-Path $root ('docs\reports\session_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.md') }
$out = $Out
$log = Join-Path $env:LOCALAPPDATA 'G1RCoop\app\coopdll.log'

$f = Get-ChildItem (Join-Path $root 'native\build') -Filter 'blackbox_*.jsonl' | Sort-Object LastWriteTime | Select-Object -Last 1
$rows = @()
# merge EVERY recorder file: restarts happen (a code change needs one), and taking only the newest file threw the earlier
# samples away. Dedupe by the sample time, then sort.
$seen = @{}
$files = @(Get-ChildItem (Join-Path $root 'native\build') -Filter 'blackbox_*.jsonl' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime)
foreach ($file in $files) {
    foreach ($line in (Get-Content $file.FullName -ErrorAction SilentlyContinue)) {
        try { $o = $line | ConvertFrom-Json } catch { continue }
        if (-not $o.t) { continue }
        if ($seen.ContainsKey($o.t)) { continue }
        $seen[$o.t] = 1
        $rows += $o
    }
}
$rows = @($rows | Sort-Object { $_.t })
$fps = @($rows | ForEach-Object { $_.seats[0].fps } | Where-Object { $_ })
$hmem = @($rows | ForEach-Object { $_.seats[0].mem_mb } | Where-Object { $_ })
$exc = @($rows | ForEach-Object { $_.exceptions })
# problems only from 16:31 on: the recorders before that had the "count exceptions from zero" bug and reported the whole
# history as new. Keeping them would put two false anomalies into the final report.
$probs = @($rows | Where-Object { $_.t -ge '16:31' } | ForEach-Object { @($_.problems) } | Where-Object { $_ })

$p = Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue
$mem = if ($p) { [math]::Round($p.WorkingSet64 / 1MB, 0) } else { 0 }
$logMb = if (Test-Path $log) { [math]::Round((Get-Item $log).Length / 1MB, 1) } else { 0 }

$all = if (Test-Path $log) { @(Get-Content $log -Tail 8000) } else { @() }
$miss = @($all | Where-Object { $_ -match 'N seat 0: .*missing (\d+)' } | ForEach-Object { [int]$Matches[1] })
$costLine = ($all | Where-Object { $_ -match 'M cost ms' } | Select-Object -Last 1)
$hostExc = @($all | Where-Object { $_ -match 'EXCEPTION' }).Count
$startLine = ($all | Where-Object { $_ -match '==== coopdll N1 start, pid (\d+)' } | Select-Object -Last 1)
$sessionPid = if ($startLine -and $startLine -match 'pid (\d+)') { $Matches[1] } else { '' }
$sessionStart = if ($startLine -and $startLine -match ('^\[' + $sessionPid + ' (\d\d:\d\d)')) { $Matches[1] } else { '' }
$hostSes = if ($sessionPid) { @($all | Where-Object { $_ -match ('^\[' + $sessionPid + ' ') }) } else { @() }
$hostExc = @($hostSes | Where-Object { $_ -match 'EXCEPTION' }).Count
$hostExcNote = if ($sessionPid) { "pid $sessionPid" } else { 'no session marker found' }
$probsAll = @($rows | ForEach-Object { @($_.problems) } | Where-Object { $_ })
$probsClosed = @($probsAll | Where-Object { $_ -match 'no game copy is running' }).Count
$probs = @($rows |
    Where-Object { -not $sessionStart -or $_.t -ge $sessionStart } |
    ForEach-Object { @($_.problems) } |
    Where-Object { $_ } |
    Where-Object { $_ -notmatch 'no game copy is running' })

$guestLine = 'guest report: n/a'
try {
    if ($Peer) { & (Join-Path $root 'tools\diag_link.ps1') fetch -Peer $Peer | Out-Null }
    $r = Get-ChildItem (Join-Path $root 'native\build') -Filter 'guest_report_*.json' | Sort-Object LastWriteTime | Select-Object -Last 1
    if ($r) {
        $j = Get-Content $r.FullName -Raw | ConvertFrom-Json
        $gm = @(($j.coopdll_log -split "`n") | Where-Object { $_ -match 'N seat 1: .*missing (\d+)' } | ForEach-Object { [int]$Matches[1] })
        $gex = @(($j.coopdll_log -split "`n") | Where-Object { $_ -match 'EXCEPTION' }).Count
        $gmem = ($j.processes | Select-Object -First 1).memory_mb
        $guestLine = "guest: $($gmem) MB, EXCEPTION $gex, missing first=$($gm[0]) last=$($gm[-1]) max=$(($gm | Measure-Object -Maximum).Maximum)"
    }
} catch { $guestLine = "guest report failed: $($_.Exception.Message)" }

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('# Session at the two-hour mark - 2026-11-07')
[void]$sb.AppendLine()
[void]$sb.AppendLine("written by tools/blackbox + a delayed collector at $(Get-Date -Format 'HH:mm')")
[void]$sb.AppendLine()
[void]$sb.AppendLine('## Host')
[void]$sb.AppendLine()
[void]$sb.AppendLine("- blackbox samples: $($rows.Count) из $($files.Count) файлов, с $($rows[0].t) по $($rows[-1].t)")
if ($fps.Count) { [void]$sb.AppendLine("- fps: samples $($fps.Count), min $(($fps | Measure-Object -Minimum).Minimum), avg $([math]::Round(($fps | Measure-Object -Average).Average,1)), max $(($fps | Measure-Object -Maximum).Maximum)") }
if ($hmem.Count) { [void]$sb.AppendLine("- память по записям рекордера: samples $($hmem.Count), min $(($hmem | Measure-Object -Minimum).Minimum) MB, max $(($hmem | Measure-Object -Maximum).Maximum) MB") }
[void]$sb.AppendLine("- problems in this session: $($probs.Count) $(if ($probs.Count) { '(' + (($probs | Select-Object -Unique) -join '; ') + ')' })")
if ($probsClosed) { [void]$sb.AppendLine("- samples taken while the game was closed: $probsClosed (a gap, not a fault)") }
[void]$sb.AppendLine("- EXCEPTION in this session: $hostExc ($hostExcNote)")
[void]$sb.AppendLine("- память процесса: $mem MB, лог: $logMb MB")
[void]$sb.AppendLine("- missing (хвост 8000 строк): first=$($miss[0]) last=$($miss[-1]) max=$(($miss | Measure-Object -Maximum).Maximum)")
[void]$sb.AppendLine("- последняя строка стоимости: ``$($costLine)``")
$gfps = @($rows | ForEach-Object { $_.guest.fps } | Where-Object { $_ })
$gmem = @($rows | ForEach-Object { $_.guest.memory_mb } | Where-Object { $_ })
$gmiss = @($rows | ForEach-Object { $_.guest.missing } | Where-Object { $null -ne $_ })
$gbad = @($rows | ForEach-Object { $_.guest.error } | Where-Object { $_ })
if ($gfps.Count) {
    [void]$sb.AppendLine("- гость по записям рекордера ($($gfps.Count) сэмплов): fps min $(($gfps | Measure-Object -Minimum).Minimum) / avg $([math]::Round(($gfps | Measure-Object -Average).Average,1)) / max $(($gfps | Measure-Object -Maximum).Maximum), память $((($gmem | Measure-Object -Minimum).Minimum))-$((($gmem | Measure-Object -Maximum).Maximum)) MB, missing max $(($gmiss | Measure-Object -Maximum).Maximum)")
}
if ($gbad.Count) { [void]$sb.AppendLine("- гость: мост не ответил $($gbad.Count) раз") }
[void]$sb.AppendLine()
[void]$sb.AppendLine('## Guest')
[void]$sb.AppendLine()
[void]$sb.AppendLine($guestLine)
[void]$sb.AppendLine()
[void]$sb.AppendLine('## Verdict')
[void]$sb.AppendLine()
[void]$sb.AppendLine('Пункт 12A: сессия 2+ часа - см. цифры выше; критерий: fps не падает ниже 15, исключений нет, `missing` не растёт, память в пределах обычных ~7 ГБ игры.')
Set-Content -LiteralPath $out -Value $sb.ToString() -Encoding UTF8
Write-Output "written: $out"
