# Starts the two co-op copies of the REAL game install (build 1.1 profile) and injects the core into each as early as it is safe.
#   .\tools\start_coop_11.ps1            # host (seat 0, main monitor) + guest (seat 1, second monitor if there is one, else the right half of the main one)
#   .\tools\start_coop_11.ps1 -Seats 0   # only the host
# The core waits by itself for the engine objects (it retries for ~3 minutes), so the DLL may be injected early; -SettleSeconds is the pause after the process starts.
# autoload.txt (build\) makes every copy press "Continue" in the main menu; gate_off.txt (build\) turns the join gate off for tests.
param([int[]]$Seats = @(0, 1), [int]$SettleSeconds = 12, [switch]$Full, [switch]$NoInject, [string]$CoreDll = "")
$root = Split-Path $PSScriptRoot -Parent
$b = Join-Path $root "native\build"
try { Start-Transcript -Path (Join-Path $b "start_coop.log") -Force | Out-Null } catch { }          # a hidden start leaves its messages (and errors) here
$exe ="C:\Program Files (x86)\Steam\steamapps\common\Gothic 1 Remake\G1R\Binaries\Win64\G1R-Win64-Shipping.exe"
if (-not (Test-Path $exe)) { throw "game not found: $exe" }
$dll = if ($CoreDll) { Join-Path $b $CoreDll } else { (Get-ChildItem "$b\coopdll_*.dll" | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName }          # -CoreDll coopdll_67.dll pins a core build
$inject = Join-Path $b "inject.exe"
if (-not (Test-Path $inject)) { throw "inject.exe is missing (Windows Defender may have quarantined it: restore it in Windows Security > Protection history)" }
if (Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue) { throw "a game copy is already running (close it first)" }
Add-Type -AssemblyName System.Windows.Forms
$screens = [Windows.Forms.Screen]::AllScreens
$main = $screens | Where-Object { $_.Primary } | Select-Object -First 1
$second = $screens | Where-Object { -not $_.Primary } | Select-Object -First 1
Remove-Item "$b\coopdll.log", "$b\autoload_done_*.txt", "$b\cfg_*.txt" -ErrorAction SilentlyContinue
Set-Content "$b\connect.txt" "host 40001" -Encoding ascii                                  # the host copy (no cfg file): listens on 40001 and locks onto the first friend that knocks
if (-not (Test-Path "$b\autoload.txt")) { Set-Content "$b\autoload.txt" "wait=3.5" -Encoding ascii }
Set-Content "$b\gate_off.txt" "tests" -Encoding ascii
$lite = if ($Full) { "" } else { ' -ExecCmds="r.Streaming.PoolSize 200,r.MipMapLODBias 3,r.Streaming.MaxTempMemoryAllowed 32,r.ScreenPercentage 30,r.Streaming.MipBias 2.7"' }
foreach ($seat in $Seats) {
    # Two copies of a UE5 game on one GPU: a full screen window leaves the other copy at a few frames.
    # Split the primary screen in half instead (measured: full size 3-15 fps, half 41 fps).
    $half = [int]($main.Bounds.Width / 2)
    if ($second) {
        if ($seat -eq 0) { $x = $main.Bounds.X; $y = $main.Bounds.Y; $w = $main.Bounds.Width; $h = $main.Bounds.Height }
        else { $x = $second.Bounds.X; $y = $second.Bounds.Y; $w = $second.Bounds.Width; $h = $second.Bounds.Height }
    } else {
        $w = $half; $h = $main.Bounds.Height; $y = $main.Bounds.Y
        if ($seat -eq 0) { $x = $main.Bounds.X } else { $x = $main.Bounds.X + $half }
    }
    $p = Start-Process $exe -ArgumentList ("-windowed -ResX=$w -ResY=$h -WinX=$x -WinY=$y -no-intro-cinematic -nosplash -CoopSeat=$seat$lite") -WorkingDirectory (Split-Path $exe) -PassThru
    if ($seat -ne 0) { Set-Content "$b\cfg_$($p.Id).txt" "40002 127.0.0.1 40001 S1" -Encoding ascii }   # the guest: local port 40002, the host is 127.0.0.1:40001
    Start-Sleep $SettleSeconds
    if ($NoInject) { "seat ${seat}: not injected (-NoInject)" } elseif (Get-Process -Id $p.Id -ErrorAction SilentlyContinue) { & $inject $p.Id $dll | Select-Object -First 1 } else { "seat ${seat}: the game exited before injection" }
    "seat $seat started (pid $($p.Id))"
    if ($seat -eq 0 -and $Seats.Count -gt 1) { Start-Sleep 20 }                              # the second copy starts a little later so that the two loads do not run in the same minute
}
