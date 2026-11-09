<#
    Finds the Gothic 1 Remake executable on this PC, for every store and for a disc install.

    Sources, in order:
      1. Steam  - the client path from the registry, then every library folder from libraryfolders.vdf;
      2. GOG    - the GOG.com registry keys (HKLM/HKCU ...\GOG.com\Games\<id> -> path), the usual GOG folders;
      3. any    - the "Apps and features" (uninstall) entries whose DisplayName mentions Gothic 1 Remake, which is how
                  GOG Galaxy and most retail installers register themselves;
      4. the usual folders on every drive (Steam default, GOG default, plain "Games", Program Files).
    The user can always point the wizard at the folder by hand, so this only has to be good, not perfect.
#>
function Get-GothicExeRelativePath { 'G1R\Binaries\Win64\G1R-Win64-Shipping.exe' }

function Test-GothicFolder([string]$dir) {
    if (-not $dir) { return $null }
    $dir = $dir.TrimEnd('\')
    $rel = Get-GothicExeRelativePath
    # Retail/disc installers lay the files out differently, and a tester may pick a folder one level too deep or one level
    # too high. Accept every shape that still ends with the real executable; the mod only needs that exe.
    foreach ($candidate in @(
        "$dir\$rel",
        "$dir\Gothic 1 Remake\$rel",
        "$dir\G1R-Win64-Shipping.exe",
        "$dir\Binaries\Win64\G1R-Win64-Shipping.exe",
        "$dir\Win64\G1R-Win64-Shipping.exe",
        "$dir\G1R\Binaries\Win64\G1R-Win64-Shipping.exe"
    )) {
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    return $null
}

function Find-GothicExe {
    $candidates = New-Object System.Collections.Generic.List[string]

    # ---- 1. Steam
    $steam = $null
    foreach ($key in 'HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'HKLM:\SOFTWARE\Valve\Steam') {
        try {
            $p = (Get-ItemProperty -Path $key -ErrorAction Stop).SteamPath
            if ($p) { $steam = $p; break }
        } catch { }
    }
    if ($steam) {
        $candidates.Add("$steam\steamapps\common\Gothic 1 Remake")
        $vdf = "$steam\steamapps\libraryfolders.vdf"
        if (Test-Path -LiteralPath $vdf) {
            foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) {
                $lib = ($m.Groups[1].Value -replace '\\\\', '\') -replace '/', '\'   # no Join-Path: it throws on a drive that is not there
                $candidates.Add("$lib\steamapps\common\Gothic 1 Remake")
            }
        }
    }

    # ---- 2. GOG (the store's own registry and GALAXY's folders)
    foreach ($key in 'HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games', 'HKLM:\SOFTWARE\GOG.com\Games', 'HKCU:\Software\GOG.com\Games') {
        try {
            foreach ($game in Get-ChildItem -Path $key -ErrorAction Stop) {
                $path = (Get-ItemProperty -Path $game.PSPath -ErrorAction SilentlyContinue).path
                if ($path) { $candidates.Add($path) }
            }
        } catch { }
    }
    $candidates.Add('C:\GOG Games\Gothic 1 Remake')
    $candidates.Add('C:\Program Files (x86)\GOG Galaxy\Games\Gothic 1 Remake')
    $candidates.Add("$env:ProgramData\GOG.com\Games\Gothic 1 Remake")

    # ---- 3. anything that registered itself in "Apps and features"
    # Retail installers and localised setups do not always call the game "Gothic 1 Remake" - a disc release may register
    # "Gothic" or "Готика", and sometimes the install folder is one level above the game. Match any of those names and let
    # Test-GothicFolder decide whether the folder really contains the game executable.
    foreach ($root in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                      'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
                      'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*') {
        try {
            foreach ($entry in Get-ItemProperty -Path $root -ErrorAction Stop) {
                if (-not $entry.InstallLocation) { continue }
                if ($entry.DisplayName -and $entry.DisplayName -match 'Gothic|Готика|G1R') {
                    $candidates.Add($entry.InstallLocation)
                    $candidates.Add((Join-Path $entry.InstallLocation 'Gothic 1 Remake'))
                }
            }
        } catch { }
    }

    # ---- 4. the usual places, every drive
    foreach ($d in 'C', 'D', 'E', 'F', 'G') {
        if (-not (Test-Path -LiteralPath "${d}:\")) { continue }
        $candidates.Add("${d}:\Program Files (x86)\Steam\steamapps\common\Gothic 1 Remake")
        $candidates.Add("${d}:\SteamLibrary\steamapps\common\Gothic 1 Remake")
        $candidates.Add("${d}:\GOG Games\Gothic 1 Remake")
        $candidates.Add("${d}:\Games\Gothic 1 Remake")
        $candidates.Add("${d}:\Program Files (x86)\Gothic 1 Remake")
        $candidates.Add("${d}:\Program Files\Gothic 1 Remake")
        $candidates.Add("${d}:\Gothic 1 Remake")
    }

    foreach ($c in $candidates | Select-Object -Unique) {
        $exe = Test-GothicFolder $c
        if ($exe) { return $exe }
    }
    return $null
}

# the folder the wizard shows in its text box (the game root, not the exe)
function Get-GothicRoot([string]$exe) {
    if (-not $exe) { return '' }
    $dir = Split-Path -Parent $exe              # ...\Win64
    for ($i = 0; $i -lt 3; $i++) { $dir = Split-Path -Parent $dir }   # ...\G1R\Binaries\Win64 -> game root
    return $dir
}
