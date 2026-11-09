# Switches the game's display language and takes a screenshot of the coop window, to check that the mod's own strings and
# the "Join" button survive a different language. The language lives in GameUserSettings.ini and is only read at start-up,
# so a screenshot of the running game shows the OLD language until the game is restarted.
#
#   .\tools\test_languages.ps1                       # show the current language and what would be done
#   .\tools\test_languages.ps1 -Set German           # write the language (applies after a restart)
#   .\tools\test_languages.ps1 -Set German -Shot     # ... and screenshot the running window
#   .\tools\test_languages.ps1 -Restore              # put back what was there before the first -Set
#
# Supported values are what the game itself writes: Russian, English, German, Polish, French, Italian, Spanish, Czech,
# Hungarian, Chinese (the ten the game ships).
#
# Exit code: 0 = done, 2 = config not found.
param(
    [string]$Set = '',
    [switch]$Restore,
    [switch]$Shot,
    [ValidateSet('ru', 'en', 'de')][string]$Ui = 'ru',
    [string]$Config = (Join-Path $env:LOCALAPPDATA 'G1R\Saved\Config\Windows\GameUserSettings.ini')
)
$ErrorActionPreference = 'Continue'
$here = $PSScriptRoot
$backup = "$Config.lang_backup"

if (-not (Test-Path -LiteralPath $Config)) { "config not found: $Config (start the game once so it writes one)"; exit 2 }

function Read-Lang {
    $m = Select-String -LiteralPath $Config -Pattern '^m_DisplayLanguage=(\S+)' | Select-Object -First 1
    if ($m) { return $m.Matches[0].Groups[1].Value }
    return '(not set)'
}

$current = Read-Lang
"current display language: $current"

if ($Restore) {
    if (-not (Test-Path -LiteralPath $backup)) { "no backup at $backup - nothing to restore"; exit 0 }
    $orig = (Get-Content -LiteralPath $backup -Raw).Trim()
    $text = Get-Content -LiteralPath $Config -Raw
    $text = $text -replace '(?m)^m_DisplayLanguage=\S+', "m_DisplayLanguage=$orig"
    [IO.File]::WriteAllText($Config, $text)
    "restored: $orig (takes effect after a game restart)"
    exit 0
}

if (-not $Set) {
    "nothing to do; use -Set <language> (e.g. German), -Shot, or -Restore"
    exit 0
}

if (-not (Test-Path -LiteralPath $backup)) { Set-Content -LiteralPath $backup -Value $current -NoNewline }
$text = Get-Content -LiteralPath $Config -Raw
if ($text -match '(?m)^m_DisplayLanguage=\S+') {
    $text = $text -replace '(?m)^m_DisplayLanguage=\S+', "m_DisplayLanguage=$Set"
} else {
    $text = $text.TrimEnd() + "`r`nm_DisplayLanguage=$Set`r`n"
}
[IO.File]::WriteAllText($Config, $text)
"language set to: $Set (original saved in $backup; the game has to be restarted)"

if ($Shot) {
    # the game may be running on the OLD language; the screenshot is still useful as "mod survived the switch"
    $proc = Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $proc) { "no game running - nothing to screenshot; start it and run this again" }
    else {
        $out = Join-Path $here ('..\docs\img\lang_' + ($Set -replace '\W', '') + '_' + (Get-Date -Format 'yyyyMMdd_HHmm') + '.png')
        $out = [IO.Path]::GetFullPath($out)
        & (Join-Path $here 'winshot.ps1') -Seat 0 -Out $out | Out-Null
        "screenshot: $out"
        "when the language is the same on screen, the mod's Join button and its own messages are readable"
    }
}
exit 0
