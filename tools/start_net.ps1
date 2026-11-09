# Starts ONE game copy for a two-PC session and injects the core.
#   host PC:   .\tools\start_net.ps1 -Role host
#   guest PC:  .\tools\start_net.ps1 -Role guest -Peer <host IP or name>
# Both PCs need: the same game build, the same mod files (this repository folder or the release zip), and the SAME save game
# (copy %LOCALAPPDATA%\G1R\Saved\SaveGames from one PC to the other first; the newest slot is what "Continue" loads).
# Network: UDP, default port 40001. The host listens, the guest sends to <host IP>:<port>; the host locks onto the first friend that knocks.
# Radmin VPN / ZeroTier / Hamachi addresses work without a router change; over the internet forward UDP 40001 to the host PC.
# Windows Firewall may ask to allow the game: allow it for private networks (this script changes no firewall or security setting).
# Without -KeepGate the join gate is switched off (tests): the guest can join before the host has talked to Diego.
param(
    [Parameter(Mandatory = $true)][ValidateSet("host", "guest")][string]$Role,
    [string]$Peer = "",
    [int]$Port = 40001,
    [string]$GameDir = "C:\Program Files (x86)\Steam\steamapps\common\Gothic 1 Remake",
    [string]$CoreDll = "",
    [int]$SettleSeconds = 12,
    [switch]$KeepGate,
    [switch]$Lite,
    [switch]$SendSaves,                  # host: also serve this PC's save games to the guest (TCP -SavePort), see savesync.ps1
    [switch]$GetSaves,                   # guest: first fetch the host's saves (your own are backed up first), then start the game
    [int]$SavePort = 40003,
    [string]$SaveToken = ""
)
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$b = Join-Path $root "native\build"
$exe = Join-Path $GameDir "G1R\Binaries\Win64\G1R-Win64-Shipping.exe"
if (-not (Test-Path $exe)) { throw "game not found: $exe (pass -GameDir)" }
if ($Role -eq "guest" -and -not $Peer) { throw "the guest needs -Peer <host IP or name>" }
$size = (Get-Item $exe).Length
"game exe size $size bytes (build 1.2 = 175124992; another size starts the core in recon mode and may need a profile line)"
$dll = if ($CoreDll) { Join-Path $b $CoreDll } else { (Get-ChildItem "$b\coopdll_*.dll" | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName }
if (-not $dll -or -not (Test-Path $dll)) { throw "no coopdll_*.dll in $b" }
$inject = Join-Path $b "inject.exe"
if (-not (Test-Path $inject)) { throw "inject.exe is missing in $b (Windows Defender may have quarantined it: restore it in Windows Security > Protection history)" }
if (-not (Test-Path (Join-Path $b "modules\story.dll"))) { throw "modules\story.dll is missing in $b" }
if (Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue) { throw "a game copy is already running (close it first)" }
$saves = Join-Path $env:LOCALAPPDATA "G1R\Saved\SaveGames"
if (Test-Path $saves) { $newest = Get-ChildItem $saves -Filter *.sav | Sort-Object LastWriteTime -Descending | Select-Object -First 1; if ($newest) { "newest save here: $($newest.Name)  $($newest.LastWriteTime)  $($newest.Length) bytes  (both PCs must show the same name and size)" } }
else { "no SaveGames folder yet at $saves" }

$ss = Join-Path $PSScriptRoot "savesync.ps1"
if ($Role -eq "host" -and $SendSaves) {
    $q = '"'; $tok = if ($SaveToken) { " -Token $q$SaveToken$q" } else { "" }
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $q$ss$q serve -Port $SavePort$tok -Minutes 240" -WindowStyle Hidden | Out-Null
    "serving this PC's saves to the guest on TCP $SavePort for 4 hours (make your save BEFORE the guest starts)"
}
if ($Role -eq "guest" -and $GetSaves) {
    "fetching the host's saves (your own saves are copied to a backup folder first) ..."
    & $ss fetch -Peer $Peer -Port $SavePort -Token $SaveToken
}
Remove-Item "$b\autoload_done_*.txt", "$b\cfg_*.txt" -ErrorAction SilentlyContinue
if ($Role -eq "host") { Set-Content "$b\connect.txt" "host $Port" -Encoding ascii } else { Remove-Item "$b\connect.txt" -ErrorAction SilentlyContinue }
if (-not (Test-Path "$b\autoload.txt")) { Set-Content "$b\autoload.txt" "wait=3.5" -Encoding ascii }
if ($KeepGate) { Remove-Item "$b\gate_off.txt" -ErrorAction SilentlyContinue } else { Set-Content "$b\gate_off.txt" "tests" -Encoding ascii }
$seat = if ($Role -eq "host") { 0 } else { 1 }
$extra = if ($Lite) { ' -ExecCmds="r.Streaming.PoolSize 200,r.MipMapLODBias 3,r.Streaming.MaxTempMemoryAllowed 32,r.ScreenPercentage 30"' } else { "" }
$p = Start-Process $exe -ArgumentList ("-no-intro-cinematic -nosplash -CoopSeat=$seat$extra") -WorkingDirectory (Split-Path $exe) -PassThru
if ($Role -eq "guest") { Set-Content "$b\cfg_$($p.Id).txt" "$($Port + 1) $Peer $Port S1" -Encoding ascii }       # local port, host, host port, id (S1 = the guest)
Start-Sleep $SettleSeconds
if (-not (Get-Process -Id $p.Id -ErrorAction SilentlyContinue)) { throw "the game exited before injection" }
& $inject $p.Id $dll | Select-Object -First 1
"role $Role, game pid $($p.Id), core $(Split-Path $dll -Leaf), port UDP $Port"
"this PC's addresses: " + ((Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notmatch "^(127\.|169\.254\.)" } | ForEach-Object { $_.IPAddress }) -join ", ")
if ($Role -eq "host") { "give the guest one of these addresses (the Radmin / VPN one if you use a VPN). Log: $b\coopdll.log" }
else { "connecting to ${Peer}:$Port. Log: $b\coopdll.log (look for 'remote' / 'N3 remote' lines when both are in the game)" }
