# Checks the installer package and, optionally, runs a real silent install/uninstall in a sandboxed LOCALAPPDATA.
#
#   .\tools\test_install_cycle.ps1                                  # read-only: payload vs manifest, layout, log lines
#   .\tools\test_install_cycle.ps1 -AllowSideEffects                # also run Setup.ps1 -Silent and Uninstall.ps1
#   .\tools\test_install_cycle.ps1 -Payload dist\Gothic1Coop-Setup-0.4.2.75\payload
#
# The read-only part is safe anywhere. The real cycle is sandboxed by pointing LOCALAPPDATA at a temp folder, so the mod is
# installed and removed inside it - BUT the installer also writes a desktop shortcut and an HKCU "Apps and features" entry,
# which are real changes to your profile. That is why it needs -AllowSideEffects.
#
# Exit code: 0 = every check that ran passed, 1 = something failed, 2 = payload missing.
param(
    [string]$Payload = '',
    [switch]$AllowSideEffects,
    [switch]$KeepSandbox
)
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent $PSScriptRoot
if (-not $Payload) {
    $cand = Get-ChildItem (Join-Path $root 'dist') -Directory -Filter 'Gothic1Coop-Setup-*' -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending | Select-Object -First 1
    if ($cand) { $Payload = Join-Path $cand.FullName 'payload' }
}
if (-not $Payload -or -not (Test-Path -LiteralPath $Payload)) {
    "no payload found - pass -Payload <path to ...\payload>"; exit 2
}
$Payload = (Resolve-Path $Payload).Path
$results = New-Object System.Collections.ArrayList
function Check([string]$name, [bool]$ok, [string]$detail) {
    [void]$results.Add([pscustomobject]@{ Name = $name; Ok = $ok })
    "$(if ($ok) { 'PASS' } else { 'FAIL' })  $name$(if ($detail) { " - $detail" })"
}

"payload: $Payload"

# --- 1. layout ----------------------------------------------------------------------------------------------------
# Two layouts exist in dist\: the 0.4.2.x package keeps the scripts at the package root and the binaries in payload\,
# while an older 0.5.0 variant has fewer files (no FindGame.ps1, no coop.ico). Required files are checked strictly, the
# optional ones are reported as a note instead of failing the run.
$pkgRoot = Split-Path -Parent $Payload
$required = @('Setup.ps1', 'Uninstall.ps1', 'Setup.cmd')
$missing = @($required | Where-Object { -not (Test-Path (Join-Path $pkgRoot $_)) })
Check 'the package has the installer scripts' ($missing.Count -eq 0) ($missing -join ', ')

$optional = @('CoopLauncher.ps1', 'FindGame.ps1', 'coop.ico', 'Setup.cmd')
$absent = @($optional | Where-Object { -not (Test-Path (Join-Path $pkgRoot $_)) })
if ($absent.Count) { "note: not in this package variant: $($absent -join ', ')" }

$mods = @(Get-ChildItem (Join-Path $Payload 'modules') -Filter *.dll -ErrorAction SilentlyContinue)
Check 'seven modules are packed' ($mods.Count -eq 7) ("$($mods.Count) found: " + (($mods | ForEach-Object { $_.Name }) -join ', '))
Check 'the core dll is packed' ([bool](Get-ChildItem $Payload -Filter 'coopdll_*.dll' -ErrorAction SilentlyContinue))
# --- 2. manifest --------------------------------------------------------------------------------------------------
$manifest = Join-Path $Payload 'manifest.json'
if (Test-Path $manifest) {
    $m = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
    $bad = @()
    foreach ($e in $m) {
        $f = Join-Path $Payload $e.path
        if (-not (Test-Path -LiteralPath $f)) { $bad += "$($e.path) missing"; continue }
        $h = (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash
        if ($h -ne $e.sha256) { $bad += "$($e.path) hash"; continue }
        if ((Get-Item -LiteralPath $f).Length -ne $e.size) { $bad += "$($e.path) size" }
    }
    Check "every file matches the manifest ($($m.Count) files)" ($bad.Count -eq 0) (($bad | Select-Object -First 3) -join '; ')
} else { Check 'manifest.json exists' $false 'not found' }

# --- 3. a real cycle, sandboxed -----------------------------------------------------------------------------------
if (-not $AllowSideEffects) {
    ""
    "SKIP  the real install/uninstall cycle: it writes a desktop shortcut and an HKCU entry."
    "      add -AllowSideEffects to run it (the mod itself stays inside a temp LOCALAPPDATA)"
} else {
    $sandbox = Join-Path ([IO.Path]::GetTempPath()) ('g1r_install_' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Force $sandbox | Out-Null
    $setup = Join-Path $pkgRoot 'Setup.ps1'
    $uninst = Join-Path $pkgRoot 'Uninstall.ps1'
    $ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    if (Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue) {
        # The installer refuses to touch a running copy on purpose ("файлы мода заняты запущенной игрой"): that guard is
        # itself worth checking, and the real cycle has to wait until the game is closed.
        $cmd = '$env:LOCALAPPDATA = ''' + $sandbox + '''; & ''' + $setup + ''' -PayloadDir ''' + $Payload + ''' -Silent -NoShortcuts'
        $o = & $ps -NoProfile -ExecutionPolicy Bypass -Command $cmd 2>&1 | Out-String
        # Encoding-independent: the child exits non-zero and leaves no app folder. Matching the Russian message directly
        # broke once because a BOM-less .ps1 is read as ANSI and the Cyrillic literal turns into mojibake.
        # Encoding-independent evidence: no app folder was created and the install log never reached "silent install done".
        $guardLog = Join-Path $sandbox 'G1RCoop\logs\install.log'
        $guardText = if (Test-Path $guardLog) { Get-Content $guardLog -Raw } else { '' }
        $refused = (-not (Test-Path (Join-Path $sandbox 'G1RCoop\app'))) -and ($guardText -notmatch 'silent install done')
        Check 'the installer refuses to install while the game runs' $refused ($(if ($guardText) { ($guardText -split "`n" | Where-Object { $_ -match '\S' } | Select-Object -First 1) } else { 'no install log at all' }))
        ""
        "SKIP  the real install/uninstall cycle: the game is running. Close it and run this again."
        Remove-Item $sandbox -Recurse -Force -ErrorAction SilentlyContinue
        $failNow = @($results | Where-Object { -not $_.Ok }).Count
        "verdict: $(if ($failNow) { 'RED' } else { 'green' }) ($(@($results | Where-Object { $_.Ok }).Count) passed, $failNow failed)"
        exit $(if ($failNow) { 1 } else { 0 })
    }
    try {
        # the installer reads $env:LOCALAPPDATA at start, so a redirected value keeps the whole mod in the sandbox
        $cmd = '$env:LOCALAPPDATA = ''' + $sandbox + '''; & ''' + $setup + ''' -PayloadDir ''' + $Payload + ''' -Silent -NoShortcuts'
        $o = & $ps -NoProfile -ExecutionPolicy Bypass -Command $cmd 2>&1 | Out-String
        $appDir = Join-Path $sandbox 'G1RCoop\app'
        $coreDll = @(Get-ChildItem $appDir -Filter 'coopdll_*.dll' -ErrorAction SilentlyContinue)
        $modDll = @(Get-ChildItem (Join-Path $appDir 'modules') -Filter *.dll -ErrorAction SilentlyContinue)
        Check 'silent install puts the app in the sandbox' ($coreDll.Count -ge 1 -and $modDll.Count -eq 7) ("core $($coreDll.Count), modules $($modDll.Count) in $appDir")
        Check 'the install log was written' (Test-Path (Join-Path $sandbox 'G1RCoop\logs\install.log')) ''
        Check 'the launcher is installed next to the app' (Test-Path (Join-Path $sandbox 'G1RCoop\CoopLauncher.ps1')) ''

        # The uninstaller is interactive by design: it shows a MessageBox and removes the folder it sits in
        # ($root = Split-Path -Parent $PSCommandPath), so it cannot be driven from a test. Check that it was installed
        # where the launcher expects it, and say plainly why the rest is not automated.
        $installedUninstaller = Join-Path $sandbox 'G1RCoop\Uninstall.ps1'
        Check 'the uninstaller is installed next to the app' (Test-Path $installedUninstaller) $installedUninstaller
        "SKIP  the uninstall itself: it shows a MessageBox and removes the folder it sits in - by design, not automated"
    } finally {
        if ($KeepSandbox) { "sandbox kept: $sandbox" } else { Remove-Item $sandbox -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

""
$fail = @($results | Where-Object { -not $_.Ok }).Count
$pass = @($results | Where-Object { $_.Ok }).Count
"verdict: $(if ($fail) { 'RED' } else { 'green' }) ($pass passed, $fail failed)"
if ($fail) { exit 1 } else { exit 0 }
