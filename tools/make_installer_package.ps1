# Builds the user-facing installer package: dist\Gothic1Coop-Setup-<version>.zip
#   .\tools\make_installer_package.ps1 -Version 0.4.0
#
# The zip holds Setup.cmd, Setup.ps1, CoopLauncher.ps1, Uninstall.ps1 and a payload folder with only what the mod
# needs at run time: the newest core, the seven clean modules and inject.exe. Nothing else - no logs,
# no per-process module copies, no developer switches, no source, no tools the user does not need.
param(
    [Parameter(Mandatory = $true)][string]$Version,
    [string]$CoreDll = ""
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$b = Join-Path $root 'native\build'
$dist = Join-Path $root 'dist'
$stage = Join-Path $dist ("Gothic1Coop-Setup-" + $Version)
Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $stage, "$stage\payload\modules" | Out-Null

# installer scripts
foreach ($f in 'Setup.cmd', 'Setup.ps1', 'CoopLauncher.ps1', 'Uninstall.ps1', 'FindGame.ps1') {
    $src = Join-Path $root "installer\$f"
    if (-not (Test-Path -LiteralPath $src)) { throw "installer file missing: $src" }
    Copy-Item -LiteralPath $src -Destination $stage -Force
}

# the black box that runs with the game (inside the installer folder, copied by the wizard)
New-Item -ItemType Directory -Force "$stage\tools" | Out-Null
Copy-Item -LiteralPath (Join-Path $root 'tools\blackbox.ps1') -Destination "$stage\tools\blackbox.ps1" -Force
Copy-Item -LiteralPath (Join-Path $root 'tools\savesync.ps1') -Destination "$stage\tools\savesync.ps1" -Force
Copy-Item -LiteralPath (Join-Path $root 'tools\firewall_coop.ps1') -Destination "$stage\tools\firewall_coop.ps1" -Force
Copy-Item -LiteralPath (Join-Path $root 'tools\diag_link.ps1') -Destination "$stage\tools\diag_link.ps1" -Force
Copy-Item -LiteralPath (Join-Path $root 'tools\collect_logs.ps1') -Destination "$stage\tools\collect_logs.ps1" -Force
Copy-Item -LiteralPath (Join-Path $root 'installer\CoopL10n.ps1') -Destination "$stage\CoopL10n.ps1" -Force
Copy-Item -LiteralPath (Join-Path $root 'installer\Собрать отчёт.bat') -Destination "$stage\Собрать отчёт.bat" -Force

# payload: the core
$core = if ($CoreDll) { Get-Item (Join-Path $b $CoreDll) } else { Get-ChildItem "$b\coopdll_*.dll" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 }
if (-not $core) { throw "no coopdll_*.dll in $b" }
Copy-Item $core.FullName "$stage\payload\" -Force

# payload: inject.exe
$inj = Join-Path $b 'inject.exe'
if (-not (Test-Path -LiteralPath $inj)) { throw "inject.exe missing in $b (Windows Defender may have quarantined it)" }
Copy-Item $inj "$stage\payload\" -Force

# payload: the clean modules (no per-process copies, no rebuild leftovers)
$mods = Get-ChildItem "$b\modules\*.dll" | Where-Object { $_.Name -notmatch '_\d+_\d+' }
if (-not $mods) { throw "no modules in $b\modules" }
$mods | Copy-Item -Destination "$stage\payload\modules\" -Force

# No autoload switch: the game must stay in the main menu, because that is where the Co-op buttons are. The
# launcher has already written the connection, so the session is ready as soon as the player presses Continue.

# readme the user sees first
$readme = @(
    "Gothic 1 Remake - co-op $Version",
    "",
    "1. Unpack this folder anywhere (for example to the Desktop).",
    "2. Run Setup.cmd and follow the wizard: it finds the game by itself.",
    "3. Start the game with the shortcut it creates on the desktop.",
    "4. In the main menu:",
    "     - the host starts the game from the Co-op shortcut (the launcher picks the role by itself),",
    "     - the guest starts the game the same way and presses 'Join' in the main menu once: the mod finds",
    "       the host, connects and loads the save without any other click.",
    "",
    "Both PCs must be in one network: Radmin VPN (recommended, addresses 26.x.x.x) or the same LAN.",
    "Windows Firewall: allow Gothic 1 Remake on private networks when Windows asks.",
    "",
    "Nothing in the game folder is changed. The mod lives in %LOCALAPPDATA%\G1RCoop and is removed completely by",
    "the Uninstall shortcut in the Start menu.",
    "",
    "Logs (send these if something goes wrong): %LOCALAPPDATA%\G1RCoop\logs"
)
Set-Content -LiteralPath (Join-Path $stage 'READ ME FIRST.txt') -Value $readme -Encoding utf8
# our own shortcut icon: the installer puts it next to Setup.cmd and points the desktop shortcut at it
$icoSrc = Join-Path (Split-Path $PSScriptRoot -Parent) 'installer\coop.ico'
if (Test-Path -LiteralPath $icoSrc) { Copy-Item -LiteralPath $icoSrc -Destination (Join-Path $stage 'coop.ico') -Force }
else { Write-Warning 'installer\coop.ico is missing - the shortcut will fall back to the Windows icon' }
# docs the tester needs: the guide, the report template, the antivirus instructions and troubleshooting
New-Item -ItemType Directory -Force "$stage\docs" | Out-Null
foreach ($d in 'HOW_TO_PLAY.md', 'BETA_GUIDE.md', 'BETA_REPORT_TEMPLATE.md', 'ANTIVIRUS.md', 'TROUBLESHOOTING.md') {
    $src = Join-Path $root "docs\$d"
    if (Test-Path -LiteralPath $src) { Copy-Item -LiteralPath $src -Destination "$stage\docs\$d" -Force }
}

# a manifest so the installer can verify the payload and refuse mismatched versions
$manifest = foreach ($f in Get-ChildItem -LiteralPath "$stage\payload" -Recurse -File) {
    $rel = $f.FullName.Substring((Resolve-Path "$stage\payload").Path.Length).TrimStart('\')
    [pscustomobject]@{ path = $rel; size = $f.Length; sha256 = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash }
}
$manifest | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath "$stage\payload\manifest.json" -Encoding utf8

$zip = Join-Path $dist ("Gothic1Coop-Setup-" + $Version + ".zip")
Remove-Item $zip -Force -ErrorAction SilentlyContinue
Compress-Archive -Path "$stage\*" -DestinationPath $zip -Force
$size = [math]::Round((Get-Item $zip).Length / 1MB, 2)
"package: $zip ($size MB), core $($core.Name), $($mods.Count) modules, $($manifest.Count) files in the manifest"
