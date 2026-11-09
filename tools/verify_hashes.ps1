# Prints SHA-256 of every file a tester would run, and compares it with manifest.json inside the package.
#   .\tools\verify_hashes.ps1 -Package dist\Gothic1Coop-Setup-0.5.3
param([Parameter(Mandatory = $true)][string]$Package)
$ErrorActionPreference = 'Stop'
$pkg = (Resolve-Path -LiteralPath $Package).Path
$payload = Join-Path $pkg 'payload'
if (-not (Test-Path $payload)) { throw "no payload folder in $pkg" }
$manifest = Join-Path $payload 'manifest.json'
$expected = @{}
if (Test-Path $manifest) { foreach ($e in (Get-Content $manifest -Raw | ConvertFrom-Json)) { $expected[$e.path] = $e.sha256 } }
$bad = 0
Get-ChildItem $payload -Recurse -File | Where-Object { $_.Name -ne 'manifest.json' } | Sort-Object FullName | ForEach-Object {
    $rel = $_.FullName.Substring($payload.Length).TrimStart('\')
    $h = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
    $ok = if ($expected.ContainsKey($rel)) { $expected[$rel] -eq $h } else { $true }
    if (-not $ok) { $bad++ }
    "{0}  {1}  {2}" -f $h, $(if ($ok) { 'OK  ' } else { 'FAIL' }), $rel
}
""
"zip: " + (Get-FileHash $pkg'.zip' -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
if ($bad) { "MISMATCH: $bad file(s)"; exit 1 } else { "all files match manifest.json" }
