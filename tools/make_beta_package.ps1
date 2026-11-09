# Builds the beta tester package: dist\coop-beta-<version>.zip
#   .\tools\make_beta_package.ps1 -Version 0.4.0-beta1
# Contains: the newest core, the clean modules, inject.exe, the start / save / report scripts, the guides, NOTICE.txt (the "unofficial modification" notice the
# THQ Nordic modding policy asks for), VERSION.txt. Does NOT contain: game files, saves, logs, developer switches (god.txt, give_*.txt, net_sim.txt ...),
# the per-process module copies, local test aids, anything from outside the repository folders listed below.
param([Parameter(Mandatory = $true)][string]$Version, [string]$CoreDll = "")
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$b = Join-Path $root "native\build"
$dist = Join-Path $root "dist"
$pack = Join-Path $dist ("coop-beta-" + $Version)
Remove-Item $pack -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force "$pack\tools", "$pack\native\build\modules", "$pack\docs" | Out-Null

$core = if ($CoreDll) { Get-Item (Join-Path $b $CoreDll) } else { Get-ChildItem "$b\coopdll_*.dll" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 }
if (-not $core) { throw "no coopdll_*.dll in $b" }
Copy-Item $core.FullName "$pack\native\build\"
$inj = Join-Path $b "inject.exe"; if (-not (Test-Path $inj)) { throw "inject.exe missing in $b" }
Copy-Item $inj "$pack\native\build\"
$mods = Get-ChildItem "$b\modules\*.dll" | Where-Object { $_.Name -notmatch "_\d+_\d+" }
if (-not $mods) { throw "no modules in $b\modules" }
$mods | Copy-Item -Destination "$pack\native\build\modules\"
Set-Content "$pack\native\build\autoload.txt" "wait=3.5" -Encoding ascii            # the only default switch: press "Continue" in the main menu

# The probe module (it also holds the autoload) is rebuilt WITHOUT the developer's local god mode: a co-op package must not carry an immortality cheat.
$tmpb = Join-Path $env:TEMP "coopbeta_probe"; Remove-Item $tmpb -Recurse -Force -ErrorAction SilentlyContinue; New-Item -ItemType Directory $tmpb | Out-Null
$vc = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
if (-not (Test-Path $vc)) { throw "Visual Studio Build Tools not found: needed to build the clean probe module" }
$bat = Join-Path $tmpb "b.bat"
Set-Content $bat @("@echo off", "call `"$vc`" >nul", "cd /d `"$tmpb`"", "cl /nologo /O2 /W3 /D_CRT_SECURE_NO_WARNINGS /DNO_LOCAL_GOD /LD `"$root\native\probe_module.c`" /Fe:probe.dll /Fo:probe_module.obj") -Encoding ascii
& cmd /c "`"$bat`"" | Out-Null
if (-not (Test-Path "$tmpb\probe.dll")) { throw "the clean probe module did not build" }
$bytes = [IO.File]::ReadAllBytes("$tmpb\probe.dll"); $txt = [Text.Encoding]::ASCII.GetString($bytes)
if ($txt.Contains("god.txt")) { throw "the clean probe module still contains the god mode" }
Copy-Item "$tmpb\probe.dll" "$pack\native\build\modules\probe.dll" -Force
Remove-Item $tmpb -Recurse -Force

foreach ($t in "start_net.ps1", "savesync.ps1", "collect_logs.ps1", "window_monitors.ps1", "window_split.ps1", "window_size.ps1", "net_check.ps1", "firewall_coop.ps1", "health.ps1", "tail.ps1", "start_coop_11.ps1", "cmp.ps1") { $tp = Join-Path $root "tools\$t"; if (Test-Path $tp) { Copy-Item $tp "$pack\tools\" } }
foreach ($d in "BETA_GUIDE.md", "BETA_REPORT_TEMPLATE.md", "FRIEND_SETUP.md", "TWO_PC_TEST.md", "TROUBLESHOOTING.md", "BUGS.md", "CHANGELOG.md", "SESSION_2026-11-06.md") { $p = Join-Path $root "docs\$d"; if (Test-Path $p) { Copy-Item $p "$pack\docs\" } }

$hash = ""; try { $hash = (git -C $root rev-parse --short HEAD 2>$null) } catch { }
$ver = @("version $Version", "core $($core.Name)", "git $hash", "built $(Get-Date -Format 'yyyy-MM-dd HH:mm')", "game build: exe 175124992 bytes (1.2); other sizes start the core in recon mode")
Set-Content "$pack\VERSION.txt" $ver -Encoding ascii
$notice = @(
    "This is an unofficial modification. It is not made, endorsed or supported by THQ Nordic.",
    "",
    "Gothic 1 Remake is a trademark of its owners. This package contains no game files and works only with a legitimately owned copy of the game.",
    "It is free. Do not sell it or put any part of it behind a paywall. Do not redistribute game files or assets.",
    "Questions and problems go to the mod's author, not to THQ Nordic support. Use at your own risk: back up your save games."
)
Set-Content "$pack\NOTICE.txt" $notice -Encoding utf8

# a last guard: no developer file may be in the package
$bad = Get-ChildItem $pack -Recurse -File | Where-Object { $_.Name -match "^(god|net_sim|cam_fix_on|time_sync_off|gate_off|role|connect)\.txt$|^give_|^cfg_|\.log$|\.sav$|\.pdb$|_\d+_\d+\.dll$" }
if ($bad) { $bad | ForEach-Object { "forbidden file in the package: $($_.FullName)" }; throw "the package contains developer files" }
$zip = Join-Path $dist ("coop-beta-" + $Version + ".zip")
Remove-Item $zip -Force -ErrorAction SilentlyContinue
Compress-Archive -Path "$pack\*" -DestinationPath $zip
"package: $zip  ($([int]((Get-Item $zip).Length / 1KB)) KB), core $($core.Name), $(@($mods).Count) modules"
