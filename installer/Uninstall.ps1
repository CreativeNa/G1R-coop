<#
    Removes the co-op mod: its folder, the shortcuts and the "Apps and features" entry.
    settings.ini and the logs are kept unless the user says otherwise; the game folder is never touched.
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
$root = Split-Path -Parent $PSCommandPath
$app = Join-Path $root 'app'
$logs = Join-Path $root 'logs'
$settings = Join-Path $root 'settings.ini'

$answer = [System.Windows.Forms.MessageBox]::Show(
    "Удалить кооператив для Gothic 1 Remake?`n`nФайлы игры не затрагиваются. Сохранения игры остаются на месте.",
    'Удаление', 'YesNo', 'Question')
if ($answer -ne 'Yes') { exit 0 }


# The installer renames the startup movies (logos, legal screen, intro) so the game goes straight to the menu.
# Removing the mod puts every name back, because the user asked for the game to be untouched after an uninstall.
function Restore-StartupMovies {
    $gameTxt = Join-Path $root 'game.txt'
    if (-not (Test-Path -LiteralPath $gameTxt)) { return }
    $exe = (Get-Content -LiteralPath $gameTxt -Raw).Trim()
    $gameRoot = $exe
    for ($i = 0; $i -lt 3; $i++) { $gameRoot = Split-Path -Parent $gameRoot }   # ...\Binaries\Win64 -> G1R\Binaries -> G1R -> game root
    if (-not $gameRoot) { return }
    $dir = Join-Path $gameRoot 'G1R\Content\Movies'
    $listFile = Join-Path $dir '_disabled_by_coop.txt'
    if (-not (Test-Path -LiteralPath $listFile)) { return }
    foreach ($n in (Get-Content -LiteralPath $listFile)) {
        $off = Join-Path $dir "$n.off"
        if (Test-Path -LiteralPath $off) { Rename-Item -LiteralPath $off -NewName $n -ErrorAction SilentlyContinue }
    }
    Remove-Item -LiteralPath $listFile -Force -ErrorAction SilentlyContinue
}

try {
    if (Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue) {
        [void][System.Windows.Forms.MessageBox]::Show('Сначала закройте игру.', 'Удаление', 'OK', 'Warning')
        exit 1
    }
    try { Restore-StartupMovies } catch { }
    Remove-Item -LiteralPath $app -Recurse -Force -ErrorAction SilentlyContinue
    # the game's mod descriptor and its entry in Mods.ini (the only things this mod ever put in the game folder)
    $gt = Join-Path $root 'game.txt'
    if (Test-Path -LiteralPath $gt) {
        $gameExe = (Get-Content -LiteralPath $gt -Raw).Trim()
        $gameRoot = Split-Path -Parent $gameExe
        for ($i = 0; $i -lt 3 -and $gameRoot; $i++) { $gameRoot = Split-Path -Parent $gameRoot }
        $modDir = Join-Path $gameRoot 'G1R\Mods\G1RCoop'
        if (Test-Path -LiteralPath $modDir) { Remove-Item -LiteralPath $modDir -Recurse -Force -ErrorAction SilentlyContinue }
    }
    $ini = Join-Path (Join-Path $env:LOCALAPPDATA 'G1R\Saved') 'Mods.ini'
    if (Test-Path -LiteralPath $ini) {
        $t = Get-Content -LiteralPath $ini -Raw
        $t = ($t -split "`r?`n" | Where-Object { $_ -notmatch '^\s*G1RCoop\s*=' }) -join "`r`n"
        Set-Content -LiteralPath $ini -Value $t -Encoding ascii
    }

    $desktop = [Environment]::GetFolderPath('Desktop')
    Remove-Item -LiteralPath (Join-Path $desktop 'Gothic 1 Remake Co-op.lnk') -Force -ErrorAction SilentlyContinue
    $group = Join-Path ([Environment]::GetFolderPath('Programs')) 'Gothic 1 Remake Co-op'
    Remove-Item -LiteralPath $group -Recurse -Force -ErrorAction SilentlyContinue
    try { Remove-MpPreference -ExclusionPath $root -ErrorAction Stop } catch { }
    Remove-Item -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\G1RCoop' -Recurse -Force -ErrorAction SilentlyContinue

    $keep = [System.Windows.Forms.MessageBox]::Show(
        "Удалить также настройки (имя игрока, порт, последний адрес)?`n`n«Нет» — настройки останутся для следующей установки; логи останутся в любом случае.",
        'Настройки', 'YesNo', 'Question')
    if ($keep -eq 'Yes') { Remove-Item -LiteralPath $settings -Force -ErrorAction SilentlyContinue }

    Remove-Item -LiteralPath (Join-Path $root 'CoopLauncher.ps1') -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath (Join-Path $root 'game.txt') -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $PSCommandPath -Force -ErrorAction SilentlyContinue

    [void][System.Windows.Forms.MessageBox]::Show("Готово. Мод удалён.`nЛоги остались в $logs", 'Удаление', 'OK', 'Information')
} catch {
    [void][System.Windows.Forms.MessageBox]::Show("Ошибка при удалении: $($_.Exception.Message)", 'Удаление', 'OK', 'Error')
    exit 1
}
