# Searches the reflection dump of the game (native\build\dump\classes_<pid>.txt, made by `dev.ps1 probe "@0 dumpall"`), no running game needed.
#   .\tools\rf.ps1 Conversation                 # classes whose name matches (with their parent), first 40
#   .\tools\rf.ps1 Camera -Show                 # ... and print each matching class with its own properties and functions
#   .\tools\rf.ps1 -Member LoadGame             # properties/functions whose name matches, with the class that declares them
#   .\tools\rf.ps1 -Super GothicCharacter       # classes that derive (directly) from a class
param([string]$Pattern = "", [string]$Member = "", [string]$Super = "", [switch]$Show, [int]$Max = 40)
$root = Split-Path $PSScriptRoot -Parent
$f = Get-ChildItem (Join-Path $root "native\build\dump\classes_*.txt") -ErrorAction SilentlyContinue | Sort-Object Length -Descending | Select-Object -First 1
if (-not $f) { throw "no dump yet: start a game copy, then  .\tools\dev.ps1 probe '@0 dumpall'  (takes a few minutes, the game stays playable)" }
$cur = ""; $n = 0
foreach ($line in [System.IO.File]::ReadLines($f.FullName)) {
    if ($line.StartsWith("class ") -or $line.StartsWith("struct ")) {
        $cur = $line
        if ($Super -and $line -match " : $([regex]::Escape($Super)) \[") { $line; $n++ }
        elseif ($Pattern -and -not $Member -and -not $Super -and ($line -split ' ')[1] -match $Pattern) {
            $n++; if ($n -le $Max) { $line; if ($Show) { $script:showing = $true } }
        } else { $script:showing = $false }
    }
    elseif ($Member -and $line -match $Member) { "$(($cur -split ' ')[1])  $($line.Trim())"; $n++ }
    elseif ($Show -and $script:showing -and $n -le $Max) { $line }
    if ($n -ge $Max -and -not $Show) { break }
}
"-- $n lines from $($f.Name)"
