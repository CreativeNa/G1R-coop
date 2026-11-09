# For copies started by Couchlink (or by hand): waits for game processes and gives each one the co-op core.
#   .\tools\inject_new_copies.ps1            # start it, then press Play in Couchlink; it ends when it has served two copies (or after 15 minutes)
# The first process that appears becomes the host (listens on 40001), the second the guest (cfg file: local 40002 -> the host 127.0.0.1:40001).
# The core is injected -SettleSeconds after a process starts (it then waits for the engine by itself). Does not change any game setting.
param([int]$SettleSeconds = 12, [int]$Copies = 2, [int]$MaxMinutes = 15)
$root = Split-Path $PSScriptRoot -Parent
$b = Join-Path $root "native\build"
$dll = (Get-ChildItem "$b\coopdll_*.dll" | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
$inject = Join-Path $b "inject.exe"
if (-not (Test-Path $inject)) { throw "inject.exe is missing (Windows Defender may have quarantined it: restore it in Windows Security > Protection history)" }
try { Start-Transcript -Path (Join-Path $b "inject_watch.log") -Force | Out-Null } catch { }
Remove-Item "$b\cfg_*.txt", "$b\autoload_done_*.txt" -ErrorAction SilentlyContinue
Set-Content "$b\connect.txt" "host 40001" -Encoding ascii
if (-not (Test-Path "$b\autoload.txt")) { Set-Content "$b\autoload.txt" "wait=3.5" -Encoding ascii }
$served = @{}
$deadline = (Get-Date).AddMinutes($MaxMinutes)
"waiting for $Copies game copies (core: $dll)"
while ($served.Count -lt $Copies -and (Get-Date) -lt $deadline) {
    foreach ($p in Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue | Sort-Object StartTime) {
        if ($served.ContainsKey($p.Id)) { continue }
        $seat = $served.Count
        $served[$p.Id] = $seat
        if ($seat -ne 0) { Set-Content "$b\cfg_$($p.Id).txt" "40002 127.0.0.1 40001 S1" -Encoding ascii }
        "seat $seat = pid $($p.Id): injecting in $SettleSeconds s"
        $age = ((Get-Date) - $p.StartTime).TotalSeconds
        if ($age -lt $SettleSeconds) { Start-Sleep -Seconds ([int]($SettleSeconds - $age)) }
        if (Get-Process -Id $p.Id -ErrorAction SilentlyContinue) { & $inject $p.Id $dll | Select-Object -First 1 } else { "pid $($p.Id) ended before injection" }
    }
    Start-Sleep -Seconds 2
}
"done: $($served.Count) copies served"
