# Collects everything a developer needs from a beta tester into ONE zip, with personal data removed.
#   .\tools\collect_logs.ps1                 # writes beta_reports\report_<time>.zip next to the mod folder
#   .\tools\collect_logs.ps1 -Note "what happened, at what time"
# Included: the tail of the mod log (IP addresses, the computer name and the Windows user name are replaced), a system summary (OS, CPU, RAM, GPU, game exe size),
# the versions (hashes) of the mod files, the role/network settings (addresses replaced), counts of the important log markers.
# NOT included: save games, screenshots, any game file, passwords, anything outside the mod folder. Read summary.txt in the zip before you send it.
param([string]$Note = "", [int]$MaxLogMB = 20, [string]$OutDir = "")
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
# Two layouts exist: the portable folder (native\build next to tools\) and the installed one (the launcher puts
# everything in %LOCALAPPDATA%\G1RCoop\app). Testers use the installer, so the installed log has to win - otherwise the
# report contains only a "no log found" stub.
$installed = Join-Path $env:LOCALAPPDATA "G1RCoop\app"
$b = if (Test-Path (Join-Path $installed "coopdll.log")) { $installed } else { Join-Path $root "native\build" }
if (-not $OutDir) { $OutDir = Join-Path $root "beta_reports" }
New-Item -ItemType Directory -Force $OutDir | Out-Null
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$work = Join-Path $env:TEMP ("coop_report_" + $stamp)
New-Item -ItemType Directory -Force $work | Out-Null

$pc = $env:COMPUTERNAME; $user = $env:USERNAME
function Scrub([string]$t) {
    if (-not $t) { return $t }
    $t = [regex]::Replace($t, "\b\d{1,3}(\.\d{1,3}){3}\b", "x.x.x.x")
    if ($pc) { $t = [regex]::Replace($t, [regex]::Escape($pc), "<PC>", "IgnoreCase") }
    if ($user) { $t = [regex]::Replace($t, [regex]::Escape($user), "<USER>", "IgnoreCase") }
    return $t
}

# ---- the mod log: the last $MaxLogMB megabytes, scrubbed ----
# The log lives inside app\, which the installer replaces on every update. The installer keeps the previous log in
# <root>\logs\coopdll_prev_*.log, so when the live log is missing (or a reinstall wiped it) the newest kept one is used.
$liveLog = Join-Path $b "coopdll.log"
$prevDir = Join-Path $env:LOCALAPPDATA "G1RCoop\logs"
$candidates = @()
if (Test-Path -LiteralPath $liveLog) { $candidates += Get-Item -LiteralPath $liveLog }
$candidates += @(Get-ChildItem $prevDir -Filter "coopdll_prev_*.log" -ErrorAction SilentlyContinue)
$log = if ($candidates.Count) { ($candidates | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName } else { $liveLog }
$logLines = @()
if (Test-Path $log) {
    $fi = Get-Item $log
    $fs = [IO.File]::Open($log, "Open", "Read", "ReadWrite")
    try {
        $take = [long][Math]::Min($fi.Length, $MaxLogMB * 1MB); $fs.Seek($fi.Length - $take, "Begin") | Out-Null
        $sr = New-Object IO.StreamReader($fs, [Text.Encoding]::UTF8); $text = $sr.ReadToEnd()
    } finally { $fs.Dispose() }
    $logLines = $text -split "`r?`n"
    if ($take -lt $fi.Length -and $logLines.Count -gt 0) { $logLines = $logLines[1..($logLines.Count - 1)] }         # the first line is cut in the middle
    Set-Content (Join-Path $work "coopdll.log") (($logLines | ForEach-Object { Scrub $_ }) -join "`n") -Encoding UTF8
} else { "no log found at $log" | Set-Content (Join-Path $work "coopdll.log.MISSING.txt") }

# ---- launcher and install logs: that is where a failed connection shows up ----
$logDir = Join-Path $env:LOCALAPPDATA 'G1RCoop\logs'
foreach ($pair in @(@((Join-Path $logDir 'launcher.log'), 'launcher.log'), @((Join-Path $logDir 'install.log'), 'install.log'))) {
    $src = $pair[0]; $name = $pair[1]
    if (Test-Path -LiteralPath $src) {
        $rows = @(Get-Content -LiteralPath $src -Tail 2000 -ErrorAction SilentlyContinue)
        Set-Content (Join-Path $work $name) (($rows | ForEach-Object { Scrub $_ }) -join "`n") -Encoding UTF8
    }
}
# ---- role and session context (from the launcher log) ----
$role = "unknown"
$launchStart = ""
$launcherLog = Join-Path $env:LOCALAPPDATA "G1RCoop\logs\launcher.log"
if (Test-Path -LiteralPath $launcherLog) {
    $tail = @(Get-Content -LiteralPath $launcherLog -Tail 400 -ErrorAction SilentlyContinue)
    $r = $tail | Where-Object { $_ -match 'role:\s*(host|guest)' } | Select-Object -Last 1
    if ($r) { $role = [regex]::Match($r, 'role:\s*(host|guest)').Groups[1].Value }
    $s = $tail | Where-Object { $_ -match 'launcher start' } | Select-Object -Last 1
    if ($s) { $launchStart = ($s -split '\]')[0].TrimStart('[') }
}

# ---- system summary ----
$os = Get-CimInstance Win32_OperatingSystem; $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$gpus = Get-CimInstance Win32_VideoController | ForEach-Object { "{0} (driver {1})" -f $_.Name, $_.DriverVersion }
$ram = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
$sum = New-Object System.Collections.ArrayList
[void]$sum.Add("Coop report $stamp")
if ($Note) { [void]$sum.Add("Note from the tester: $Note") }
[void]$sum.Add("OS: $($os.Caption) $($os.Version)")
[void]$sum.Add("CPU: $($cpu.Name.Trim()), $($cpu.NumberOfLogicalProcessors) threads")
[void]$sum.Add("RAM: $ram GB total")
[void]$sum.Add("GPU: " + ($gpus -join "; "))
$exeCandidates = @("C:\Program Files (x86)\Steam\steamapps\common\Gothic 1 Remake\G1R\Binaries\Win64\G1R-Win64-Shipping.exe")
foreach ($p in (Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue)) { try { $exeCandidates += $p.MainModule.FileName } catch {} }
$exe = $exeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($exe) { [void]$sum.Add("Game exe size: $((Get-Item $exe).Length) bytes (build 1.2 = 175124992)") } else { [void]$sum.Add("Game exe: not found at the default path") }
[void]$sum.Add("Game processes running: $(@(Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue).Count)")
[void]$sum.Add("Role in this session: $role")
if ($launchStart) { [void]$sum.Add("Launcher started at: $launchStart") }
$lastSave = @($logLines | Where-Object { $_ -match 'S save|F5|quick save|S load:' }) | Select-Object -Last 3
if ($lastSave.Count) {
    [void]$sum.Add("")
    [void]$sum.Add("Last saves/loads seen in the log:")
    $lastSave | ForEach-Object { [void]$sum.Add("  " + $_) }
}
$events = @($logLines | Where-Object { $_ -match '^\[' + '' }) | Select-Object -Last 10
if ($events.Count) {
    [void]$sum.Add("")
    [void]$sum.Add("Last 10 log lines (context for the problem):")
    $events | ForEach-Object { [void]$sum.Add("  " + $_) }
}
$verFile = Join-Path $root "VERSION.txt"; if (Test-Path $verFile) { [void]$sum.Add("Mod version: " + ((Get-Content $verFile) -join " | ")) }

# ---- mod file versions (hash prefixes) ----
[void]$sum.Add("")
[void]$sum.Add("Mod files:")
$core = Get-ChildItem "$b\coopdll_*.dll" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($core) { [void]$sum.Add(("  {0}  {1}  {2}" -f $core.Name, (Get-FileHash $core.FullName -Algorithm SHA256).Hash.Substring(0, 12), $core.LastWriteTime)) }
Get-ChildItem "$b\modules\*.dll" -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch "_\d+_\d+" } | ForEach-Object { [void]$sum.Add(("  modules\{0}  {1}  {2}" -f $_.Name, (Get-FileHash $_.FullName -Algorithm SHA256).Hash.Substring(0, 12), $_.LastWriteTime)) }

# ---- settings files (scrubbed) ----
[void]$sum.Add("")
[void]$sum.Add("Settings files in native\build:")
foreach ($n in "autoload.txt", "connect.txt", "gate_off.txt", "role.txt", "net_sim.txt", "god.txt", "cam_fix_on.txt", "time_sync_off.txt") {
    $f = Join-Path $b $n; if (Test-Path $f) { [void]$sum.Add("  ${n}: " + (Scrub ((Get-Content $f -ErrorAction SilentlyContinue) -join " / "))) }
}
Get-ChildItem "$b\cfg_*.txt" -ErrorAction SilentlyContinue | ForEach-Object { [void]$sum.Add("  $($_.Name): " + (Scrub ((Get-Content $_.FullName) -join " / "))) }

# ---- counts of the important markers ----
[void]$sum.Add("")
[void]$sum.Add("Log markers (in the included part of the log):")
$pats = [ordered]@{ "EXCEPTION lines" = "EXCEPTION"; "access violations" = "AV at "; "loads started (any)" = "S load:"; "death events" = "S death:"; "hero changed" = "hero changed"; "no packet from the friend" = "no packet from the friend"; "ignored a packet from a stranger" = "ignored a packet from"; "network still waiting" = "still waiting for the first packet" }
foreach ($k in $pats.Keys) { $n = @($logLines | Where-Object { $_ -match [regex]::Escape($pats[$k]) }).Count; [void]$sum.Add(("  {0,-34} {1}" -f $k, $n)) }
$fps = @($logLines | Where-Object { $_ -match "PR fps ([\d.]+)" } | ForEach-Object { [double]([regex]::Match($_, "PR fps ([\d.]+)").Groups[1].Value) })
if ($fps.Count) { [void]$sum.Add(("  fps samples {0}: min {1}, median {2}" -f $fps.Count, ($fps | Measure-Object -Minimum).Minimum, ($fps | Sort-Object)[[int]($fps.Count / 2)])) }
$last = @($logLines | Where-Object { $_ -match "EXCEPTION|AV at " } | Select-Object -Last 5)
if ($last.Count) { [void]$sum.Add(""); [void]$sum.Add("Last faults:"); $last | ForEach-Object { [void]$sum.Add("  " + (Scrub $_)) } }

Set-Content (Join-Path $work "summary.txt") (($sum | ForEach-Object { Scrub ([string]$_) }) -join "`r`n") -Encoding UTF8
$zip = Join-Path $OutDir ("report_" + $role + "_" + $stamp + ".zip")
Compress-Archive -Path "$work\*" -DestinationPath $zip -Force
Remove-Item $work -Recurse -Force
"report written: $zip"
"Open summary.txt inside it and check that nothing private is there before you send it."
