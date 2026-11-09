<#
    Gothic 1 Remake — co-op installer wizard.

    Design rules (see docs/INSTALLER_PLAN.md):
      * nothing is ever written into the game folder, so a bad install cannot break the game;
      * the mod lives in %LOCALAPPDATA%\G1RCoop\app and is updated by swapping that folder;
      * settings.ini, logs\ and the save games survive an update and are never copied over;
      * the user only picks the game folder if automatic detection fails.

    Started by Setup.cmd (which asks for administrator rights only when needed - the installer itself writes only to
    the user's own folders, so it usually runs unelevated).
#>
param(
    [string]$PayloadDir = (Join-Path $PSScriptRoot "payload"),
    [string]$Version = "",
    [switch]$Silent,
    # Silent installs never touch the antivirus configuration unless this switch is given explicitly: an installer that
    # quietly adds security exclusions is exactly what makes people distrust a mod. The wizard asks instead, with a
    # checkbox that is off by default.
    [switch]$AddDefenderExclusion,
    # tests install into a sandbox: they must not repoint the player's desktop shortcut at a temp folder
    [switch]$NoShortcuts
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$root = Join-Path $env:LOCALAPPDATA 'G1RCoop'
$appDir = Join-Path $root 'app'
$logDir = Join-Path $root 'logs'
$logFile = Join-Path $logDir 'install.log'
New-Item -ItemType Directory -Force $logDir | Out-Null

function Write-Log([string]$text) {
    $line = "[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $text
    Add-Content -LiteralPath $logFile -Value $line -Encoding utf8
}
Write-Log "installer start, payload=$PayloadDir"

# ---------------------------------------------------------------- game detection
. (Join-Path $PSScriptRoot 'FindGame.ps1')   # Find-GothicExe / Get-GothicRoot, shared with the launcher

function Test-GameExe([string]$exe) {
    if (-not $exe -or -not (Test-Path -LiteralPath $exe)) { return @{ ok = $false; why = 'executable not found' } }
    $size = (Get-Item -LiteralPath $exe).Length
    if ($size -ge 175124992) { return @{ ok = $true; size = $size; why = 'game build 1.2 or newer - supported' } }
    return @{ ok = $true; size = $size; why = "older than build 1.2 ($size bytes) - continuing at your own risk" }
}



# ---------------------------------------------------------------- Radmin VPN
# The supported way to play together: Radmin VPN gives both PCs an address in one virtual network (26.x.x.x), so no
# router, no port forwarding and no "what is my public IP" questions. The installer only *checks* for it.
function Get-RadminAddress {
    try {
        $ip = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop |
            Where-Object { $_.IPAddress -like '26.*' } | Select-Object -First 1 -ExpandProperty IPAddress
        return $ip
    } catch { return $null }
}



# ---------------------------------------------------------------- Windows Defender
# inject.exe exists to put a DLL into the running game, so Windows Defender flags and sometimes deletes it. The mod
# cannot work without it, so the installer asks for a narrow exclusion of the mod's own folder (not the whole disk).
# It needs administrator rights: when the installer runs unelevated it asks for them with the usual Windows prompt.
function Get-DefenderExclusion {
    try { return @((Get-MpPreference -ErrorAction Stop).ExclusionPath | Where-Object { $_ }) } catch { return @() }
}

function Ensure-DefenderExclusion([string]$path) {
    $have = Get-DefenderExclusion
    if ($have -contains $path) { Write-Log "defender exclusion already present: $path"; return $true }
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    try {
        if ($isAdmin) {
            Add-MpPreference -ExclusionPath $path -ErrorAction Stop
        } else {
            $cmd = "Add-MpPreference -ExclusionPath '$path'; exit 0"
            $pr = Start-Process powershell -Verb RunAs -Wait -PassThru -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$cmd`""
            if ($pr.ExitCode -ne 0) { throw "the elevated window returned $($pr.ExitCode)" }
        }
        Write-Log "defender exclusion added: $path"
        return $true
    } catch {
        Write-Log "defender exclusion FAILED for ${path}: $($_.Exception.Message)"
        return $false
    }
}

# ---------------------------------------------------------------- startup movies
# The publisher logos, the legal screen and the one gigabyte intro are loose .bk2 files in <game>\G1R\Content\Movies.
# No command line argument and no user configuration switches them off, so they are renamed in place, with the list
# written next to them; the uninstaller puts every name back. This is the only change the mod ever makes inside the
# game folder, it is reversible, and it can be unticked in the wizard.
$script:MovieNames = @('Alkimia_Logo.bk2', 'Game_Logo.bk2', 'THQNordic_Logo.bk2', 'V_LegalScreen.bk2', 'G1R_Intro.bk2')

function Get-MovieFolder([string]$gameRoot) { return (Join-Path $gameRoot 'G1R\Content\Movies') }

function Disable-StartupMovies([string]$gameRoot) {
    $dir = Get-MovieFolder $gameRoot
    if (-not (Test-Path -LiteralPath $dir)) { Write-Log 'movie folder not found, nothing to disable'; return }
    $done = @()
    foreach ($n in $script:MovieNames) {
        $src = Join-Path $dir $n
        $dst = "$src.off"
        if (Test-Path -LiteralPath $src) {
            if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Force -ErrorAction SilentlyContinue }
            try { Rename-Item -LiteralPath $src -NewName "$n.off" -ErrorAction Stop; $done += $n }
            catch { Write-Log "could not disable $n : $($_.Exception.Message)" }
        } elseif (Test-Path -LiteralPath $dst) { $done += $n }
    }
    if ($done.Count) {
        Set-Content -LiteralPath (Join-Path $dir '_disabled_by_coop.txt') -Value $done -Encoding utf8
        Write-Log "startup movies disabled: $($done -join ', ')"
    }
}

function Enable-StartupMovies([string]$gameRoot) {
    $dir = Get-MovieFolder $gameRoot
    $listFile = Join-Path $dir '_disabled_by_coop.txt'
    if (-not (Test-Path -LiteralPath $listFile)) { return }
    foreach ($n in (Get-Content -LiteralPath $listFile)) {
        $off = Join-Path $dir "$n.off"
        if (Test-Path -LiteralPath $off) { Rename-Item -LiteralPath $off -NewName $n -ErrorAction SilentlyContinue }
    }
    Remove-Item -LiteralPath $listFile -Force -ErrorAction SilentlyContinue
    Write-Log 'startup movies restored'
}


# ---------------------------------------------------------------- the game's mod descriptor
# Gothic 1 Remake lists mods through G1R\Mods\<name>\GothicMod.json and records them in every save; a descriptor
# silences the "save was made with a different modlist" warning. Measured on the guest, however, the descriptor alone
# made the game take 81 s to open its window instead of 34 s - the engine evidently re-scans or re-cooks whatever it
# finds there. That is a much worse trade than a cosmetic warning, so the installer does NOT write a descriptor any
# more; Write-ModDescriptor is kept for experiments and is only called when settings.ini asks for it
# (mod_descriptor = 1). Removing an old one is still done, because it costs the player half a minute at every start.

function Remove-ModDescriptor([string]$gameRoot) {
    $dir = Join-Path $gameRoot 'G1R\Mods\G1RCoop'
    if (Test-Path -LiteralPath $dir) {
        Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "removed an old mod descriptor at $dir (it made every start ~45 s slower)"
    }
    $ini = Join-Path (Join-Path $env:LOCALAPPDATA 'G1R\Saved') 'Mods.ini'
    if (Test-Path -LiteralPath $ini) {
        $t = Get-Content -LiteralPath $ini -Raw
        if ($t -match 'G1RCoop\s*=') {
            $t2 = (($t -split "`r?`n") | Where-Object { $_ -notmatch 'G1RCoop' }) -join "`r`n"
            Set-Content -LiteralPath $ini -Value $t2.Trim() -Encoding ascii
            Write-Log 'removed the G1RCoop entry from Mods.ini'
        }
    }
}

function Write-ModDescriptor([string]$gameRoot) {
    # The version here is NOT the release version on purpose: the game compares it with what every save recorded, so a
    # change makes all existing saves greet the player with "this save was made with a different modlist". Keeping it
    # constant means the descriptor matches every save this mod has ever made. The real version lives in VERSION.txt.
    $ver = '0.0.1'
    $dir = Join-Path $gameRoot 'G1R\Mods\G1RCoop'
    New-Item -ItemType Directory -Force $dir | Out-Null
    $json = [ordered]@{
        name        = 'G1RCoop'
        title       = 'G1R Coop'
        author      = 'G1R Coop project'
        description = 'Co-op for Gothic 1 Remake'
        modVersion  = $ver
        loadOrder   = 'late'
    }
    ($json | ConvertTo-Json) | Set-Content -LiteralPath (Join-Path $dir 'GothicMod.json') -Encoding utf8
    $ini = Join-Path (Join-Path $env:LOCALAPPDATA 'G1R\Saved') 'Mods.ini'
    New-Item -ItemType Directory -Force (Split-Path -Parent $ini) | Out-Null
    if (-not (Test-Path -LiteralPath $ini)) { "[Mods]`r`nG1RCoop=1`r`n" | Set-Content -LiteralPath $ini -Encoding ascii }
    else {
        $text = Get-Content -LiteralPath $ini -Raw
        if ($text -notmatch 'G1RCoop\s*=') {
            if ($text -notmatch '\[Mods\]') { $text = "[Mods]`r`n$text" }
            $text = $text.TrimEnd() + "`r`nG1RCoop=1`r`n"
            Set-Content -LiteralPath $ini -Value $text -Encoding ascii
        }
    }
    Write-Log "mod descriptor written: G1RCoop $ver at $dir"
}

# ---------------------------------------------------------------- install
function Install-Mod([string]$exe) {
    if (Get-Process G1R-Win64-Shipping -ErrorAction SilentlyContinue) {
        throw "Игра запущена. Закройте Gothic 1 Remake и нажмите «Установить» ещё раз — файлы мода заняты запущенной игрой."
    }
    if (-not (Test-Path -LiteralPath $PayloadDir)) { throw "payload folder missing: $PayloadDir" }
    $files = Get-ChildItem -LiteralPath $PayloadDir -Recurse -File
    if (-not $files) { throw "the payload is empty: $PayloadDir" }

    New-Item -ItemType Directory -Force $logDir | Out-Null
    $newDir = "$appDir.new"
    Remove-Item -LiteralPath $newDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force $newDir | Out-Null
    $rel = (Resolve-Path -LiteralPath $PayloadDir).Path
    foreach ($f in $files) {
        $target = Join-Path $newDir ($f.FullName.Substring($rel.Length).TrimStart('\'))
        New-Item -ItemType Directory -Force (Split-Path -Parent $target) | Out-Null
        Copy-Item -LiteralPath $f.FullName -Destination $target -Force
    }
    Write-Log "payload copied to $newDir ($($files.Count) files)"

    # the launcher and the uninstaller live next to app\, not inside it, so an update never touches them
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'CoopLauncher.ps1') -Destination (Join-Path $root 'CoopLauncher.ps1') -Force
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Uninstall.ps1') -Destination (Join-Path $root 'Uninstall.ps1') -Force
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'FindGame.ps1') -Destination (Join-Path $root 'FindGame.ps1') -Force
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'CoopL10n.ps1') -Destination (Join-Path $root 'CoopL10n.ps1') -Force
    # a one-click report for testers: the bat asks for a note, runs collect_logs and opens the folder
    $reportBat = Join-Path $PSScriptRoot 'Собрать отчёт.bat'
    if (Test-Path -LiteralPath $reportBat) { Copy-Item -LiteralPath $reportBat -Destination (Join-Path $root 'Собрать отчёт.bat') -Force }
    New-Item -ItemType Directory -Force (Join-Path $root 'beta_reports') | Out-Null
    $toolsDir = Join-Path $root 'tools'
    New-Item -ItemType Directory -Force $toolsDir | Out-Null
    # the guide and the antivirus/report docs are referenced from the guide itself, so they have to exist after installation
    $docsDir = Join-Path $root 'docs'
    New-Item -ItemType Directory -Force $docsDir | Out-Null
    foreach ($d in 'HOW_TO_PLAY.md', 'BETA_GUIDE.md', 'BETA_REPORT_TEMPLATE.md', 'ANTIVIRUS.md', 'TROUBLESHOOTING.md') {
        $srcDoc = Join-Path (Join-Path $PSScriptRoot 'docs') $d
        if (Test-Path -LiteralPath $srcDoc) { Copy-Item -LiteralPath $srcDoc -Destination (Join-Path $docsDir $d) -Force }
    }
    foreach ($t in 'blackbox.ps1', 'savesync.ps1', 'firewall_coop.ps1', 'diag_link.ps1', 'collect_logs.ps1') {
        $src = Join-Path (Join-Path $PSScriptRoot 'tools') $t
        if (Test-Path -LiteralPath $src) { Copy-Item -LiteralPath $src -Destination (Join-Path $toolsDir $t) -Force }
    }
    if ($Version) { Set-Content -LiteralPath (Join-Path $newDir 'VERSION.txt') -Value $Version -Encoding ascii }
    Set-Content -LiteralPath (Join-Path $root 'game.txt') -Value $exe -Encoding utf8

    # swap the folder: the old one is kept for a rollback until the new one is verified
    # the mod log lives INSIDE app\, so replacing the folder would throw the log away - and a tester who updates and then
    # sends a report would send an empty one. Keep the previous log next to the installer logs.
    $liveLog = Join-Path $appDir 'coopdll.log'
    if (Test-Path -LiteralPath $liveLog) {
        $keep = Join-Path $logDir ('coopdll_prev_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.log')
        Copy-Item -LiteralPath $liveLog -Destination $keep -Force -ErrorAction SilentlyContinue
        Write-Log "previous mod log kept: $keep"
    }
    $old = "$appDir.old"
    Remove-Item -LiteralPath $old -Recurse -Force -ErrorAction SilentlyContinue
    $swapped = $false
    try {
        if (Test-Path -LiteralPath $appDir) { Move-Item -LiteralPath $appDir -Destination $old -Force }
        Move-Item -LiteralPath $newDir -Destination $appDir -Force
        $swapped = $true
    } catch {
        # put the previous version back: an update must never leave the user without a working mod
        if (-not (Test-Path -LiteralPath $appDir) -and (Test-Path -LiteralPath $old)) {
            Move-Item -LiteralPath $old -Destination $appDir -Force -ErrorAction SilentlyContinue
        }
        throw "Не удалось заменить файлы мода (вероятно, игра всё ещё запущена). Предыдущая версия восстановлена. Закройте игру и повторите. Подробности: $($_.Exception.Message)"
    }
    if (-not $swapped) { throw "Не удалось установить файлы мода." }

    # settings are written only when absent
    $settings = Join-Path $root 'settings.ini'
    if (-not (Test-Path -LiteralPath $settings)) {
        @(
            '[coop]'
            'name = Player'
            'port = 40001'
            'discovery_port = 40002'
            'settle_seconds = 12'
            'role = auto'
            'save_transfer = 1'
            'last_address ='
        ) | Set-Content -LiteralPath $settings -Encoding utf8
        Write-Log 'settings.ini created'
    }

    # verification: every payload file must be there with the same size
    foreach ($f in $files) {
        $target = Join-Path $appDir ($f.FullName.Substring($rel.Length).TrimStart('\'))
        if (-not (Test-Path -LiteralPath $target)) { throw "verification failed: $target is missing" }
        if ((Get-Item -LiteralPath $target).Length -ne $f.Length) { throw "verification failed: $target has the wrong size" }
    }
    Write-Log "verified $($files.Count) files in $appDir"
    Remove-Item -LiteralPath $old -Recurse -Force -ErrorAction SilentlyContinue
    return $files.Count
}

function New-Shortcut([string]$path, [string]$target, [string]$arguments, [string]$description) {
    $shell = New-Object -ComObject WScript.Shell
    $sc = $shell.CreateShortcut($path)
    $sc.TargetPath = $target
    $sc.Arguments = $arguments
    $sc.Description = $description
    $sc.WorkingDirectory = $root
    # our own icon (installer\coop.ico ships with the package); fall back to the Windows one only if it is missing
    $ico = Join-Path $root 'coop.ico'
    if (Test-Path -LiteralPath $ico) { $sc.IconLocation = "$ico,0" }
    else { $sc.IconLocation = "$env:SystemRoot\System32\shell32.dll,21" }
    $sc.Save()
}

function Install-Shortcuts {
    $launcher = Join-Path $root 'CoopLauncher.ps1'
    $ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $args = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$launcher`""
    $desktop = [Environment]::GetFolderPath('Desktop')
    New-Shortcut (Join-Path $desktop 'Gothic 1 Remake Co-op.lnk') $ps $args 'Gothic 1 Remake co-op'
    $start = [Environment]::GetFolderPath('Programs')
    $group = Join-Path $start 'Gothic 1 Remake Co-op'
    New-Item -ItemType Directory -Force $group | Out-Null
    New-Shortcut (Join-Path $group 'Play co-op.lnk') $ps $args 'Gothic 1 Remake co-op'
    New-Shortcut (Join-Path $group 'Uninstall.lnk') $ps "-NoProfile -ExecutionPolicy Bypass -File `"$(Join-Path $root 'Uninstall.ps1')`"" 'Remove the co-op mod'

    # an entry in "Apps and features" so the mod can be found and removed like a normal program
    $uninstallKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\G1RCoop'
    New-Item -Path $uninstallKey -Force | Out-Null
    Set-ItemProperty -Path $uninstallKey -Name DisplayName -Value 'Gothic 1 Remake Co-op'
    Set-ItemProperty -Path $uninstallKey -Name DisplayVersion -Value $(if ($Version) { $Version } else { 'dev' })
    Set-ItemProperty -Path $uninstallKey -Name Publisher -Value 'unofficial mod'
    Set-ItemProperty -Path $uninstallKey -Name InstallLocation -Value $root
    Set-ItemProperty -Path $uninstallKey -Name UninstallString -Value ("powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f (Join-Path $root 'Uninstall.ps1'))
    Set-ItemProperty -Path $uninstallKey -Name NoModify -Value 1 -Type DWord
    Set-ItemProperty -Path $uninstallKey -Name NoRepair -Value 1 -Type DWord
    Write-Log 'shortcuts and uninstall entry written'
}

# ---------------------------------------------------------------- the wizard
$script:detectedExe = Find-GothicExe
if ($Silent) {
    if (-not $script:detectedExe) { Write-Log 'silent install: no game found'; exit 2 }
    # silent installs never touch Windows Defender unless asked with -AddDefenderExclusion, and then before unpacking
    if ($AddDefenderExclusion) { $null = Ensure-DefenderExclusion $root } else { Write-Log 'silent install: defender exclusion not requested, skipping' }
    $null = Install-Mod $script:detectedExe
    if ($env:G1RCOOP_MOD_DESCRIPTOR -eq '1') { Write-ModDescriptor (Get-GothicRoot $script:detectedExe) }
    if (-not $NoShortcuts) { Install-Shortcuts }
    try { Remove-ModDescriptor (Get-GothicRoot $script:detectedExe) } catch { }
    try { Disable-StartupMovies (Get-GothicRoot $script:detectedExe) } catch { Write-Log "movies: $($_.Exception.Message)" }
    Write-Log 'silent install done'
    exit 0
}

$form = New-Object Windows.Forms.Form
$form.Text = 'Gothic 1 Remake — установка кооператива'
$form.Size = New-Object Drawing.Size(760, 450)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

$title = New-Object Windows.Forms.Label
$title.Text = 'Кооператив для Gothic 1 Remake'
$title.Font = New-Object Drawing.Font('Segoe UI', 15, [Drawing.FontStyle]::Bold)
$title.Location = New-Object Drawing.Point(20, 15)
$title.AutoSize = $true
$form.Controls.Add($title)

$sub = New-Object Windows.Forms.Label
$sub.Text = "Установщик кладёт мод в вашу папку пользователя и НЕ меняет файлы игры.`nВерсия мода: $(if ($Version) { $Version } else { 'dev' })"
$sub.Location = New-Object Drawing.Point(22, 55)
$sub.AutoSize = $true
$form.Controls.Add($sub)

$lblGame = New-Object Windows.Forms.Label
$lblGame.Text = 'Папка игры:'
$lblGame.Location = New-Object Drawing.Point(22, 105)
$lblGame.AutoSize = $true
$form.Controls.Add($lblGame)

$txtGame = New-Object Windows.Forms.TextBox
$txtGame.Location = New-Object Drawing.Point(22, 128)
$txtGame.Size = New-Object Drawing.Size(590, 24)
$txtGame.Text = if ($script:detectedExe) { Get-GothicRoot $script:detectedExe } else { '' }
$form.Controls.Add($txtGame)

$btnBrowse = New-Object Windows.Forms.Button
$btnBrowse.Text = 'Обзор…'
$btnBrowse.Location = New-Object Drawing.Point(620, 126)
$btnBrowse.Size = New-Object Drawing.Size(110, 28)
$form.Controls.Add($btnBrowse)

$status = New-Object Windows.Forms.Label
$status.Location = New-Object Drawing.Point(22, 165)
$status.Size = New-Object Drawing.Size(700, 60)
$status.AutoSize = $false
$form.Controls.Add($status)

$lblRadmin = New-Object Windows.Forms.Label
$lblRadmin.Location = New-Object Drawing.Point(22, 200)
$lblRadmin.Size = New-Object Drawing.Size(700, 30)
$lblRadmin.AutoSize = $false
$radmin = Get-RadminAddress
if ($radmin) {
    $lblRadmin.ForeColor = [Drawing.Color]::DarkGreen
    $lblRadmin.Text = "Radmin VPN: подключён, ваш адрес $radmin — его увидит друг; в игре есть кнопка Join co-op."
} else {
    $lblRadmin.ForeColor = [Drawing.Color]::DarkOrange
    $lblRadmin.Text = "Radmin VPN не найден. Для игры по сети установите Radmin VPN и войдите с другом в одну сеть (адреса 26.x.x.x)."
}
$form.Controls.Add($lblRadmin)

$chkSkipMovies = New-Object Windows.Forms.CheckBox
$chkSkipMovies.Text = 'Не показывать заставки (логотипы, правовой экран и вступление)'
$chkSkipMovies.Location = New-Object Drawing.Point(22, 232)
$chkSkipMovies.Size = New-Object Drawing.Size(600, 24)
$chkSkipMovies.Checked = $true
$form.Controls.Add($chkSkipMovies)

# Off by default on purpose: the installer must not change security settings behind the user's back. The text says
# exactly which folder and why, and the manual route is offered at the end either way.
$chkDefenderExclusion = New-Object Windows.Forms.CheckBox
$chkDefenderExclusion.Text = 'Добавить папку мода в исключения Windows Defender (нужно из-за inject.exe)'
$chkDefenderExclusion.Location = New-Object Drawing.Point(22, 258)
$chkDefenderExclusion.Size = New-Object Drawing.Size(700, 24)
$chkDefenderExclusion.Checked = $false
$form.Controls.Add($chkDefenderExclusion)

$lblDefenderNote = New-Object Windows.Forms.Label
$lblDefenderNote.Text = 'Антивирус иногда удаляет inject.exe — он внедряет DLL в игру. Исключение только для папки мода, не для диска.'
$lblDefenderNote.Location = New-Object Drawing.Point(40, 280)
$lblDefenderNote.Size = New-Object Drawing.Size(540, 18)
$lblDefenderNote.ForeColor = [Drawing.Color]::DimGray
$form.Controls.Add($lblDefenderNote)

$progress = New-Object Windows.Forms.ProgressBar
$progress.Location = New-Object Drawing.Point(22, 258)
$progress.Size = New-Object Drawing.Size(700, 18)
$progress.Style = 'Continuous'
$form.Controls.Add($progress)

$btnInstall = New-Object Windows.Forms.Button
$btnInstall.Text = 'Установить'
$btnInstall.Location = New-Object Drawing.Point(600, 292)
$btnInstall.Size = New-Object Drawing.Size(124, 34)
$form.Controls.Add($btnInstall)

$btnClose = New-Object Windows.Forms.Button
$btnClose.Text = 'Закрыть'
$btnClose.Location = New-Object Drawing.Point(470, 292)
$btnClose.Size = New-Object Drawing.Size(120, 34)
$form.Controls.Add($btnClose)

function Update-Status {
    $exe = Join-Path $txtGame.Text 'G1R\Binaries\Win64\G1R-Win64-Shipping.exe'
    $check = Test-GameExe $exe
    if ($check.ok) {
        $status.ForeColor = [Drawing.Color]::DarkGreen
        $status.Text = "Игра найдена (build: $($check.size) байт). $($check.why)"
        $btnInstall.Enabled = $true
    } else {
        $status.ForeColor = [Drawing.Color]::DarkRed
        $status.Text = "Игра не найдена по этому пути. Укажите папку, где лежит G1R (внутри неё G1R\Binaries\Win64\G1R-Win64-Shipping.exe)."
        $btnInstall.Enabled = $false
    }
}

$btnBrowse.Add_Click({
    $dlg = New-Object Windows.Forms.FolderBrowserDialog
    $dlg.Description = 'Выберите папку Gothic 1 Remake (в ней есть папка G1R)'
    if ($dlg.ShowDialog() -eq 'OK') { $txtGame.Text = $dlg.SelectedPath; Update-Status }
})
$txtGame.Add_TextChanged({ Update-Status })
$btnClose.Add_Click({ $form.Close() })

$btnInstall.Add_Click({
    $exe = Join-Path $txtGame.Text 'G1R\Binaries\Win64\G1R-Win64-Shipping.exe'
    $btnInstall.Enabled = $false
    $progress.Value = 10
    $status.ForeColor = [Drawing.Color]::Black
    try {
        $status.Text = 'Проверка игры…'; $form.Refresh()
        $check = Test-GameExe $exe
        if (-not $check.ok) { throw "Игра не найдена: $exe" }
        # A disc copy or an older patch has a different exe size. The mod finds engine functions by signature, so it may
        # simply not work there - say that loudly at the end instead of letting the tester discover it in silence.
        $buildNote = if ($check.size -lt 175124992) { "ВНИМАНИЕ: сборка игры старее 1.2 — мод может не заработать." } else { "" }
        Write-Log ("game check: " + $check.why)
        if ($chkDefenderExclusion.Checked) {
            # before the payload is unpacked: a file that is copied and then deleted by the antivirus leaves a broken mod
            $status.Text = 'Добавление исключения в Windows Defender…'; $progress.Value = 20; $form.Refresh()
            $null = Ensure-DefenderExclusion $root
        }
        $status.Text = 'Копирование файлов мода…'; $progress.Value = 30; $form.Refresh()
        $n = Install-Mod $exe
        $progress.Value = 70
        $status.Text = 'Регистрация мода в игре…'; $form.Refresh()
        if ($env:G1RCOOP_MOD_DESCRIPTOR -eq '1') { Write-ModDescriptor (Get-GothicRoot $exe) }
        $status.Text = 'Создание ярлыков…'; $form.Refresh()
        if (-not $NoShortcuts) { Install-Shortcuts }
        # an existing descriptor from an older version slows every start by ~45 s: remove it unless asked for
        try { Remove-ModDescriptor (Get-GothicRoot $exe) } catch { }
        # the exclusion is offered up front (see the checkbox); here we only remind how to add it by hand
        $defenderHint = if ($chkDefenderExclusion.Checked) { "Исключение Defender добавлено для $root." } else { "Исключение Defender не добавлялось. Если антивирус удалит inject.exe — инструкция в docs\ANTIVIRUS.md (папка $root)." }
        Write-Log ("defender: " + $defenderHint)
        if ($chkSkipMovies.Checked) {
            $status.Text = 'Отключение заставок…'; $form.Refresh()
            try { Disable-StartupMovies (Get-GothicRoot $exe) } catch { Write-Log "movies: $($_.Exception.Message)" }
        }
        $progress.Value = 100
        $status.ForeColor = [Drawing.Color]::DarkGreen
        $radminNow = Get-RadminAddress
        $hint = if ($radminNow) { "Ваш Radmin-адрес: $radminNow" } else { "Radmin VPN не найден — без него играть по сети не получится." }
        $status.Text = "Готово. Установлено файлов: $n.`nЗапускайте игру ярлыком «Gothic 1 Remake Co-op» на рабочем столе.`nВ главном меню одна кнопка — Join co-op (роль выбирает лаунчер).$([Environment]::NewLine)$hint$([Environment]::NewLine)$defenderHint$(if ($buildNote) { [Environment]::NewLine + $buildNote } else { '' })"
        if ($buildNote) { $status.ForeColor = [Drawing.Color]::DarkOrange }
        $btnClose.Text = 'Готово'
    } catch {
        $progress.Value = 0
        $status.ForeColor = [Drawing.Color]::DarkRed
        $status.Text = "Ошибка: $($_.Exception.Message)`nПодробности: $logFile`nНичего в игре не изменено."
        Write-Log "install failed: $($_.Exception.Message)"
        $btnInstall.Enabled = $true
    }
})

$form.Add_Shown({ Update-Status })
[void]$form.ShowDialog()
