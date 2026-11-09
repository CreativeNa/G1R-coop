# Reads a report_*.zip from the mod's beta_reports folder and prints a short verdict.
#   .\tools\triage_report.ps1 -Report "$env:LOCALAPPDATA\G1RCoop\beta_reports\report_guest_....zip"
param([Parameter(Mandatory = $true)][string]$Report)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$tmp = Join-Path $env:TEMP ('triage_' + [guid]::NewGuid().ToString('N').Substring(0,8))
[IO.Compression.ZipFile]::ExtractToDirectory((Resolve-Path $Report).Path, $tmp)
try {
    $json = if (Test-Path (Join-Path $tmp 'report.json')) { Get-Content (Join-Path $tmp 'report.json') -Raw | ConvertFrom-Json } else { $null }
    $launcher = if (Test-Path (Join-Path $tmp 'launcher.log')) { Get-Content (Join-Path $tmp 'launcher.log') } else { @() }
    $mod = if (Test-Path (Join-Path $tmp 'coopdll.log')) { Get-Content (Join-Path $tmp 'coopdll.log') } else { @() }
    "версия:     " + $(if ($json) { $json.version } else { 'нет report.json' })
    "роль:       " + $(if ($json) { $json.role } else { '?' })
    "сборка игры:" + $(if ($json -and $json.gameBuild) { ' ' + $json.gameBuild } else { ' ?' })
    "ошибок:     " + $(if ($json) { $json.errors } else { '-' })
    "контакт:    " + $(if ($json) { $json.contactLines } else { '-' })
    ""
    "--- вывод ---"
    if (-not $json) { "  report.json отсутствует: отчёт старой версии"; }
    else {
        if ($json.gameBuild -and $json.gameBuild -ne 175124992) { "  сборка игры не 1.2 ($($json.gameBuild)) — мод может не работать"; }
        if ($json.role -eq 'guest' -and $json.contactLines -eq 0) { "  гость не соединился: проверьте порядок запуска, Radmin и кнопку «Присоединиться»"; }
        if ($json.role -eq 'host' -and $json.contactLines -eq 0) { "  хост не видел гостя: гость не дошёл до подключения или блокирует брандмауэр"; }
        if ($json.errors -gt 0) { "  в журнале $($json.errors) ошибок — смотрите coopdll.log"; }
        if ($launcher -match 'savesync fetch returned') { "  передача сохранений не удалась — миры могут различаться"; }
        if ($launcher -match 'LoadLibrary returned 0x0') { "  мод не внедрился (LoadLibrary 0x0)"; }
        if ($launcher -match 'no host answered') { "  лаунчер не нашёл хоста в сети"; }
        if ($json.contactLines -gt 0 -and $json.errors -eq 0) { "  соединение было, грубых ошибок нет — смотрите жалобу тестера"; }
    }
}
finally { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
